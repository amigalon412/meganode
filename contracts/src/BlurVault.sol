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

    event Deployed(uint256 assets);
    event Recalled(uint256 assets);
    event BufferUpdated(uint16 bufferBps);

    error AssetMismatch();
    error BufferTooHigh();

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
    // Liquidity-aware limits
    //
    // The base implementation assumes every asset is available on demand. Ours
    // are not: the lending vault can be short of liquidity, and reporting a
    // withdrawable amount we cannot actually pay would only turn a clear
    // rejection into a confusing revert deeper in the call.
    // ---------------------------------------------------------------------

    function maxWithdraw(address owner) public view override returns (uint256) {
        uint256 owned = super.maxWithdraw(owner);
        uint256 liquid = _liquid();
        return owned < liquid ? owned : liquid;
    }

    function maxRedeem(address owner) public view override returns (uint256) {
        uint256 owned = super.maxRedeem(owner);
        // Round the cap up. Rounding down costs a wei on the way through the
        // venue's own rounding and would block a holder from redeeming their
        // last share. The cap exists to catch a real shortfall, not dust.
        uint256 cap = _convertToShares(_liquid(), Math.Rounding.Ceil);
        return owned < cap ? owned : cap;
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

    /// @dev What the vault could pay out right now: idle plus the value of our
    ///      position in the lending vault.
    ///
    ///      Deliberately does NOT use `yieldVault.maxWithdraw`. The venue we
    ///      target (Morpho VaultV2) reports zero for both `maxWithdraw` and
    ///      `maxDeposit` while happily executing deposits and redemptions of the
    ///      full amount — verified on a fork. Trusting that view would make this
    ///      vault refuse every legitimate exit the moment funds were deployed.
    ///      A genuine shortfall at the venue instead surfaces as a revert inside
    ///      `_withdraw`, which is the honest failure: we do not know a payout is
    ///      impossible until we try it.
    function _liquid() internal view returns (uint256) {
        return _idle() + yieldVault.convertToAssets(yieldVault.balanceOf(address(this)));
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
