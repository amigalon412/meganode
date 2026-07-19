# SecuritySection Specification

## Overview
- **Target file:** `src/components/SecuritySection.tsx` (server component)
- **Interaction model:** static + card hover

## Exact markup (classes verbatim)
```html
<section class="border-b border-wire-border px-8 py-20">
  <div class="max-w-5xl mx-auto">
    <div class="font-mono text-xs text-wire-muted tracking-[0.4em] mb-2">// SECURITY MODEL</div>
    <div class="font-mono text-[10px] text-wire-border mb-8">╠══════════════════════════════════════════════════════════════╣</div>
    <div class="grid grid-cols-1 md:grid-cols-3 gap-px bg-wire-border">
      <!-- 3 cards, each: -->
      <div class="bg-black p-6 hover:bg-wire-card transition-colors">
        <div class="font-mono text-xs text-wire-border mb-1">┌─────────┐</div>
        <div class="font-mono text-xs text-wire-cyan mb-1">│ {tag} {num} │</div>
        <div class="font-mono text-xs text-wire-border mb-4">└─────────┘</div>
        <div class="font-mono text-sm text-wire-cyan glow-cyan mb-3">{title}</div>
        <div class="font-mono text-xs text-wire-muted leading-relaxed">{body}</div>
      </div>
    </div>
  </div>
</section>
```

## Card content (verbatim)
1. `│ [KEY] 01 │` / **YOUR KEYS, ALWAYS** — `Export your raw private key from the dashboard. No permission needed. Walk away to any wallet at any time.`
2. `│ [BOT] 02 │` / **BOT NEVER HOLDS KEYS** — `The language model only parses intent into JSON. All execution is deterministic code with per-tx spending limits.`
3. `│ [SND] 03 │` / **PRE-GENERATED WALLETS** — `Send to @anyone — even if they've never heard of us. They log in with X and the funds are already there.`

ASCII box: `┌─────────┐` = 9 `─` chars; middle line has single spaces: `│ [KEY] 01 │`.

## Responsive
- ≥768px: 3 columns. <768px: single column.

## Verification
`npx tsc --noEmit` must pass.
