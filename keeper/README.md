# BLUR keeper

Drives the four automated actions the guard exposes: rebalancing a vault back
toward its split, allocating idle balance to the lending venue, turning accrued
fee shares into stable, and spending that stable on the protocol token.

It is deliberately dumb. Every limit that matters — who may call, which vaults
and modules, how much per call, how often, and whether automation is halted at
all — is enforced on-chain by `KeeperGuard`, not here. A bug in this file, or a
stolen key, cannot exceed those limits. See `contracts/test/KeeperGuard.t.sol`.

## Run

```bash
cd keeper && npm install

export VAULT_ADDRESS=0x...
export GUARD_ADDRESS=0x...
export BUYBACK_ADDRESS=0x...   # optional; without it, only the vault half runs

# Dry run: reads chain state, decides, prints, sends nothing.
npm run once

# Live. Needs a key that is registered as a keeper on the guard.
export KEEPER_PRIVATE_KEY=0x...
export DRY_RUN=false
npm start
```

`DRY_RUN` defaults to on, and the private key is only read when it is off, so
the bot can be inspected and left running without a key present.

| Variable | Default | Meaning |
|---|---|---|
| `VAULT_ADDRESS` | required | Vault to drive |
| `GUARD_ADDRESS` | required | Guard that fronts it |
| `BUYBACK_ADDRESS` | — | Buyback module; omit to skip fee and buyback actions |
| `RPC_URL` | official mainnet RPC | Chain endpoint |
| `DRY_RUN` | `true` | Set to `false` to send transactions |
| `KEEPER_PRIVATE_KEY` | — | Only read when `DRY_RUN=false` |
| `MIN_DEPLOY_UNITS` | `100000000` (100 USDG) | Do not allocate below this |
| `MIN_FEE_UNITS` | `10000000` (10 USDG) | Do not collect fees below this |
| `MIN_BUYBACK_UNITS` | `50000000` (50 USDG) | Do not buy back below this |
| `BUYBACK_SLIPPAGE_BPS` | `100` (1%) | How far below the quote a buyback may fill |
| `POLL_MS` | `60000` | How often to check |

## What it decides

**Rebalance before allocate.** Both actions share one cooldown slot on the
guard, so only one can run per period. Rebalancing wins: it is about the vault
holding what it says it holds, while allocating idle cash is an optimisation
that keeps just as well until the next tick.

**Which constituent to trade.** The vault decides direction and size from the
live gap; the keeper only names a token. It names the one furthest from its own
target weight in the direction the trade is going — buy what is most
under-weight, sell what is most over. Naming the wrong one is not unsafe, only
wasteful.

**Nothing at all, when the vault cannot price its basket.** A stale feed or an
unacknowledged stock split makes the vault refuse to value itself. Every vault
action accrues the fee first, so all of them would revert; the keeper says so
and waits rather than retrying into a halt that exists for a reason.

**The buyback floor.** The protocol token has no price feed, so `minAmountOut`
cannot be checked against an oracle. It is derived by simulating the swap to see
what the pool would return right now, then demanding all but
`BUYBACK_SLIPPAGE_BPS` of that. The bound is therefore against a quote seconds
old rather than a price anyone attested to, which is why the guard's size cap
matters more for this action than for any other.

Cooldowns are compared against the latest block's timestamp, not this host's
clock. A skewed clock would otherwise either idle the keeper or send a call the
guard reverts, and neither failure announces itself.

Before sending anything it simulates the call — the guard reverts on every limit
it enforces, and learning that locally is free. At startup in live mode it
verifies its own address is a registered keeper and that the guard knows the
vault, exiting if not rather than burning gas on calls that can only revert.

## Operating notes

The key is online, so treat it as compromised eventually. It should hold gas and
nothing else, and it should be rotated by calling `setKeeper` on the guard
rather than by moving funds. If something looks wrong, a sentinel can call
`pause()` on the guard to stop automation without needing the owner key.
