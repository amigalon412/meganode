// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

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

    event Deployed(uint256 assets);
    event Recalled(uint256 assets);
    event BufferUpdated(uint16 bufferBps);
    event FeeAccrued(uint256 feeAssets, uint256 feeShares, uint256 newHighWaterMark);
    event FeeRecipientUpdated(address recipient);

    error AssetMismatch();
    error BufferTooHigh();
    error FeeTooHigh();
    error ZeroFeeRecipient();

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
        highWaterMark = _sharePrice();
    }

    /// @dev Virtual shares. Without this, the first depositor can donate assets
    ///      directly to the vault and round the next depositor's shares to zero.
    ///      An offset of 6 makes that attack cost more than it can ever extract.
    function _decimalsOffset() internal pure override returns (uint8) {
        return 6;
    }

    /// @inheritdoc ERC4626
    function totalAssets() public view override returns (uint256) {
        return _idle() + yieldVault.convertToAssets(yieldVault.balanceOf(address(this)));
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
    // Allocation
    // ---------------------------------------------------------------------

    /// @notice Move idle assets above the buffer into the lending vault.
    /// @dev Owner-only for now. Stage 3 moves this behind KeeperGuard so an
    ///      automated caller can run it under explicit on-chain limits.
    function deployIdle() external onlyOwner returns (uint256 deployed) {
        uint256 idle = _idle();
        uint256 target = (totalAssets() * bufferBps) / BPS;
        if (idle <= target) return 0;

        deployed = idle - target;
        IERC20(asset()).forceApprove(address(yieldVault), deployed);
        yieldVault.deposit(deployed, address(this));
        emit Deployed(deployed);
    }

    /// @notice Pull everything back out of the lending vault into idle.
    /// @dev Escape hatch. Moves assets toward depositors, never away from them.
    function recallAll() external onlyOwner returns (uint256 recalled) {
        uint256 shares = yieldVault.balanceOf(address(this));
        if (shares == 0) return 0;
        recalled = yieldVault.redeem(shares, address(this), address(this));
        emit Recalled(recalled);
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
