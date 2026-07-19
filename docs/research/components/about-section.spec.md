# AboutSection Specification

## Overview
- **Target file:** `src/components/AboutSection.tsx` (server component)
- **Screenshot:** `docs/design-references/mobile-390-about.jpg` (mobile), desktop layout = 3-col grid
- **Interaction model:** static + card hover

## Exact markup (classes verbatim)
```html
<section id="about" class="border-b border-wire-border px-8 py-20 scroll-mt-16">
  <div class="max-w-5xl mx-auto">
    <div class="font-mono text-xs text-wire-muted tracking-[0.4em] mb-2">// WHAT IS WIRE</div>
    <div class="font-mono text-[10px] text-wire-border mb-10">╠══════════════════════════════════════════════════════════════╣</div>
    <h2 class="font-mono text-2xl md:text-3xl text-wire-cyan glow-cyan mb-6 leading-snug">Trade the market from your timeline.</h2>
    <p class="font-mono text-sm text-wire-muted leading-relaxed max-w-3xl mb-10">WIRE is a non-custodial trading bot that lives on X. Mention <span class="text-wire-cyan">@wirebotRH</span> in plain language and it executes real on-chain trades on Robinhood Chain — tokenized stocks &amp; ETFs, index baskets, native ETH and community tokens. A language model only reads your intent; every transaction is signed by deterministic code inside your own wallet, with hard spending limits. You can export your private key any time and walk away.</p>
    <div class="grid grid-cols-1 md:grid-cols-3 gap-px bg-wire-border">
      <!-- 6 cards, each: -->
      <div class="bg-black p-6 hover:bg-wire-card transition-colors">
        <div class="font-mono text-sm text-wire-cyan glow-cyan mb-2">{title}</div>
        <div class="font-mono text-xs text-wire-muted leading-relaxed">{body}</div>
      </div>
    </div>
  </div>
</section>
```

## Card content (verbatim, in order — note typographic … and “ ” quotes)
1. **STOCKS & ETFS** — `50+ tokenized equities (NVDA, TSLA, SPY…) settled in USDG via Uniswap v4 pools.`
2. **INDEX BASKETS** — `One-tap diversified exposure — MAG7, AI6 and more, minted through the Vimen protocol.`
3. **TOKENS & ETH** — `Native ETH and community tokens (like $WIRE) routed through WETH liquidity.`
4. **SEND BY @HANDLE** — `Transfer assets to any X user — even before they sign up. Funds wait in their wallet.`
5. **AIRDROPS** — `Reward your replies: “drop $5 of NVDA to first 10 replies”. One claim per person.`
6. **YOUR KEYS** — `MPC-backed wallet, exportable private key, non-custodial by design.`

## Notes
- The 1px lines between cards are produced by `gap-px bg-wire-border` on the grid + `bg-black` cells — do not use real borders.
- Divider line is exactly 62 `═` chars between `╠` and `╣`.

## Responsive
- ≥768px: 3 columns × 2 rows. <768px: single column stack.

## Verification
`npx tsc --noEmit` must pass.
