// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";

import {BuybackModule} from "../src/BuybackModule.sol";
import {RobinhoodChain} from "../src/RobinhoodChain.sol";

/// @notice A real buyback through a real Uniswap v4 pool, on a fork.
///
/// @dev $BLUR does not exist yet, so this exercises the module against an
///      unrelated token that is already listed against USDG on this chain. It
///      is a stand-in for the venue, nothing more: none of it is our token, and
///      no figure here describes $BLUR. What it proves is that the module
///      settles a real v4 swap and retires what it receives -- the part the
///      unit tests deliberately mock away.
///
///      It also records what a thin market does to a buyback, which is the
///      thing that should set maxSpendPerCall. This stand-in is listed in 25
///      pools, most of them traps: fee tiers of 87%, 89%, even 99.978%, which
///      would keep almost the whole trade. Whichever pool $BLUR eventually
///      lives in, the module must be pointed at it explicitly and never infer
///      one.
contract BuybackForkTest is Test {
    IPoolManager constant POOL_MANAGER = IPoolManager(0x8366a39CC670B4001A1121B8F6A443A643e40951);

    /// @dev Not ours. An arbitrary token with a live USDG pool, standing in for
    ///      $BLUR until $BLUR exists.
    address constant STAND_IN = 0x8ECEA3d0E648DB646d824AA51EedeB16aC3d6878;

    IERC20 usdg = IERC20(RobinhoodChain.USDG);
    IERC20 token = IERC20(STAND_IN);

    BuybackModule module;
    address owner = makeAddr("owner");
    address constant GRAVEYARD = 0x000000000000000000000000000000000000dEaD;

    uint256 constant ONE = 1e6;

    function setUp() public {
        vm.createSelectFork(vm.envOr("ROBINHOOD_RPC", vm.rpcUrl("robinhood")));
        module = new BuybackModule(owner, address(usdg), STAND_IN, POOL_MANAGER);
    }

    /// @dev USDG/token, the standard 1% tier. USDG sorts below the token, so it
    ///      is currency0.
    function _onePercentPool() internal pure returns (PoolKey memory) {
        return PoolKey({
            currency0: Currency.wrap(RobinhoodChain.USDG),
            currency1: Currency.wrap(STAND_IN),
            fee: 10_000,
            tickSpacing: 200,
            hooks: IHooks(address(0))
        });
    }

    /// @dev The deepest USDG pool by raw liquidity, at a 4.6% fee.
    function _deepestUsdgPool() internal pure returns (PoolKey memory) {
        return PoolKey({
            currency0: Currency.wrap(RobinhoodChain.USDG),
            currency1: Currency.wrap(STAND_IN),
            fee: 46_000,
            tickSpacing: 920,
            hooks: IHooks(address(0))
        });
    }

    function _fund(uint256 amount) internal {
        deal(address(usdg), address(module), amount);
    }

    // -----------------------------------------------------------------
    // The fixture, pinned rather than assumed
    // -----------------------------------------------------------------

    /// @dev If the stand-in changes underneath us, every number below stops
    ///      meaning anything, so this fails first and says why.
    function test_StandInIsUnchanged() public view {
        assertEq(IERC20Metadata(STAND_IN).symbol(), "wire", "stand-in changed");
        assertEq(IERC20Metadata(STAND_IN).decimals(), 18);
        assertEq(IERC20Metadata(STAND_IN).totalSupply(), 1_000_000_000e18);
    }

    /// @dev This stand-in has no burn function, which is why the module retires
    ///      by transfer rather than by burning. If $BLUR ships with a burn, the
    ///      module can call it instead and supply would genuinely fall.
    function test_StandInCannotBeBurned() public {
        deal(STAND_IN, address(this), 1e18);

        (bool ok,) = STAND_IN.call(abi.encodeWithSignature("burn(uint256)", 1e18));
        assertFalse(ok, "stand-in grew a burn function");

        // And the zero address is refused, which is why GRAVEYARD is 0xdEaD.
        vm.expectRevert();
        token.transfer(address(0), 1e18);
    }

    // -----------------------------------------------------------------
    // A real buyback
    // -----------------------------------------------------------------

    function test_BuysAndRetiresThroughTheRealPool() public {
        vm.prank(owner);
        module.setPool(_onePercentPool());

        _fund(100 * ONE);

        // The graveyard is not ours and is not empty: others have sent tokens
        // there already. Only the change caused by this call means anything.
        uint256 graveyardBefore = token.balanceOf(GRAVEYARD);

        vm.prank(owner);
        uint256 retired = module.buyback(100 * ONE, 1);

        assertGt(retired, 0, "nothing came back");
        assertEq(token.balanceOf(GRAVEYARD) - graveyardBefore, retired, "not retired");
        assertEq(token.balanceOf(address(module)), 0, "kept some back");
        assertEq(module.totalRetired(), retired);

        console2.log("spent (USDG 1e6) :", module.totalSpent());
        console2.log("retired (1e18)   :", retired);
        console2.log("tokens per USDG  :", (retired / 1e18) / (module.totalSpent() / ONE));
    }

    /// @dev What a buyback actually costs at size. Printed rather than asserted
    ///      against a threshold, because the honest output of this test is a
    ///      number the operator has to look at before setting maxSpendPerCall.
    function test_PriceImpactAcrossSizes() public {
        uint256[4] memory sizes = [uint256(10), 100, 1_000, 10_000];

        for (uint256 i = 0; i < sizes.length; i++) {
            uint256 snapshot = vm.snapshotState();

            BuybackModule fresh = new BuybackModule(owner, address(usdg), STAND_IN, POOL_MANAGER);
            vm.prank(owner);
            fresh.setPool(_onePercentPool());

            uint256 spend = sizes[i] * ONE;
            deal(address(usdg), address(fresh), spend);

            vm.prank(owner);
            try fresh.buyback(spend, 1) returns (uint256 retired) {
                // Whole tokens received per whole USDG spent.
                console2.log("USDG in:", sizes[i], "tokens per USDG:", (retired / 1e18) / sizes[i]);
            } catch {
                console2.log("USDG in:", sizes[i], "-> reverted (insufficient depth)");
            }

            vm.revertToState(snapshot);
        }
    }

    function test_DeepestUsdgPoolAlsoExecutes() public {
        vm.prank(owner);
        module.setPool(_deepestUsdgPool());

        _fund(100 * ONE);

        vm.prank(owner);
        uint256 retired = module.buyback(100 * ONE, 1);

        console2.log("4.6% pool, 100 USDG -> tokens:", retired / 1e18);
        assertGt(retired, 0);
    }

    /// @dev The minimum is enforced on what actually arrives, so an operator who
    ///      names a price the pool cannot fill gets a revert, not a bad fill.
    function test_MinimumOutIsEnforcedAgainstTheRealPool() public {
        vm.prank(owner);
        module.setPool(_onePercentPool());

        _fund(100 * ONE);

        vm.prank(owner);
        vm.expectRevert();
        module.buyback(100 * ONE, 1_000_000_000e18);
    }
}
