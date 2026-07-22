// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/src/types/Currency.sol";

import {SwapExecutor} from "../src/SwapExecutor.sol";
import {PriceOracle} from "../src/PriceOracle.sol";
import {RobinhoodChain} from "../src/RobinhoodChain.sol";

contract Swapper is SwapExecutor {
    constructor(IPoolManager pm) SwapExecutor(pm) {}

    function swap(PoolKey memory key, bool zeroForOne, uint256 amountIn) external returns (uint256) {
        return _executeSwap(
            SwapRequest({key: key, zeroForOne: zeroForOne, amountIn: amountIn, minAmountOut: 1})
        );
    }
}

/// @notice Proves `RobinhoodChain.basketPool` names a pool that actually trades.
///
/// @dev A pool key is four fields, and a wrong one does not fail loudly: it
///      either reverts as uninitialised or, worse, points at a real pool with a
///      predatory fee. These pairs have pools at 85% and 99.7% alongside the
///      honest 0.30% tier, so "the key parses" is not evidence of anything.
///
///      Each token below is bought for real and the fill is compared against
///      its Chainlink feed. A key naming the wrong pool cannot land within a
///      few percent of the oracle by accident, which makes this a test of the
///      constant rather than of Uniswap.
contract BasketPoolsForkTest is Test {
    IPoolManager constant POOL_MANAGER = IPoolManager(RobinhoodChain.POOL_MANAGER);

    Swapper swapper;
    PriceOracle oracle;
    address owner = makeAddr("owner");

    uint256 constant ONE = 1e6;
    /// @dev A trade small enough that impact should not explain a bad fill.
    uint256 constant TRADE = 1_000 * ONE;

    function setUp() public {
        vm.createSelectFork(vm.envOr("ROBINHOOD_RPC", vm.rpcUrl("robinhood")));
        swapper = new Swapper(POOL_MANAGER);
        oracle = new PriceOracle(owner);

        vm.startPrank(owner);
        oracle.setFeed(RobinhoodChain.NVDA, RobinhoodChain.NVDA_USD_FEED, 7 days);
        oracle.setFeed(RobinhoodChain.AAPL, RobinhoodChain.AAPL_USD_FEED, 7 days);
        oracle.setFeed(RobinhoodChain.TSLA, RobinhoodChain.TSLA_USD_FEED, 7 days);
        oracle.setFeed(RobinhoodChain.AMZN, RobinhoodChain.AMZN_USD_FEED, 7 days);
        oracle.setFeed(RobinhoodChain.AMD, RobinhoodChain.AMD_USD_FEED, 7 days);
        vm.stopPrank();
    }

    function test_NvdaPoolTradesNearTheOracle() public {
        _check("NVDA", RobinhoodChain.NVDA);
    }

    function test_AaplPoolTradesNearTheOracle() public {
        _check("AAPL", RobinhoodChain.AAPL);
    }

    function test_TslaPoolTradesNearTheOracle() public {
        _check("TSLA", RobinhoodChain.TSLA);
    }

    function test_AmznPoolTradesNearTheOracle() public {
        _check("AMZN", RobinhoodChain.AMZN);
    }

    /// @dev AMD looks like the others and is not. Its 0.30% USDG pool carries a
    ///      hook, so this key names a pool that was never initialised at all --
    ///      and the hooked one it does not name sits at a price of 1.0 with no
    ///      liquidity. Pinned so that adding AMD to a basket fails here rather
    ///      than at the first rebalance.
    function test_AmdHasNoPoolAtThisKey() public {
        PoolKey memory key = RobinhoodChain.basketPool(RobinhoodChain.AMD);
        deal(RobinhoodChain.USDG, address(swapper), TRADE);

        vm.expectRevert();
        swapper.swap(key, true, TRADE);
    }

    /// @dev USDG sorts above two of these tokens and below three, so this also
    ///      pins that `basketPool` orders the pair rather than assuming one way.
    function test_PairOrderingFollowsAddressOrder() public pure {
        // Below USDG, so the token is currency0.
        assertEq(Currency.unwrap(RobinhoodChain.basketPool(RobinhoodChain.TSLA).currency0), RobinhoodChain.TSLA);
        assertEq(Currency.unwrap(RobinhoodChain.basketPool(RobinhoodChain.AMZN).currency0), RobinhoodChain.AMZN);
        // Above USDG, so USDG is currency0.
        assertEq(Currency.unwrap(RobinhoodChain.basketPool(RobinhoodChain.NVDA).currency0), RobinhoodChain.USDG);
        assertEq(Currency.unwrap(RobinhoodChain.basketPool(RobinhoodChain.AAPL).currency0), RobinhoodChain.USDG);
        assertEq(Currency.unwrap(RobinhoodChain.basketPool(RobinhoodChain.AMD).currency0), RobinhoodChain.USDG);
    }

    function _check(string memory symbol, address token) internal {
        PoolKey memory key = RobinhoodChain.basketPool(token);
        bool zeroForOne = Currency.unwrap(key.currency0) == RobinhoodChain.USDG;

        deal(RobinhoodChain.USDG, address(swapper), TRADE);
        uint256 received = swapper.swap(key, zeroForOne, TRADE);
        assertGt(received, 0, "pool returned nothing");

        // What we paid per whole token, in 1e18 USD, against what the feed says.
        uint256 paidPerToken = (TRADE * 1e12 * 1e18) / received;
        uint256 oraclePrice = oracle.priceUsd(token);

        uint256 diffBps = paidPerToken > oraclePrice
            ? ((paidPerToken - oraclePrice) * 10_000) / oraclePrice
            : ((oraclePrice - paidPerToken) * 10_000) / oraclePrice;

        console2.log(symbol);
        console2.log("  paid per token (1e18):", paidPerToken);
        console2.log("  oracle       (1e18)  :", oraclePrice);
        console2.log("  difference       (bps):", diffBps);

        // 0.30% is the fee itself; the rest is spread and impact. Anything far
        // outside this means the key is naming a pool we did not intend.
        assertLt(diffBps, 500, "fill is nowhere near the oracle -- wrong pool?");
    }
}
