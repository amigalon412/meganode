# Stock tokens on Robinhood Chain

Everything below was read from mainnet (chain id 4663) via
`rpc.mainnet.chain.robinhood.com` and the Blockscout API, not from marketing
pages. Re-verify before relying on it; this is a three-week-old chain.

## The tokens exist and are used

| Symbol | Name | Holders | Address |
|---|---|---|---|
| NVDA | NVIDIA • Robinhood Token | 23,699 | `0xd0601CE157Db5bdC3162BbaC2a2C8aF5320D9EEC` |
| AAPL | Apple • Robinhood Token | 22,679 | `0xaF3D76f1834A1d425780943C99Ea8A608f8a93f9` |
| SPCX | Space Exploration Technologies | 18,905 | `0x4a0E65A3EcceC6dBe60AE065F2e7bb85Fae35eEa` |
| TSLA | Tesla • Robinhood Token | 17,128 | `0x322F0929c4625eD5bAd873c95208D54E1c003b2d` |
| AMZN | Amazon • Robinhood Token | 15,258 | `0x12f190a9F9d7D37a250758b26824B97CE941bF54` |
| AMD | AMD • Robinhood Token | 15,028 | `0x86923f96303D656E4aa86D9d42D1e57ad2023fdC` |
| SNDK | Sandisk Corporation | 8,123 | `0xB90A19fF0Af67f7779afF50A882A9CfF42446400` |

All 18 decimals. NVDA supply is 14,205 tokens.

**No SPY.** The site copy names it as a basket constituent; it is not in the
top fifty tokens on this chain. Either drop it or verify it exists elsewhere.

## Contract shape

Each is a `BeaconProxy` over a shared `Stock` implementation
(`0xb35490d6f9163DE4F80d88dc75c3516eb64C5aE2`), so all of them behave
identically and upgrade together.

### Transfers are not gated by KYC

The token consults `ACCESS_CONTROLLED_REGISTRY`
(`0xe10b6f6B275de231345c20D14Ab812db62151b00`), which exposes `isBlocked`,
`blockAccounts` and `unblockAccounts` — and no `isAllowed`. It is a **blocklist,
not an allowlist**: `isBlocked` returns false for an arbitrary address.

That answers the question that would have killed the second leg outright. A
vault contract can hold these tokens without being whitelisted.

### Powers the issuer keeps

| Function | What it means for us |
|---|---|
| `blockAccounts` | Our vault can be blocked specifically, freezing its basket |
| `pause` / `tokenPaused` | Global transfer freeze; in-kind redemption stops working |
| `adminBurn` | Tokens can be burned out of any holder, including us |
| `mint` | Supply is issuer-controlled |

This is the concrete form of the issuer risk the docs mention. It is not
theoretical and it is not small: **for the basket leg, "nobody can move your
funds" is false.** Nobody can move the *shares*, but the assets behind them can
be frozen or burned by the issuer. The site copy has to say so.

### Stock splits use a multiplier, and this is a trap

`uiMultiplier` (currently `1e18`), `updateMultiplier`, `effectiveAt`,
`balanceOfUI`, `totalSupplyUI`, `TransferWithScaledUI`.

Raw `balanceOf` is **not** the economic quantity. After a split the multiplier
changes and `balanceOfUI` moves while `balanceOf` does not. Any NAV computed
from raw `balanceOf` against a per-share price silently doubles or halves on the
next split.

Whatever price source we use, the units it quotes and the balance we multiply it
by must be established explicitly, with a test that simulates a multiplier
change. This is the single easiest way to get the second leg badly wrong.

## Liquidity

The largest NVDA holder is Uniswap v4's `PoolManager`
(`0x8366a39CC670B4001A1121B8F6A443A643e40951`) with 6,619 NVDA — 47% of supply,
roughly $1.2M on one side. Real liquidity exists, and the venue is Uniswap v4,
so trading goes through the singleton with hook-aware routing rather than a
per-pair pool.

## Price feeds: Chainlink, and they exist

Chainlink is deployed here. The Morpho oracles are `MorphoChainlinkOracleV2`
wrapping standard `EACAggregatorProxy` feeds, and there are around fifty of
them on the chain — including the equities.

All are 8 decimals and expose the usual `latestRoundData()`.

| Feed | Address | Price when read |
|---|---|---|
| RHNVDA / USD | `0x379EC4f7C378F34a1B47E4F3cbeBCbAC3E8E9F15` | $206.27 |
| Robinhood AAPL / USD | `0x6B22A786bAa607d76728168703a39Ea9C99f2cD0` | $324.19 |
| RHTSLA / USD | `0x4A1166a659A55625345e9515b32adECea5547C38` | $380.13 |
| RHSPY / USD | `0x319724394D3A0e3669269846abE664Cd621f9f6A` | $747.06 |

Also present: AMZN, GOOGL, META, MSFT, QQQ, PLTR, ORCL, SPCX, COIN, RKLB, BABA,
INTC, AMD, SNDK, MU, DELL, CRCL, CRWV, SLV, USO, SGOV, plus LINK/USD and
USDT/USD.

**An SPY feed exists even though no SPY token was found.** A feed is not a
tradable asset; do not infer the basket from the feed list.

Most feeds appear at two addresses with identical values. Establish which is
canonical before hardcoding one.

### Staleness is the real constraint

Read at 00:35 UTC, with US markets closed:

| Feed | Age |
|---|---|
| LINK / USD | 15 min |
| AAPL, TSLA | 29 min |
| RHNVDA | 1 h 51 min |
| USDT / USD | 4 h 53 min |
| RHSPY | 10 h 7 min |

Two consequences for the design:

1. **One global staleness threshold will not work.** A limit tight enough for
   AAPL rejects SPY permanently. Thresholds have to be per feed, set from each
   feed's observed heartbeat rather than guessed.

2. **Overnight, every equity price is stale by construction.** That is correct
   behaviour, not a fault — the underlying market is shut. It means NAV outside
   session hours is marked at the last print, and rebalancing must refuse to
   run rather than trade against a price nobody is maintaining. This is the
   concrete mechanism behind what `docs/market-hours` already promises.

The pool price still must not be used for NAV: it is the pool we would trade
against, so anyone willing to move it for one block can move our accounting.
Chainlink for valuation, the pool only for execution.
