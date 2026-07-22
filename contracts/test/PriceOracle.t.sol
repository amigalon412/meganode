// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {PriceOracle, IAggregatorV3} from "../src/PriceOracle.sol";

/// @dev Chainlink-shaped feed we can drive.
contract MockAggregator is IAggregatorV3 {
    uint8 public decimals;
    string public description;
    int256 public answer;
    uint256 public updatedAt;

    constructor(uint8 d, string memory desc, int256 a) {
        decimals = d;
        description = desc;
        answer = a;
        updatedAt = block.timestamp;
    }

    function set(int256 a, uint256 t) external {
        answer = a;
        updatedAt = t;
    }

    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        return (1, answer, updatedAt, updatedAt, 1);
    }
}

contract PriceOracleTest is Test {
    PriceOracle oracle;
    MockAggregator nvdaFeed;

    address owner = makeAddr("owner");
    address NVDA = makeAddr("NVDA");
    address UNKNOWN = makeAddr("UNKNOWN");

    uint32 constant MAX_AGE = 2 hours;

    function setUp() public {
        vm.warp(1_700_000_000); // a realistic timestamp, not 1
        oracle = new PriceOracle(owner);
        nvdaFeed = new MockAggregator(8, "RHNVDA / USD", 206_27000000); // $206.27

        vm.prank(owner);
        oracle.setFeed(NVDA, address(nvdaFeed), MAX_AGE);
    }

    // ------------------------------------------------------------------
    // Scaling
    // ------------------------------------------------------------------

    function test_PriceIsScaledToWadRegardlessOfFeedDecimals() public {
        assertEq(oracle.priceUsd(NVDA), 206.27e18, "8-decimal feed not normalised");

        // Same price from an 18-decimal feed must give the same answer.
        MockAggregator wide = new MockAggregator(18, "RHNVDA / USD", 206.27e18);
        address other = makeAddr("other");
        vm.prank(owner);
        oracle.setFeed(other, address(wide), MAX_AGE);
        assertEq(oracle.priceUsd(other), 206.27e18, "18-decimal feed not normalised");
    }

    function test_ValueOfAPositionIsScaledToWad() public view {
        // 3.5 tokens of an 18-decimal stock at $206.27 = $721.945
        assertEq(oracle.valueUsd(NVDA, 3.5e18, 18), 721.945e18);
        // A 6-decimal token must give the same answer for the same quantity.
        assertEq(oracle.valueUsd(NVDA, 3_500_000, 6), 721.945e18);
    }

    function testFuzz_ValueScalesLinearly(uint96 rawAmount) public view {
        uint256 amount = bound(uint256(rawAmount), 0, 1_000_000e18);
        assertEq(oracle.valueUsd(NVDA, amount, 18), (206.27e18 * amount) / 1e18);
    }

    // ------------------------------------------------------------------
    // Refusing to answer
    // ------------------------------------------------------------------

    function test_StalePriceReverts() public {
        nvdaFeed.set(206_27000000, block.timestamp - MAX_AGE - 1);

        vm.expectRevert();
        oracle.priceUsd(NVDA);
        assertFalse(oracle.isFresh(NVDA));
    }

    function test_PriceAtExactlyTheLimitIsStillGood() public {
        nvdaFeed.set(206_27000000, block.timestamp - MAX_AGE);
        assertEq(oracle.priceUsd(NVDA), 206.27e18);
        assertTrue(oracle.isFresh(NVDA));
    }

    function test_NegativeOrZeroPriceReverts() public {
        nvdaFeed.set(0, block.timestamp);
        vm.expectRevert();
        oracle.priceUsd(NVDA);

        nvdaFeed.set(-1, block.timestamp);
        vm.expectRevert();
        oracle.priceUsd(NVDA);

        assertFalse(oracle.isFresh(NVDA));
    }

    function test_UnknownTokenReverts() public {
        vm.expectRevert(abi.encodeWithSelector(PriceOracle.NoFeed.selector, UNKNOWN));
        oracle.priceUsd(UNKNOWN);
        assertFalse(oracle.isFresh(UNKNOWN), "an unconfigured token must never look fresh");
    }

    /// @notice The unsafe read still works when the safe one refuses, and says so.
    function test_UnsafeReadReportsStalenessRatherThanReverting() public {
        nvdaFeed.set(206_27000000, block.timestamp - MAX_AGE - 1);

        (uint256 price, uint256 updatedAt, bool fresh) = oracle.priceUsdUnsafe(NVDA);
        assertEq(price, 206.27e18);
        assertEq(updatedAt, block.timestamp - MAX_AGE - 1);
        assertFalse(fresh);
    }

    // ------------------------------------------------------------------
    // Per-feed thresholds — the point of the design
    // ------------------------------------------------------------------

    function test_ThresholdsAreIndependentPerFeed() public {
        // SPY updates roughly every 10 hours; AAPL every half hour. One global
        // limit cannot serve both, which is why maxAge is per feed.
        address SPY = makeAddr("SPY");
        MockAggregator spyFeed = new MockAggregator(8, "RHSPY / USD", 747_06000000);
        vm.prank(owner);
        oracle.setFeed(SPY, address(spyFeed), 12 hours);

        uint256 sixHoursAgo = block.timestamp - 6 hours;
        nvdaFeed.set(206_27000000, sixHoursAgo);
        spyFeed.set(747_06000000, sixHoursAgo);

        assertFalse(oracle.isFresh(NVDA), "NVDA should be stale after six hours");
        assertTrue(oracle.isFresh(SPY), "SPY should still be good after six hours");
    }

    // ------------------------------------------------------------------
    // Configuration
    // ------------------------------------------------------------------

    function test_OnlyOwnerConfigures() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        oracle.setFeed(NVDA, address(nvdaFeed), MAX_AGE);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(this)));
        oracle.removeFeed(NVDA);
    }

    function test_ZeroMaxAgeIsRejected() public {
        vm.prank(owner);
        vm.expectRevert(PriceOracle.ZeroMaxAge.selector);
        oracle.setFeed(NVDA, address(nvdaFeed), 0);
    }

    function test_DeadFeedCannotBeRegistered() public {
        MockAggregator dead = new MockAggregator(8, "DEAD / USD", 0);
        vm.prank(owner);
        vm.expectRevert();
        oracle.setFeed(makeAddr("dead"), address(dead), MAX_AGE);
    }

    function test_RemovedFeedStopsAnswering() public {
        vm.prank(owner);
        oracle.removeFeed(NVDA);

        vm.expectRevert(abi.encodeWithSelector(PriceOracle.NoFeed.selector, NVDA));
        oracle.priceUsd(NVDA);
    }
}
