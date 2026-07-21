// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IAllocatable {
    function deployIdle(uint256 maxAssets) external returns (uint256);
}

/// @title KeeperGuard
/// @notice The only address a vault trusts to run automation, and the place
///         every limit on that automation is enforced.
///
/// @dev The point of this contract is what it *cannot* be made to do. A keeper
///      key is online, so it will eventually be treated as compromised. The
///      design target is that a fully compromised keeper costs the protocol
///      rounding dust and gas, and nothing else — it cannot move funds to an
///      address of its choosing, cannot unwind a position, cannot change a fee,
///      a buffer or an owner, and cannot act on a vault nobody registered.
///
///      Today the only automated action is allocation, so the applicable limits
///      are the caller allowlist, the vault allowlist, a per-call size cap and a
///      cooldown. Trading brings asset allowlists, slippage caps and oracle
///      freshness; they belong here too, checked before the call goes through.
contract KeeperGuard is Ownable {
    /// @notice Keepers permitted to trigger automation.
    mapping(address => bool) public isKeeper;

    /// @notice Vaults this guard is allowed to drive.
    mapping(address => bool) public isVault;

    /// @notice Addresses that may halt automation without being able to run it.
    mapping(address => bool) public isSentinel;

    /// @notice Largest amount a single call may allocate.
    uint256 public maxDeployPerCall;

    /// @notice Minimum seconds between actions on the same vault.
    uint32 public cooldown;

    /// @notice When true, every automated action reverts. Owner or sentinel.
    bool public paused;

    mapping(address => uint256) public lastActionAt;

    event KeeperSet(address keeper, bool allowed);
    event VaultSet(address vault, bool allowed);
    event SentinelSet(address sentinel, bool allowed);
    event LimitsUpdated(uint256 maxDeployPerCall, uint32 cooldown);
    event PausedSet(bool paused);
    event Deployed(address indexed vault, address indexed keeper, uint256 assets);

    error NotKeeper();
    error NotSentinel();
    error VaultNotAllowed();
    error CoolingDown();
    error Paused();

    constructor(address owner_, uint256 maxDeployPerCall_, uint32 cooldown_) Ownable(owner_) {
        maxDeployPerCall = maxDeployPerCall_;
        cooldown = cooldown_;
    }

    // ---------------------------------------------------------------------
    // Automation
    // ---------------------------------------------------------------------

    /// @notice Move a vault's idle balance into its lending venue, within limits.
    function deployIdle(address vault) external returns (uint256 deployed) {
        if (paused) revert Paused();
        if (!isKeeper[msg.sender]) revert NotKeeper();
        if (!isVault[vault]) revert VaultNotAllowed();
        // A vault that has never been acted on is not cooling down. Comparing
        // against a zero timestamp would otherwise lock out the first call.
        uint256 last = lastActionAt[vault];
        if (last != 0 && block.timestamp < last + cooldown) revert CoolingDown();

        lastActionAt[vault] = block.timestamp;
        deployed = IAllocatable(vault).deployIdle(maxDeployPerCall);
        emit Deployed(vault, msg.sender, deployed);
    }

    // ---------------------------------------------------------------------
    // Halting
    // ---------------------------------------------------------------------

    /// @dev A sentinel can stop automation but cannot start it or run it. The
    ///      asymmetry is deliberate: halting is safe to hand out widely,
    ///      resuming is not.
    function pause() external {
        if (!isSentinel[msg.sender] && msg.sender != owner()) revert NotSentinel();
        paused = true;
        emit PausedSet(true);
    }

    function unpause() external onlyOwner {
        paused = false;
        emit PausedSet(false);
    }

    // ---------------------------------------------------------------------
    // Configuration
    // ---------------------------------------------------------------------

    function setKeeper(address keeper, bool allowed) external onlyOwner {
        isKeeper[keeper] = allowed;
        emit KeeperSet(keeper, allowed);
    }

    function setVault(address vault, bool allowed) external onlyOwner {
        isVault[vault] = allowed;
        emit VaultSet(vault, allowed);
    }

    function setSentinel(address sentinel, bool allowed) external onlyOwner {
        isSentinel[sentinel] = allowed;
        emit SentinelSet(sentinel, allowed);
    }

    function setLimits(uint256 maxDeployPerCall_, uint32 cooldown_) external onlyOwner {
        maxDeployPerCall = maxDeployPerCall_;
        cooldown = cooldown_;
        emit LimitsUpdated(maxDeployPerCall_, cooldown_);
    }
}
