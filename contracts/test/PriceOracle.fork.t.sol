// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {PriceOracle} from "../src/PriceOracle.sol";
import {RobinhoodChain} from "../src/RobinhoodChain.sol";

/// @notice Against the real Chainlink feeds. A mock proves the arithmetic; only
///         the live feeds prove the addresses and decimals are right.
contract PriceOracleForkTest is Test {
    PriceOracle oracle;
    address owner = makeAddr("owner");

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("robinhood"));
        oracle = new PriceOracle(owner);

        vm.startPrank(owner);
        oracle.setFeed(RobinhoodChain.NVDA, RobinhoodChain.NVDA_USD_FEED, 24 hours);
        oracle.setFeed(RobinhoodChain.AAPL, RobinhoodChain.AAPL_USD_FEED, 24 hours);
        oracle.setFeed(RobinhoodChain.TSLA, RobinhoodChain.TSLA_USD_FEED, 24 hours);
        vm.stopPrank();
    }

    function test_LiveFeedsReturnPlausiblePrices() public view {
        uint256 nvda = oracle.priceUsd(RobinhoodChain.NVDA);
        uint256 aapl = oracle.priceUsd(RobinhoodChain.AAPL);
        uint256 tsla = oracle.priceUsd(RobinhoodChain.TSLA);

        console2.log("NVDA:", nvda / 1e18);
        console2.log("AAPL:", aapl / 1e18);
        console2.log("TSLA:", tsla / 1e18);

        // Deliberately wide. This catches a wrong address or a decimals error
        // by six orders of magnitude, not a market move.
        assertGt(nvda, 1e18, "NVDA below $1 - wrong feed or scaling");
        assertLt(nvda, 100_000e18, "NVDA above $100k - wrong feed or scaling");
        assertGt(aapl, 1e18);
        assertLt(aapl, 100_000e18);
        assertGt(tsla, 1e18);
        assertLt(tsla, 100_000e18);
    }

    function test_ValuingARealPositionIsSane() public view {
        // Ten whole NVDA tokens, which are 18 decimals on this chain.
        uint256 value = oracle.valueUsd(RobinhoodChain.NVDA, 10e18, 18);
        uint256 unit = oracle.priceUsd(RobinhoodChain.NVDA);
        assertEq(value, unit * 10, "position value is not ten times the unit price");
    }

    /// @notice Documents the staleness we actually observe, without pinning a
    ///         number that changes with the market clock.
    function test_ObservedFeedAges() public view {
        _report("NVDA", RobinhoodChain.NVDA);
        _report("AAPL", RobinhoodChain.AAPL);
        _report("TSLA", RobinhoodChain.TSLA);
    }

    /// @notice A tight threshold must reject an equity feed outside of session
    ///         hours rather than quietly pricing on a stale print.
    function test_TightThresholdRefusesOutsideSessionHours() public {
        vm.prank(owner);
        oracle.setFeed(RobinhoodChain.NVDA, RobinhoodChain.NVDA_USD_FEED, 60);

        (, uint256 updatedAt,) = oracle.priceUsdUnsafe(RobinhoodChain.NVDA);
        if (block.timestamp - updatedAt > 60) {
            assertFalse(oracle.isFresh(RobinhoodChain.NVDA));
            vm.expectRevert();
            oracle.priceUsd(RobinhoodChain.NVDA);
        }
    }

    function _report(string memory name, address token) internal view {
        (uint256 price, uint256 updatedAt, bool fresh) = oracle.priceUsdUnsafe(token);
        console2.log(name, "price:", price / 1e18);
        console2.log(name, "age (minutes):", (block.timestamp - updatedAt) / 60);
        console2.log(name, "fresh at 24h:", fresh);
    }
}
