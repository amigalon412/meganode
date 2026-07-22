# BLUR keeper

Calls `KeeperGuard.deployIdle(vault)` when a vault has enough idle balance to be
worth putting to work. That is the entire job.

It is deliberately dumb. Every limit that matters — who may call, which vaults,
how much per call, how often, and whether automation is halted at all — is
enforced on-chain by `KeeperGuard`, not here. A bug in this file, or a stolen
key, cannot exceed those limits. See `contracts/test/KeeperGuard.t.sol`.

## Run

```bash
cd keeper && npm install

export VAULT_ADDRESS=0x...
export GUARD_ADDRESS=0x...

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
| `RPC_URL` | official mainnet RPC | Chain endpoint |
| `DRY_RUN` | `true` | Set to `false` to send transactions |
| `KEEPER_PRIVATE_KEY` | — | Only read when `DRY_RUN=false` |
| `MIN_DEPLOY_UNITS` | `100000000` (100 USDG) | Do not act below this |
| `POLL_MS` | `60000` | How often to check |

## Behaviour

Before sending, it checks that the vault actually trusts the guard it was
pointed at, that the guard is not paused, that the cooldown has elapsed, and
that the amount clears the minimum. Then it simulates the call — the guard
reverts on every limit it enforces, and learning that locally is free.

At startup in live mode it verifies its own address is a registered keeper and
exits if not, rather than burning gas on calls that can only revert.

## Operating notes

The key is online, so treat it as compromised eventually. It should hold gas
and nothing else, and it should be rotated by calling `setKeeper` on the guard
rather than by moving funds. If something looks wrong, a sentinel can call
`pause()` on the guard to stop automation without needing the owner key.
