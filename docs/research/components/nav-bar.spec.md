# NavBar Specification

## Overview
- **Target file:** `src/components/NavBar.tsx` (server component is fine — no state)
- **Screenshot:** `docs/design-references/desktop-1440-hero.jpg` (top bar)
- **Interaction model:** static (sticky positioning + CSS hover states only; appearance does NOT change on scroll)

## Exact markup (from live site SSR — reproduce classes verbatim)
```html
<nav class="grid grid-cols-2 lg:grid-cols-3 items-center px-6 py-3 border-b border-wire-border sticky top-0 z-50 bg-black/85 backdrop-blur">
  <div class="flex items-center gap-3">
    <img src="/images/logo.png" alt="WIRE" width="32" height="32" class="rounded opacity-90" />  <!-- use next/image -->
    <span class="wire-title text-2xl text-wire-cyan glow-cyan tracking-widest">WIRE</span>
  </div>
  <div class="hidden lg:flex items-center justify-center gap-8 font-mono text-xs tracking-widest text-wire-cyan/80">
    <a href="#about" class="hover:text-wire-cyan hover:glow-cyan transition-all">ABOUT</a>
    <a href="#guide" class="hover:text-wire-cyan hover:glow-cyan transition-all">GUIDE</a>
    <a href="#feed" class="hover:text-wire-cyan hover:glow-cyan transition-all">LIVE</a>
    <a href="/docs" class="hover:text-wire-cyan hover:glow-cyan transition-all">DOCS</a>
  </div>
  <div class="flex items-center justify-end gap-2 sm:gap-3">
    <a href="https://x.com/wirebotRH" target="_blank" rel="noopener noreferrer" title="@wirebotRH on X"
       class="flex items-center justify-center border border-wire-cyan text-wire-cyan glow-box-cyan p-2 hover:bg-wire-cyan hover:text-black transition-all">
      <XIcon width={15} height={15} className="glow-svg-cyan" />
    </a>
    <a href="https://app.uniswap.org/swap?chain=robinhood&inputCurrency=NATIVE&outputCurrency=0x8ecea3d0e648db646d824aa51eedeb16ac3d6878"
       target="_blank" rel="noopener noreferrer"
       class="flex items-center gap-2 border border-wire-cyan text-wire-cyan glow-cyan font-mono text-xs px-4 py-2 hover:bg-wire-cyan hover:text-black transition-all tracking-widest whitespace-nowrap">BUY $WIRE</a>
    <button class="flex items-center gap-2 border border-wire-cyan text-wire-cyan font-mono text-xs px-4 py-2 hover:bg-wire-cyan hover:text-black transition-all disabled:opacity-30 tracking-widest whitespace-nowrap">CONNECT <XIcon width={15} height={15} /></button>
  </div>
</nav>
```
Note: original renders CONNECT button enabled after session check (do NOT set `disabled` in the clone; it should render at full opacity and be a no-op).

## Imports
- `XIcon` from `@/components/icons`
- `Image` from `next/image` for the logo (`/images/logo.png`, width 32 height 32; original rendered a 32×28 box)

## States & Behaviors
- Sticky: stays pinned at top over all content (z-50), translucent `bg-black/85` + `backdrop-blur`.
- Hover: see classes above; no other states.

## Responsive
- Desktop ≥1024: 3-column grid (logo | links | actions), center links visible.
- <1024: 2-column grid, center links hidden. Same paddings.

## Verification
`npx tsc --noEmit` must pass.
