# GuideSection Specification

## Overview
- **Target file:** `src/components/GuideSection.tsx` (server component)
- **Interaction model:** static + card hover

## Exact markup (classes verbatim)
```html
<section id="guide" class="border-b border-wire-border px-8 py-20 scroll-mt-16">
  <div class="max-w-5xl mx-auto">
    <div class="font-mono text-xs text-wire-muted tracking-[0.4em] mb-2">// QUICK START</div>
    <div class="font-mono text-[10px] text-wire-border mb-10">╠══════════════════════════════════════════════════════════════╣</div>
    <div class="grid grid-cols-1 md:grid-cols-2 gap-px bg-wire-border">
      <!-- 4 step cards, each: -->
      <div class="bg-black p-8 hover:bg-wire-card transition-colors">
        <div class="flex items-baseline gap-3 mb-3">
          <span class="font-mono text-3xl text-wire-cyan glow-cyan">{num}</span>
          <span class="font-mono text-sm text-wire-cyan tracking-widest">{title}</span>
        </div>
        <div class="font-mono text-xs text-wire-muted leading-relaxed">{body}</div>
      </div>
    </div>
    <div class="mt-8 flex flex-col md:flex-row items-center justify-between gap-4">
      <div class="font-mono text-xs text-wire-muted">_ NEED MORE DETAIL? READ THE FULL DOCUMENTATION.</div>
      <a href="/docs" class="font-mono text-xs text-wire-cyan border border-wire-border px-5 py-2.5 hover:border-wire-cyan hover:glow-cyan transition-all tracking-widest">OPEN DOCS →</a>
    </div>
  </div>
</section>
```

## Step content (verbatim — note “ ” typographic quotes)
1. **01 / SIGN IN WITH X** — `Connect your X account. WIRE instantly generates a self-custodial wallet tied to your handle — no seed phrase, no setup.`
2. **02 / DEPOSIT** — `Fund your wallet from the dashboard. Send USDG for stocks & baskets, and a little ETH for gas (and for token/ETH trades).`
3. **03 / TWEET A COMMAND** — `Mention @wirebotRH anywhere in a post: “buy $50 NVDA”, “sell all TSLA”, “send @friend $25 AAPL”, or “buy $20 MAG7”.`
4. **04 / GET CONFIRMED** — `The bot replies with the result and a Blockscout link. Everything shows up in the live feed above in real time.`

## Responsive
- ≥768px: 2×2 grid; bottom row horizontal. <768px: stacked; bottom row column, centered.

## Verification
`npx tsc --noEmit` must pass.
