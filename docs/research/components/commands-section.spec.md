# CommandsSection Specification

## Overview
- **Target file:** `src/components/CommandsSection.tsx` (server component)
- **Interaction model:** static + card hover (group-hover glow on command text)

## Exact markup (classes verbatim)
```html
<section class="border-b border-wire-border px-8 py-20">
  <div class="max-w-5xl mx-auto">
    <div class="font-mono text-xs text-wire-muted tracking-[0.4em] mb-2">// SUPPORTED COMMANDS</div>
    <div class="font-mono text-[10px] text-wire-border mb-8">╠══════════════════════════════════════════════════════════════╣</div>
    <div class="grid grid-cols-1 md:grid-cols-2 gap-px bg-wire-border">
      <!-- 6 cards, each: -->
      <div class="bg-black p-6 hover:bg-wire-card transition-colors group">
        <div class="font-mono text-xs text-wire-dim mb-1">┌─</div>
        <div class="font-mono text-sm text-wire-cyan group-hover:glow-cyan transition-all mb-2">{command}</div>
        <div class="font-mono text-xs text-wire-muted">{description}</div>
        <div class="font-mono text-xs text-wire-dim mt-2">└─</div>
      </div>
    </div>
  </div>
</section>
```
Note: divider uses `mb-8` here (about/guide use `mb-10`).

## Card content (verbatim, in order)
1. `@wirebotRH buy $50 NVDA` — `Buy any tokenized stock or ETF with your USDG balance`
2. `@wirebotRH sell all TSLA` — `Liquidate a full position — or a fixed dollar amount`
3. `@wirebotRH buy $20 MAG7` — `Buy an index basket in one tap (MAG7, AI6…)`
4. `@wirebotRH send @handle $25 AAPL` — `Send any asset to an X handle — even non-users`
5. `@wirebotRH buy $10 WIRE` — `Trade community tokens & native ETH via WETH pools`
6. `@wirebotRH drop $5 NVDA to first 10` — `Airdrop to the first N unique repliers — 1 per person`

## Responsive
- ≥768px: 2 columns × 3 rows. <768px: single column.

## Verification
`npx tsc --noEmit` must pass.
