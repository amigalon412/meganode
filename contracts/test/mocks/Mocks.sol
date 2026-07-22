// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev Stand-in for USDG: 6 decimals, freely mintable.
contract MockERC20 is ERC20 {
    uint8 private immutable _dec;

    constructor(string memory n, string memory s, uint8 d) ERC20(n, s) {
        _dec = d;
    }

    function decimals() public view override returns (uint8) {
        return _dec;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}

/// @dev A token that can reduce its own supply, which is what $BLUR is meant to
///      be. `burn(uint256)` is the signature BuybackModule calls.
contract MockBurnableERC20 is MockERC20 {
    constructor(string memory n, string memory s, uint8 d) MockERC20(n, s, d) {}

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}

/// @dev Stand-in for the external lending vault. Pays a fixed APR, but only
///      when poked, so tests decide exactly when interest lands.
contract MockYieldVault is ERC4626 {
    uint256 public aprBps;
    uint256 public lastAccrual;

    constructor(IERC20 asset_, uint256 aprBps_) ERC20("Mock Yield", "mYIELD") ERC4626(asset_) {
        aprBps = aprBps_;
        lastAccrual = block.timestamp;
    }

    /// @notice Mint the interest earned since the last call straight into the vault,
    ///         which lifts the share price for everyone holding it.
    function accrue() public {
        uint256 elapsed = block.timestamp - lastAccrual;
        lastAccrual = block.timestamp;
        if (elapsed == 0) return;

        uint256 principal = totalAssets();
        uint256 interest = (principal * aprBps * elapsed) / (10_000 * 365 days);
        if (interest > 0) MockERC20(asset()).mint(address(this), interest);
    }

    function totalAssets() public view override returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }
}
