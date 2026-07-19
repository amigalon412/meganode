# Footer Specification

## Overview
- **Target file:** `src/components/Footer.tsx` (server component)
- **Interaction model:** static + link hover

## Exact markup (classes verbatim)
```html
<footer class="px-8 py-12">
  <div class="font-mono text-[10px] text-wire-border mb-6 text-center whitespace-pre overflow-x-auto">╔══════════════════════════════════════════════════════════════════╗
║  WIRE · THE COMMAND LAYER FOR FINANCE · wirebot.trade             ║
╚══════════════════════════════════════════════════════════════════╝</div>
  <div class="flex flex-col md:flex-row items-center justify-between gap-4">
    <div class="flex items-center gap-3">
      <img src="/images/logo.png" alt="WIRE" width="22" height="22" class="rounded opacity-50" />  <!-- next/image -->
      <span class="wire-title text-wire-cyan opacity-50 tracking-widest text-lg">WIRE</span>
    </div>
    <div class="flex items-center gap-6 font-mono text-xs text-wire-muted tracking-widest">
      <a href="#about" class="hover:text-wire-cyan transition-colors">ABOUT</a>
      <a href="#guide" class="hover:text-wire-cyan transition-colors">GUIDE</a>
      <a href="/docs" class="hover:text-wire-cyan transition-colors">DOCS</a>
      <a href="https://x.com/wirebotRH" target="_blank" rel="noopener noreferrer" class="hover:text-wire-cyan transition-colors">X</a>
    </div>
    <div class="font-mono text-[10px] text-wire-muted text-center max-w-xs">BUILT ON ROBINHOOD CHAIN · NOT FINANCIAL ADVICE · STOCK TOKENS NOT AVAILABLE TO US PERSONS</div>
  </div>
</footer>
```

## ASCII box (exact — must render as 3 lines via whitespace-pre; put it in a template literal)
- Top: `╔` + 66×`═` + `╗`
- Middle: `║  WIRE · THE COMMAND LAYER FOR FINANCE · wirebot.trade             ║` (2 leading spaces, 13 trailing spaces before `║`)
- Bottom: `╚` + 66×`═` + `╝`
The element uses `whitespace-pre` so the string must contain real newlines and exact spacing. In JSX, render `{BOX}` from a template literal to avoid JSX whitespace collapsing.

## Imports
- `Image` from `next/image` (`/images/logo.png`, 22×22).

## Responsive
- ≥768px: single row, space-between. <768px: stacked, centered, gap-4.

## Verification
`npx tsc --noEmit` must pass.
