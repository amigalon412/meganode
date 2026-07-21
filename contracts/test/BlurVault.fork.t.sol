// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {BlurVault} from "../src/BlurVault.sol";
import {RobinhoodChain} from "../src/RobinhoodChain.sol";

/// @notice Runs against a fork of Robinhood Chain, so the yield is the real
///         rate Morpho is paying rather than a number we invented.
contract BlurVaultForkTest is Test {
    IERC20 constant usdg = IERC20(RobinhoodChain.USDG);
    IERC4626 constant steak = IERC4626(RobinhoodChain.STEAK_USDG);

    BlurVault vault;

    address owner = makeAddr("owner");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    uint256 constant ONE = 1e6; // USDG has 6 decimals

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("robinhood"));

        vault = new BlurVault(usdg, steak, "BLUR Steady", "blurSTEADY", owner);

        deal(address(usdg), alice, 100_000 * ONE);
        deal(address(usdg), bob, 100_000 * ONE);
    }

    // ------------------------------------------------------------------
    // Wiring
    // ------------------------------------------------------------------

    function test_ForkIsRobinhoodChain() public view {
        assertEq(block.chainid, RobinhoodChain.CHAIN_ID, "wrong chain");
    }

    function test_UnderlyingIsRealAndFunded() public view {
        // If these ever fail, the addresses in RobinhoodChain.sol moved.
        assertEq(steak.asset(), address(usdg), "steakUSDG is not a USDG vault");
        assertGt(steak.totalAssets(), 1_000_000 * ONE, "lending vault looks empty");
    }

    function test_DecimalsCarryTheOffset() public view {
        assertEq(vault.decimals(), 12, "6 asset decimals + 6 offset");
    }

    // ------------------------------------------------------------------
    // Core cycle
    // ------------------------------------------------------------------

    function test_DepositMintsProportionalShares() public {
        _deposit(alice, 1_000 * ONE);
        _deposit(bob, 3_000 * ONE);

        uint256 aliceValue = vault.previewRedeem(vault.balanceOf(alice));
        uint256 bobValue = vault.previewRedeem(vault.balanceOf(bob));

        // Bob put in 3x what Alice did, so he owns 3x the claim (± rounding).
        assertApproxEqRel(bobValue, aliceValue * 3, 1e12, "shares not proportional");
    }

    function test_RoundTripNeverProfits() public {
        uint256 amount = 5_000 * ONE;
        _deposit(alice, amount);

        // Read the balance before pranking: an argument expression consumes the
        // prank, and the redeem would then run as the test contract.
        uint256 shares = vault.balanceOf(alice);
        vm.prank(alice);
        uint256 out = vault.redeem(shares, alice, alice);

        assertLe(out, amount, "round trip minted value from nothing");
        assertApproxEqAbs(out, amount, 2, "round trip lost more than rounding dust");
    }

    // ------------------------------------------------------------------
    // Current state of the lending venue
    //
    // These two assert what steakUSDG does *today*, not what we want it to do.
    // Both are blockers for going live, and phrasing them as tests means we
    // find out the moment the chain changes underneath us instead of guessing.
    // ------------------------------------------------------------------

    /// @dev Measures, deliberately does not pin, the rate. Accrual here has been
    ///      inconsistent between runs: a probe that deposited first saw the price
    ///      frozen over 90 days, while this one sees it move. Until we understand
    ///      why, the only safe assertion is that the price never falls — quoting
    ///      an APR off this would be quoting noise.
    function test_State_LendingVaultAccrual() public {
        uint256 priceBefore = steak.convertToAssets(1e18);
        vm.warp(block.timestamp + 90 days);
        uint256 priceAfter = steak.convertToAssets(1e18);

        console2.log("steakUSDG price before  :", priceBefore);
        console2.log("steakUSDG price after 90d:", priceAfter);
        if (priceAfter > priceBefore) {
            console2.log("implied APR (bps):", ((priceAfter - priceBefore) * 10_000 * 365) / (priceBefore * 90));
        }

        assertGe(priceAfter, priceBefore, "lending vault share price went backwards");
    }

    /// @dev BLOCKER: the venue reports no withdrawable liquidity and no deposit
    ///      capacity, while still accepting deposits. Until this changes, funds
    ///      routed there cannot be pulled back out, so `deployIdle` must not be
    ///      used against it on mainnet.
    function test_State_LendingVaultIsNotExitable() public {
        _deposit(alice, 10_000 * ONE);
        vm.prank(owner);
        vault.deployIdle();

        assertEq(steak.maxWithdraw(address(vault)), 0, "steakUSDG opened up - revisit exit assumptions");
        assertEq(steak.maxDeposit(address(vault)), 0, "steakUSDG reports capacity now");

        // Our own limit reporting must reflect that: only the idle buffer is
        // claimable, and redeem reverts cleanly rather than failing deep inside.
        assertLt(vault.maxRedeem(alice), vault.balanceOf(alice), "vault overstated what it can pay");
    }

    /// @dev With nothing deployed, the full cycle works against the real chain.
    function test_ExitWorksWhileFundsAreIdle() public {
        _deposit(alice, 10_000 * ONE);

        uint256 balBefore = usdg.balanceOf(alice);
        uint256 shares = vault.balanceOf(alice);
        vm.prank(alice);
        vault.redeem(shares, alice, alice);

        assertApproxEqAbs(usdg.balanceOf(alice) - balBefore, 10_000 * ONE, 2, "did not get the deposit back");
        assertLe(vault.totalAssets(), 2, "vault should be empty after the only holder leaves");
    }

    // ------------------------------------------------------------------
    // The classic ERC-4626 attack
    // ------------------------------------------------------------------

    function test_InflationAttackDoesNotStealFromVictim() public {
        address attacker = alice;
        address victim = bob;

        // 1 wei of shares, then a fat donation straight to the vault balance.
        vm.startPrank(attacker);
        usdg.approve(address(vault), type(uint256).max);
        vault.deposit(1, attacker);
        usdg.transfer(address(vault), 10_000 * ONE);
        vm.stopPrank();

        uint256 victimDeposit = 5_000 * ONE;
        _deposit(victim, victimDeposit);

        uint256 victimShares = vault.balanceOf(victim);
        assertGt(victimShares, 0, "victim was rounded down to zero shares");

        vm.prank(victim);
        uint256 recovered = vault.redeem(victimShares, victim, victim);

        // The victim should get essentially all of their money back; the
        // attacker eats the donation rather than the other way round.
        assertGe(recovered, (victimDeposit * 9999) / 10_000, "victim lost value to the attacker");
    }

    // ------------------------------------------------------------------
    // Custody
    // ------------------------------------------------------------------

    function test_OwnerCannotMoveDepositorFunds() public {
        _deposit(alice, 1_000 * ONE);

        uint256 ownerBalanceBefore = usdg.balanceOf(owner);

        vm.startPrank(owner);
        vault.deployIdle();
        vault.recallAll();
        vault.setBufferBps(10_000);
        vm.stopPrank();

        assertEq(usdg.balanceOf(owner), ownerBalanceBefore, "owner extracted assets");
        assertEq(vault.balanceOf(owner), 0, "owner minted itself shares");
        assertApproxEqAbs(vault.previewRedeem(vault.balanceOf(alice)), 1_000 * ONE, 2, "alice's claim moved");
    }

    // ------------------------------------------------------------------

    function _deposit(address who, uint256 amount) internal {
        vm.startPrank(who);
        usdg.approve(address(vault), amount);
        vault.deposit(amount, who);
        vm.stopPrank();
    }
}
