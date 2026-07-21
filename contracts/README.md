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

## Known blockers before this can hold real money

1. **The lending venue is not exitable.** `steakUSDG`
   (`0xBeEff033F34C046626B8D0A041844C5d1A5409dd`) reports
   `maxWithdraw == 0` and `maxDeposit == 0` while still accepting deposits.
   Anything sent there currently cannot be pulled back. `deployIdle` must not
   be pointed at it on mainnet until that changes.
2. **Its accrual is not characterised.** One probe saw the share price frozen
   across 90 simulated days; another saw it move at roughly 2.4% annualised.
   Until the difference is understood, no APR should be quoted anywhere.
3. **It is not MetaMorpho.** `MORPHO()`, `timelock()`, `supplyQueueLength()` and
   `fee()` all revert; only `owner()` and `curator()` answer. Whatever it is, it
   is not the contract shape its name implies, and it has not been read.
4. **No audit.** Nothing here has been reviewed by anyone.

## What the vault deliberately cannot do

There is no function that sends depositor assets to an arbitrary address. The
owner chooses only how much sits idle versus deployed. `test_OwnerCannotTakeDepositorFunds`
asserts this rather than trusting it.
