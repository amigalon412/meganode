// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {RobinhoodChain} from "../src/RobinhoodChain.sol";

/// @notice Not assertions about our code — questions about the lending vault we
///         are about to depend on. Kept in the suite because the answers decide
///         what the product can honestly promise.
contract DiagnosticsForkTest is Test {
    IERC20 constant usdg = IERC20(RobinhoodChain.USDG);
    IERC4626 constant steak = IERC4626(RobinhoodChain.STEAK_USDG);

    address depositor = makeAddr("depositor");
    uint256 constant ONE = 1e6;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("robinhood"));
        deal(address(usdg), depositor, 50_000 * ONE);
    }

    function test_Diag_LiquidityAndAccrual() public {
        console2.log("--- steakUSDG at head ---");
        console2.log("totalAssets (USDG)   :", steak.totalAssets() / ONE);
        console2.log("totalSupply          :", steak.totalSupply());
        console2.log("price per 1e18 share :", steak.convertToAssets(1e18));

        vm.startPrank(depositor);
        usdg.approve(address(steak), type(uint256).max);
        uint256 shares = steak.deposit(10_000 * ONE, depositor);
        vm.stopPrank();

        console2.log("--- after depositing 10,000 USDG ---");
        console2.log("our shares           :", shares);
        console2.log("convertToAssets      :", steak.convertToAssets(shares));
        console2.log("maxWithdraw(us)      :", steak.maxWithdraw(depositor));
        console2.log("maxRedeem(us)        :", steak.maxRedeem(depositor));

        uint256 priceBefore = steak.convertToAssets(1e18);

        vm.warp(block.timestamp + 90 days);
        console2.log("--- after warping 90 days ---");
        uint256 priceAfter = steak.convertToAssets(1e18);
        console2.log("price per 1e18 share :", priceAfter);
        console2.log("maxWithdraw(us)      :", steak.maxWithdraw(depositor));

        if (priceAfter > priceBefore) {
            uint256 aprBps = ((priceAfter - priceBefore) * 10_000 * 365) / (priceBefore * 90);
            console2.log("implied APR (bps)    :", aprBps);
        } else {
            console2.log("implied APR (bps)    : 0 - share price did not move");
        }

        vm.roll(block.number + 1);
        console2.log("after roll, price    :", steak.convertToAssets(1e18));
    }
}
