# BLUR contracts

Stage 1: the lending leg. `BlurVault` is an ERC-4626 vault that takes USDG,
issues shares, and routes idle balance into an external ERC-4626 lending vault.
The tokenized-stock leg, the bounded keeper role, fees and buyback are added on
top of this — `totalAssets()` is the seam they extend.

## Setup

Dependencies are not vendored. Install them at their pinned versions:

```bash
curl -L https://foundry.paradigm.xyz | bash && foundryup
cd contracts
forge install foundry-rs/forge-std
forge install OpenZeppelin/openzeppelin-contracts@v5.1.0
forge test
```

## Tests

| Suite | Needs network | Purpose |
|---|---|---|
| `BlurVault.t.sol` | no | Accounting, attacks, fuzz. The real test of our code. |
| `BlurVault.fork.t.sol` | yes | Wiring against live Robinhood Chain, plus assertions that pin the current state of the lending venue. |
| `Diagnostics.fork.t.sol` | yes | Non-asserting probes. Prints what the venue is actually doing. |

Fork tests use the official RPC (`rpc.mainnet.chain.robinhood.com`). The
publicnode endpoint rejects the archive reads forking needs, and Blockscout's
JSON-RPC shim rejects forge's block parameter format — neither works here.

## Where the yield comes from

Traced on-chain, end to end:

```
USDG  ->  steakUSDG                     Morpho VaultV2, $163.8M
              |                          fees: 0 management, 0 performance
              |  $9.99M idle
              v  $153.8M allocated
          MorphoMarketV1AdapterV2       0x44ABc1d6cCFF2696d98890B92E2157AF242179c2
              |
              v
          Morpho Blue                   0x9D53d5E3bd5E8d4Cbfa6DB1ca238AEA02E651010
              |
    +---------+---------+-----------------+
    v                   v                 v
 syrupUSDG            USDe             spUSDG          <- collateral
 (Maple)             (Ethena)      (Spark Savings)
 $41.2M supplied   $151.7M supplied  $11.3M supplied
 89.2% utilised     89.6% utilised    89.9% utilised
```

All three markets lend USDG against yield-bearing stablecoin collateral at
91.5% LLTV. The interest is paid by leveraged loopers borrowing USDG against
Spark, Ethena and Maple positions. That is the whole of the "real lending
yield" — no equity exposure anywhere in it.

## Notes on the venue

1. **Its ERC-4626 limit views cannot be trusted.** `maxDeposit` and
   `maxWithdraw` both return zero while `deposit` and `redeem` execute in full
   — verified on a fork, both directions, for the whole balance. `_liquid()`
   deliberately ignores them; see the comment there.
2. **Accrual is lazy.** Interest lands in `_totalAssets` only when
   `accrueInterest()` runs, so a probe that interacts first and then warps sees
   a frozen share price while one that only warps sees it move. Neither reading
   is an APR. Do not quote a rate off a fork.
3. **It is VaultV2, not MetaMorpho.** Adapters rather than supply/withdraw
   queues, which is why every MetaMorpho selector reverts. Exits beyond
   available liquidity go through `forceDeallocate`, whose penalty is currently
   1e13 (0.001%).
4. **No audit.** Nothing here has been reviewed by anyone.

## What the vault deliberately cannot do

There is no function that sends depositor assets to an arbitrary address. The
owner chooses only how much sits idle versus deployed. `test_OwnerCannotTakeDepositorFunds`
asserts this rather than trusting it.
