// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {BasketAdapter} from "./BasketAdapter.sol";

/// @title BlurVault
/// @notice Tokenized vault that puts idle stablecoin to work in an external
///         lending vault and hands depositors a proportional share of the result.
/// @dev Stage 1 of the protocol: the lending leg only. The tokenized-stock leg
///      and the bounded keeper role are added on top of this, not woven into it —
///      `totalAssets()` is the single seam they extend.
///
///      Custody note: there is deliberately no function that moves depositor
///      assets to an arbitrary address. The owner can only choose how much sits
///      idle versus earning; it cannot direct funds anywhere else.
contract BlurVault is ERC4626, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint16 internal constant BPS = 10_000;

    /// @notice External ERC-4626 producing the lending yield.
    IERC4626 public immutable yieldVault;

    /// @notice Portion of assets kept liquid so small exits need no unwind, in bps.
    uint16 public bufferBps;

    /// @notice Performance fee, charged only on gains above the high-water mark.
    uint16 public performanceFeeBps;

    /// @notice Highest share price ever reached, in assets per whole share.
    uint256 public highWaterMark;

    /// @notice Where fee shares are minted.
    address public feeRecipient;

    /// @notice Contract allowed to run automation. Zero disables it.
    address public guard;

    /// @notice Equity side of the vault. Zero means this is a lending-only vault.
    BasketAdapter public basket;

    /// @notice Share of the vault targeted at the lending leg, in bps.
    /// @dev 10_000 is STEADY. 6_000 is BALANCED. 3_000 is GROWTH.
    uint16 public targetStableBps;

    /// @dev Cached so USD valuations can be scaled without another external call.
    uint8 private immutable _assetDecimals;

    event Deployed(uint256 assets);
    event Recalled(uint256 assets);
    event BufferUpdated(uint16 bufferBps);
    event FeeAccrued(uint256 feeAssets, uint256 feeShares, uint256 newHighWaterMark);
    event FeeRecipientUpdated(address recipient);
    event GuardUpdated(address guard);
    event BasketUpdated(address basket, uint16 targetStableBps);
    event RedeemedInKind(
        address indexed caller, address indexed receiver, address indexed owner, uint256 shares, uint256 stableOut
    );

    error AssetMismatch();
    error BasketNotEmpty();
    error SplitOutOfRange();
    error BufferTooHigh();
    error FeeTooHigh();
    error ZeroFeeRecipient();
    error NotAutomation();

    constructor(
        IERC20 asset_,
        IERC4626 yieldVault_,
        string memory name_,
        string memory symbol_,
        address owner_
    ) ERC20(name_, symbol_) ERC4626(asset_) Ownable(owner_) {
        if (yieldVault_.asset() != address(asset_)) revert AssetMismatch();
        yieldVault = yieldVault_;
        bufferBps = 500;
        performanceFeeBps = 500;
        feeRecipient = owner_;
        targetStableBps = BPS; // lending-only until a basket is attached
        _assetDecimals = IERC20Metadata(address(asset_)).decimals();
        highWaterMark = _sharePrice();
    }

    /// @dev Virtual shares. Without this, the first depositor can donate assets
    ///      directly to the vault and round the next depositor's shares to zero.
    ///      An offset of 6 makes that attack cost more than it can ever extract.
    function _decimalsOffset() internal pure override returns (uint8) {
        return 6;
    }

    /// @inheritdoc ERC4626
    /// @dev Reverts when the basket cannot be priced — a stale feed or an
    ///      unacknowledged split. That deliberately blocks deposits and
    ///      priced withdrawals rather than quoting a share price nobody
    ///      can stand behind. `redeemInKind` stays open in that state.
    function totalAssets() public view override returns (uint256) {
        return _stableAssets() + basketAssets();
    }

    /// @notice Value of the lending leg plus anything sitting idle.
    function stableAssets() public view returns (uint256) {
        return _stableAssets();
    }

    /// @notice Value of the equity leg, in asset units.
    function basketAssets() public view returns (uint256) {
        if (address(basket) == address(0)) return 0;
        return _usdToAssets(basket.totalValueUsd());
    }

    /// @notice How the vault is actually split right now, in bps.
    function currentStableBps() external view returns (uint16) {
        uint256 total = totalAssets();
        if (total == 0) return targetStableBps;
        return uint16((_stableAssets() * BPS) / total);
    }

    /// @notice True when a priced deposit or withdrawal can go through.
    function isPriceable() public view returns (bool) {
        return address(basket) == address(0) || basket.isValuable();
    }

    // ---------------------------------------------------------------------
    // On withdrawal limits
    //
    // `maxWithdraw` and `maxRedeem` are deliberately left as inherited. An
    // earlier version capped them by "available liquidity", but that number is
    // not knowable here: the venue's own `maxWithdraw` reports zero while
    // executing full redemptions, so the only figure we can compute is the
    // value of our position — which is exactly what `totalAssets()` already is.
    // The cap was therefore identical to the base behaviour and never bound,
    // while its comment claimed a protection that did not exist.
    //
    // A real shortfall at the venue surfaces as a revert inside `_withdraw`.
    // That is the honest failure mode: we cannot know a payout is impossible
    // until we attempt it.
    // ---------------------------------------------------------------------

    // ---------------------------------------------------------------------
    // Performance fee
    //
    // Taken as newly minted shares, never by moving assets out. The fee dilutes
    // holders by its own value; it does not give anyone a withdrawal path. That
    // is what lets the custody claim stay true with a fee in place.
    //
    // The high-water mark tracks the gross share price, so a gain is charged
    // once and a recovery after a drawdown is free. See docs/fees.
    // ---------------------------------------------------------------------

    /// @notice Assets backing one whole share.
    function sharePrice() public view returns (uint256) {
        return _sharePrice();
    }

    /// @notice Mint the fee owed on any gain above the high-water mark.
    /// @dev Permissionless and idempotent. Runs before every change to the share
    ///      count so nobody can enter or exit at a price that has not been
    ///      assessed, which would shift the fee onto the holders who stayed.
    function accrueFee() public returns (uint256 feeShares) {
        uint256 price = _sharePrice();
        if (price <= highWaterMark) return 0;

        uint256 supply = totalSupply();
        uint16 feeBps = performanceFeeBps;
        if (supply == 0 || feeBps == 0) {
            highWaterMark = price;
            return 0;
        }

        uint256 gain = ((price - highWaterMark) * supply) / 10 ** decimals();
        uint256 feeAssets = (gain * feeBps) / BPS;
        uint256 assets = totalAssets();

        if (feeAssets > 0 && assets > feeAssets) {
            // Shares worth exactly feeAssets once minted, allowing for the
            // virtual shares and assets the base contract adds.
            feeShares = Math.mulDiv(
                feeAssets, supply + 10 ** _decimalsOffset(), assets + 1 - feeAssets, Math.Rounding.Floor
            );
            if (feeShares > 0) _mint(feeRecipient, feeShares);
        }

        highWaterMark = price;
        emit FeeAccrued(feeAssets, feeShares, price);
    }

    function setPerformanceFeeBps(uint16 newFeeBps) external onlyOwner {
        if (newFeeBps > 2_000) revert FeeTooHigh();
        accrueFee(); // settle everything owed at the old rate first
        performanceFeeBps = newFeeBps;
    }

    function setFeeRecipient(address newRecipient) external onlyOwner {
        if (newRecipient == address(0)) revert ZeroFeeRecipient();
        feeRecipient = newRecipient;
        emit FeeRecipientUpdated(newRecipient);
    }

    // ---------------------------------------------------------------------
    // Entrypoints
    //
    // Every path that changes the share count assesses the fee first.
    // ---------------------------------------------------------------------

    function deposit(uint256 assets, address receiver) public override returns (uint256) {
        accrueFee();
        return super.deposit(assets, receiver);
    }

    function mint(uint256 shares, address receiver) public override returns (uint256) {
        accrueFee();
        return super.mint(shares, receiver);
    }

    function withdraw(uint256 assets, address receiver, address owner) public override returns (uint256) {
        accrueFee();
        return super.withdraw(assets, receiver, owner);
    }

    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256) {
        accrueFee();
        return super.redeem(shares, receiver, owner);
    }

    // ---------------------------------------------------------------------
    // In-kind redemption
    // ---------------------------------------------------------------------

    /// @notice Burn shares and take a pro-rata slice of everything the vault
    ///         holds — stablecoin and equities alike — without selling anything.
    ///
    /// @dev Consults no price at any point. The slice is `shares / totalSupply`,
    ///      which is arithmetic on the share ledger alone, so this path keeps
    ///      working when feeds are stale, the equity market is shut, or a split
    ///      is pending. Those are exactly the moments an exit matters, and they
    ///      are exactly the moments `totalAssets()` refuses to answer.
    ///
    ///      The fee is skipped when the vault cannot be priced. Charging it
    ///      would require a share price, and trapping a holder's funds to
    ///      protect a fee is the wrong way round.
    function redeemInKind(uint256 shares, address receiver, address owner)
        external
        nonReentrant
        returns (uint256 stableOut, address[] memory tokens, uint256[] memory amounts)
    {
        if (isPriceable()) accrueFee();

        if (msg.sender != owner) _spendAllowance(owner, msg.sender, shares);

        uint256 supply = totalSupply();
        uint256 idleShare = (_idle() * shares) / supply;
        uint256 venueShare = (yieldVault.convertToAssets(yieldVault.balanceOf(address(this))) * shares) / supply;

        // Burn before moving anything out.
        _burn(owner, shares);

        if (venueShare > 0) {
            yieldVault.withdraw(venueShare, address(this), address(this));
            emit Recalled(venueShare);
        }

        stableOut = idleShare + venueShare;
        if (stableOut > 0) IERC20(asset()).safeTransfer(receiver, stableOut);

        if (address(basket) != address(0)) {
            (tokens, amounts) = basket.sendSliceToVault(shares, supply);
            for (uint256 i; i < tokens.length; ++i) {
                if (amounts[i] > 0) IERC20(tokens[i]).safeTransfer(receiver, amounts[i]);
            }
        }

        emit RedeemedInKind(msg.sender, receiver, owner, shares, stableOut);
    }

    // ---------------------------------------------------------------------
    // Allocation
    // ---------------------------------------------------------------------

    /// @notice Move idle assets above the buffer into the lending vault.
    function deployIdle() external returns (uint256) {
        return _deployIdle(type(uint256).max);
    }

    /// @notice Same, but never moving more than `maxAssets` in one call.
    /// @dev The bounded form exists so KeeperGuard can enforce a size cap. A
    ///      cap is only meaningful if the caller cannot ask for everything.
    function deployIdle(uint256 maxAssets) external returns (uint256) {
        return _deployIdle(maxAssets);
    }

    function _deployIdle(uint256 maxAssets) internal returns (uint256 deployed) {
        _requireAutomation();

        uint256 idle = _idle();
        uint256 target = (totalAssets() * bufferBps) / BPS;
        if (idle <= target) return 0;

        deployed = idle - target;
        if (deployed > maxAssets) deployed = maxAssets;
        if (deployed == 0) return 0;

        IERC20(asset()).forceApprove(address(yieldVault), deployed);
        yieldVault.deposit(deployed, address(this));
        emit Deployed(deployed);
    }

    /// @notice Address permitted to run automation alongside the owner.
    /// @dev Setting it to the zero address turns automation off entirely.
    function setGuard(address newGuard) external onlyOwner {
        guard = newGuard;
        emit GuardUpdated(newGuard);
    }

    /// @dev Automation may allocate. It may not unwind, retune or reprice
    ///      anything — those stay with the owner. See KeeperGuard.
    function _requireAutomation() internal view {
        if (msg.sender != owner() && msg.sender != guard) revert NotAutomation();
    }

    /// @notice Pull everything back out of the lending vault into idle.
    /// @dev Escape hatch. Moves assets toward depositors, never away from them.
    function recallAll() external onlyOwner returns (uint256 recalled) {
        uint256 shares = yieldVault.balanceOf(address(this));
        if (shares == 0) return 0;
        recalled = yieldVault.redeem(shares, address(this), address(this));
        emit Recalled(recalled);
    }

    /// @notice Attach the equity leg and set the target split.
    /// @dev Detaching requires the basket to be empty first, so a position can
    ///      never be stranded in an adapter the vault has stopped counting.
    function setBasket(BasketAdapter newBasket, uint16 newTargetStableBps) external onlyOwner {
        if (newTargetStableBps > BPS) revert SplitOutOfRange();
        if (address(basket) != address(0) && basket.totalValueUsd() != 0) revert BasketNotEmpty();

        basket = newBasket;
        targetStableBps = newTargetStableBps;
        emit BasketUpdated(address(newBasket), newTargetStableBps);
    }

    function setTargetStableBps(uint16 newTargetStableBps) external onlyOwner {
        if (newTargetStableBps > BPS) revert SplitOutOfRange();
        targetStableBps = newTargetStableBps;
        emit BasketUpdated(address(basket), newTargetStableBps);
    }

    function setBufferBps(uint16 newBufferBps) external onlyOwner {
        if (newBufferBps > BPS) revert BufferTooHigh();
        bufferBps = newBufferBps;
        emit BufferUpdated(newBufferBps);
    }

    // ---------------------------------------------------------------------
    // Internals
    // ---------------------------------------------------------------------

    function _idle() internal view returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }

    function _sharePrice() internal view returns (uint256) {
        return _convertToAssets(10 ** decimals(), Math.Rounding.Floor);
    }

    function _stableAssets() internal view returns (uint256) {
        return _idle() + yieldVault.convertToAssets(yieldVault.balanceOf(address(this)));
    }

    /// @dev USDG is treated as exactly one dollar. There is no USDG/USD feed on
    ///      this chain to do better, so the assumption is stated rather than
    ///      hidden: a depeg misprices the equity leg against the stable leg.
    function _usdToAssets(uint256 usd) internal view returns (uint256) {
        return usd / (10 ** (18 - _assetDecimals));
    }

    /// @dev Top up idle from the lending vault before paying an exit.
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal override nonReentrant {
        uint256 idle = _idle();
        if (idle < assets) {
            uint256 missing = assets - idle;
            yieldVault.withdraw(missing, address(this), address(this));
            emit Recalled(missing);
        }
        super._withdraw(caller, receiver, owner, assets, shares);
    }

    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal override nonReentrant {
        super._deposit(caller, receiver, assets, shares);
    }
}
