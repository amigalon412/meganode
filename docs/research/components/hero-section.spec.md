# HeroSection + TickerMarquee Specification

## Overview
- **Target files:** `src/components/HeroSection.tsx` (client component — has boot-sequence state) and `src/components/TickerMarquee.tsx` (server component)
- **Screenshot:** `docs/design-references/desktop-1440-hero.jpg`, mobile: `docs/design-references/mobile-390-hero.jpg`
- **Interaction model:** time-driven (staggered boot lines via setTimeout; CSS flicker/glitch/marquee animations)

## HeroSection exact markup (classes verbatim from live site)
```html
<section class="min-h-[78vh] flex flex-col items-center justify-center px-8 py-16 border-b border-wire-border text-center">
  <div class="font-mono text-[10px] text-wire-muted mb-8 tracking-widest hidden md:block">
    <div>┌──────────────────────────────┐</div>
    <div>│  ROBINHOOD CHAIN · ID: 4663  │</div>
    <div>│  STATUS: ████████████  LIVE  │</div>
    <div>└──────────────────────────────┘</div>
  </div>
  <pre class="font-mono text-[10px] md:text-[14px] lg:text-[18px] leading-tight text-wire-cyan glow-cyan glitch mb-8 animate-flicker whitespace-pre" data-text={ASCII}>{ASCII}</pre>
  <div class="font-mono text-base md:text-lg text-wire-muted mb-4 tracking-[0.25em] flex items-center gap-2 justify-center">
    <span class="text-wire-cyan">▶</span>THE COMMAND LAYER FOR FINANCE</div>
  <p class="font-mono text-xs md:text-sm text-wire-muted max-w-xl mb-10 leading-relaxed">Buy, sell, send and airdrop tokenized stocks, ETFs, index baskets and tokens on Robinhood Chain — by posting a tweet. No app. No seed phrase. Your keys, always.</p>
  <div class="mb-10 space-y-1 text-left inline-block">
    <!-- 4 boot lines, see behavior -->
  </div>
  <div class="space-y-3 flex flex-col items-center">
    <button class="flex items-center gap-3 bg-wire-cyan text-black font-mono font-bold text-base px-10 py-4 hover:opacity-90 hover:shadow-[0_0_40px_rgba(0,255,255,0.35)] transition-all disabled:opacity-30 tracking-widest">SIGN IN WITH <XIcon width={15} height={15} /> →</button>
    <div class="font-mono text-xs text-wire-muted">_ SELF-CUSTODIAL WALLET · GENERATED IN ONE TAP · NO SEED PHRASE</div>
  </div>
</section>
```

ASCII constant (exact — box-drawing block art; keep as template literal, `.trim()`ed, 6 lines):
```
██╗    ██╗██╗██████╗ ███████╗
██║    ██║██║██╔══██╗██╔════╝
██║ █╗ ██║██║██████╔╝█████╗  
██║███╗██║██║██╔══██╗██╔══╝  
╚███╔███╔╝██║██║  ██║███████╗
 ╚══╝╚══╝ ╚═╝╚═╝  ╚═╝╚══════╝
```
(lines 3 and 4 end with two trailing spaces — preserve exactly; same string goes in the `data-text` attribute for the glitch pseudo-elements)

## Boot sequence behavior (exact from original JS)
```ts
const BOOT = [
  { delay: 0,    text: "> SYSTEM BOOT  .............. [OK]" },
  { delay: 700,  text: "> CHAIN LINK   .............. [OK]" },
  { delay: 1400, text: "> WALLET LAYER .............. [OK]" },
  { delay: 2100, text: "> LISTENING ON @wirebotRH ....... [ACTIVE]" },
];
```
- `useState<number[]>([])`; on mount `BOOT.forEach((e,t)=>setTimeout(()=>setShown(s=>[...s,t]), e.delay))`.
- Line render: `<div className={"font-mono text-sm transition-all duration-200 " + (shown.includes(i) ? "opacity-100" : "opacity-0") + " " + (i === BOOT.length-1 ? "text-wire-cyan" : "text-wire-muted")}>{text}</div>`
- After all 4 shown: append `<div className="text-wire-cyan font-mono text-sm cursor" />` (`.cursor::after` = blinking █, already in globals.css).
- SIGN IN button: render enabled, no-op onClick (original triggers Twitter OAuth — out of scope).

## TickerMarquee exact markup
```html
<div class="border-b border-wire-border bg-wire-card overflow-hidden py-2">
  <div class="flex animate-marquee whitespace-nowrap">
    <!-- PHRASES array rendered TWICE (16 spans total) for seamless -50% loop -->
    <span class="font-mono text-xs tracking-[0.3em] text-wire-muted mx-10">TRADE ANYTHING <span class="text-wire-cyan">◆</span></span>
    ...
  </div>
</div>
```
PHRASES (exact order): `["TRADE ANYTHING","TRANSFER ANYWHERE","EXECUTE INSTANTLY","POWERED ONCHAIN","NO APP REQUIRED","YOUR KEYS YOUR FUNDS","ROBINHOOD CHAIN","NON-CUSTODIAL"]`
Animation: `.animate-marquee` → `marquee 25s linear infinite` (already in globals.css). Note the space between phrase text and the ◆ span.

## Imports
- `XIcon` from `@/components/icons`
- `"use client"` on HeroSection only.

## v4 cascade fix
The original (Tailwind v3) computes the hero paragraph line-height as 20px at ≥768px because `md:text-sm`'s bundled line-height beats `leading-relaxed` in v3's cascade; in Tailwind v4 `leading-relaxed` always wins via `--tw-leading`. The clone adds `md:leading-5` to the paragraph to match the original computed values (19.5px at mobile, 20px at md+).

## Responsive
- ASCII status box hidden <768px. ASCII logo 10px/14px/18px at base/md/lg. Tagline base/lg text. Paragraph xs/sm.

## Verification
`npx tsc --noEmit` must pass.
