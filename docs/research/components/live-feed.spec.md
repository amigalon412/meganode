# LiveFeed Specification

## Overview
- **Target file:** `src/components/LiveFeed.tsx` (client component — `"use client"`)
- **Screenshot:** `docs/design-references/mobile-390-feed.jpg`
- **Interaction model:** time-driven (polls `/api/feed?limit=25` every 8s; 15s re-render tick for time labels)
- **Data:** `FeedItem`/`FeedStats`/`FeedResponse` types from `@/types/feed`. The API route `/api/feed` already exists (mock, built in foundation).

## Behavior (exact port of original logic)
```ts
// state: items: FeedItem[], stats: FeedStats {total, volumeUsd}, loaded: boolean,
//        highlightIds: Set<number>, seenIds: useRef(new Set<number>()), tick counter
useEffect(() => {
  let alive = true;
  const load = async () => {
    try {
      const res = await fetch("/api/feed?limit=25", { cache: "no-store" });
      if (!res.ok) return;
      const data = await res.json();
      if (!alive) return;
      const fresh = new Set<number>();
      for (const item of data.items) if (!seen.current.has(item.id)) { fresh.add(item.id); seen.current.add(item.id); }
      if (seen.current.size > fresh.size && fresh.size) {   // skip highlight on first load
        setHighlight(fresh);
        setTimeout(() => alive && setHighlight(new Set()), 2000);
      }
      setItems(data.items); setStats(data.stats); setLoaded(true);
    } catch {}
  };
  load();
  const poll = setInterval(load, 8000);
  const ticker = setInterval(() => alive && setTick(t => t + 1), 15000);
  return () => { alive = false; clearInterval(poll); clearInterval(ticker); };
}, []);
```

timeAgo: `const t = Math.max(0, Math.floor(Date.now()/1000 - ts));` → `<60: "${t}s"`, `<3600: "${floor(t/60)}m"`, `<86400: "${floor(t/3600)}h"`, else `"${floor(t/86400)}d"`.

Action map:
```ts
const ACTIONS: Record<string, {label: string; cls: string; arrow: string}> = {
  buy:  { label: "BUY",  cls: "text-wire-green glow-green",   arrow: "▲" },
  sell: { label: "SELL", cls: "text-wire-purple glow-purple", arrow: "▼" },
  send: { label: "SEND", cls: "text-wire-cyan glow-cyan",     arrow: "→" },
  drop: { label: "DROP", cls: "text-wire-green glow-green",   arrow: "🎁" },
};
// fallback: { label: action.toUpperCase(), cls: "text-wire-cyan", arrow: "•" }
```

## Exact markup
```html
<section id="feed" class="border-b border-wire-border">
  <!-- terminal title bar -->
  <div class="flex items-center justify-between px-6 py-2 bg-wire-card border-b border-wire-border">
    <div class="flex items-center gap-2 min-w-0">
      <span class="w-2.5 h-2.5 bg-red-500 rounded-full shrink-0"></span>
      <span class="w-2.5 h-2.5 bg-yellow-500 rounded-full shrink-0"></span>
      <span class="w-2.5 h-2.5 bg-wire-green rounded-full shrink-0"></span>
      <span class="text-wire-muted text-xs font-mono ml-3 tracking-widest truncate">root@wirebot:~$ tail -f /var/log/wire/transactions</span>
    </div>
    <div class="flex items-center gap-5 shrink-0">
      <span class="hidden md:inline text-wire-muted text-xs font-mono tracking-widest">{stats.total.toLocaleString()} TX · ${Math.round(stats.volumeUsd).toLocaleString()} VOL</span>
      <span class="text-wire-cyan text-xs font-mono flex items-center gap-1.5"><span class="w-1.5 h-1.5 rounded-full bg-wire-cyan animate-blink"></span> LIVE</span>
    </div>
  </div>
  <!-- body -->
  <div class="bg-wire-card">
    <div class="px-6 py-4 font-mono text-xs md:text-sm max-h-[440px] overflow-y-auto">
      <!-- if !loaded || items empty: -->
      <div class="text-wire-muted py-8 text-center"><span class="cursor">CONNECTING TO LEDGER</span></div>
      <!-- else: <div class="space-y-1.5"> rows </div> -->
    </div>
  </div>
</section>
```

Row (key={item.id}; trailing space in class string when not highlighted matches original but is irrelevant — use conditional `bg-wire-dim/60`):
```html
<div class="flex items-center gap-3 py-1.5 border-b border-wire-border/40 last:border-0 transition-colors {highlight.has(id) ? 'bg-wire-dim/60' : ''}">
  <span class="text-wire-border shrink-0 w-9 text-right tabular-nums">{timeAgo(item.ts)}</span>
  <span class="shrink-0 w-[70px] {action.cls}">{action.arrow} {action.label}</span>
  <span class="flex-1 min-w-0 truncate">
    <a href="https://x.com/{item.actor}" target="_blank" rel="noopener noreferrer" class="text-wire-cyan hover:glow-cyan hover:underline">@{item.actor}</a>
    <span class="text-wire-muted"> {item.verb} </span>
    <span class="text-wire-cyan">{item.amountLabel} </span>
    <span class="text-wire-cyan glow-cyan">${item.ticker}</span>
    <!-- if counterparty: -->
    <span class="text-wire-muted"> → </span>
    <a href="https://x.com/{item.counterparty}" ... class="text-wire-cyan hover:glow-cyan hover:underline">@{item.counterparty}</a>
  </span>
  <div class="flex items-center gap-3 shrink-0">
    <!-- if tweetUrl: -->
    <a href={item.tweetUrl} target="_blank" rel="noopener noreferrer" class="text-wire-border hover:text-wire-cyan hidden sm:inline" title="View tweet on X"><XIcon width={12} height={12} className="inline-block align-middle" /></a>
    <a href={item.txUrl} target="_blank" rel="noopener noreferrer" class="text-wire-border hover:text-wire-cyan tracking-wider hidden sm:inline" title="View on Blockscout">{item.txShort} ↗</a>
  </div>
</div>
```
Note: ticker rendered as `$` + ticker (e.g. `$NVDA`), amountLabel keeps trailing space (`$50 `). Actor/counterparty links contain `@` prefix. The feed X icon is 12×12 (nav's is 15×15).

## Imports
- `XIcon` from `@/components/icons`; types from `@/types/feed`.

## Responsive
- Stats counter hidden <768px; tweet/tx links hidden <640px; text xs → sm at md.

## Verification
`npx tsc --noEmit` must pass.
