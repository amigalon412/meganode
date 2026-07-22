"use client";

import { useEffect, useRef, useState } from "react";
import type { FeedItem, FeedKind, FeedResponse, FeedStats } from "@/types/feed";

interface KindMeta {
  label: string;
  cls: string;
  arrow: string;
}

const KIND_MAP: Record<FeedKind, KindMeta> = {
  price: { label: "PRICE", cls: "text-wire-cyan glow-cyan", arrow: "◆" },
  yield: { label: "YIELD", cls: "text-wire-green glow-green", arrow: "⟳" },
  vault: { label: "VAULT", cls: "text-wire-purple glow-purple", arrow: "▲" },
};

function timeAgo(ts: number): string {
  const t = Math.max(0, Math.floor(Date.now() / 1000 - ts));
  if (t < 60) return `${t}s`;
  if (t < 3600) return `${Math.floor(t / 60)}m`;
  if (t < 86400) return `${Math.floor(t / 3600)}h`;
  return `${Math.floor(t / 86400)}d`;
}

const EMPTY_STATS: FeedStats = {
  blockNumber: 0,
  tvlUsd: null,
  vaultsDeployed: 0,
};

export function LiveFeed() {
  const [items, setItems] = useState<FeedItem[]>([]);
  const [stats, setStats] = useState<FeedStats>(EMPTY_STATS);
  const [loaded, setLoaded] = useState(false);
  const [highlight, setHighlight] = useState<Set<string>>(new Set());
  const [, setTick] = useState(0);
  const seen = useRef(new Set<string>());

  useEffect(() => {
    let alive = true;
    const load = async () => {
      try {
        const res = await fetch("/api/feed", { cache: "no-store" });
        if (!res.ok) return;
        const data: FeedResponse = await res.json();
        if (!alive) return;
        const fresh = new Set<string>();
        for (const item of data.items) {
          if (!seen.current.has(item.id)) {
            fresh.add(item.id);
            seen.current.add(item.id);
          }
        }
        if (seen.current.size > fresh.size && fresh.size) {
          setHighlight(fresh);
          setTimeout(() => {
            if (alive) setHighlight(new Set());
          }, 2000);
        }
        setItems(data.items);
        setStats(data.stats);
        setLoaded(true);
      } catch {}
    };
    load();
    // The route caches for 12s, so polling faster only burns requests.
    const poll = setInterval(load, 15000);
    const ticker = setInterval(() => {
      if (alive) setTick((t) => t + 1);
    }, 15000);
    return () => {
      alive = false;
      clearInterval(poll);
      clearInterval(ticker);
    };
  }, []);

  return (
    <section id="feed" className="border-b border-wire-border">
      <div className="flex items-center justify-between px-6 py-2 bg-wire-card border-b border-wire-border">
        <div className="flex items-center gap-2 min-w-0">
          <span className="w-2.5 h-2.5 bg-red-500 rounded-full shrink-0"></span>
          <span className="w-2.5 h-2.5 bg-yellow-500 rounded-full shrink-0"></span>
          <span className="w-2.5 h-2.5 bg-wire-green rounded-full shrink-0"></span>
          <span className="text-wire-muted text-xs font-mono ml-3 tracking-widest truncate">
            root@blurvault:~$ tail -f /var/log/blur/chain
          </span>
        </div>
        <div className="flex items-center gap-5 shrink-0">
          <span className="hidden md:inline text-wire-muted text-xs font-mono tracking-widest">
            {stats.blockNumber > 0
              ? `BLOCK ${stats.blockNumber.toLocaleString()}`
              : "CONNECTING"}
            {stats.tvlUsd === null
              ? " · NO VAULTS DEPLOYED"
              : ` · $${Math.round(stats.tvlUsd).toLocaleString()} TVL`}
          </span>
          <span className="text-wire-cyan text-xs font-mono flex items-center gap-1.5">
            <span className="w-1.5 h-1.5 rounded-full bg-wire-cyan animate-blink"></span>{" "}
            LIVE
          </span>
        </div>
      </div>
      <div className="bg-wire-card">
        <div className="px-6 py-4 font-mono text-xs md:text-sm max-h-[440px] overflow-y-auto">
          {!loaded ? (
            <div className="text-wire-muted py-8 text-center">
              <span className="cursor">READING ROBINHOOD CHAIN</span>
            </div>
          ) : items.length === 0 ? (
            <div className="text-wire-muted py-10 text-center space-y-2">
              <div className="text-wire-cyan">{"// CHAIN UNREACHABLE"}</div>
              <div className="text-[11px]">
                Nothing is shown here that was not just read from the chain, so
                nothing is shown.
              </div>
            </div>
          ) : (
            <div className="space-y-1.5">
              {items.map((item) => {
                const kind = KIND_MAP[item.kind];
                return (
                  <div
                    key={item.id}
                    className={`flex items-center gap-3 py-1.5 border-b border-wire-border/40 last:border-0 transition-colors${
                      highlight.has(item.id) ? " bg-wire-dim/60" : ""
                    }`}
                  >
                    <span className="text-wire-border shrink-0 w-9 text-right tabular-nums">
                      {timeAgo(item.ts)}
                    </span>
                    <span className={`shrink-0 w-[76px] ${kind.cls}`}>
                      {kind.arrow} {kind.label}
                    </span>
                    <span className="flex-1 min-w-0 truncate">
                      <span className="text-wire-cyan glow-cyan">
                        {item.subject}
                      </span>
                      <span className="text-wire-muted"> · </span>
                      <span className="text-wire-cyan">{item.value}</span>
                      {item.detail && (
                        <span className="text-wire-muted"> · {item.detail}</span>
                      )}
                    </span>
                    <a
                      href={item.linkUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-wire-border hover:text-wire-cyan tracking-wider hidden sm:inline shrink-0"
                      title="View the contract this was read from"
                    >
                      {item.linkShort} ↗
                    </a>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </section>
  );
}
