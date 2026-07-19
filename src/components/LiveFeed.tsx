"use client";

import { useEffect, useRef, useState } from "react";
import { XIcon } from "@/components/icons";
import type { FeedItem, FeedResponse, FeedStats } from "@/types/feed";

interface ActionMeta {
  label: string;
  cls: string;
  arrow: string;
}

const ACTION_MAP: Record<string, ActionMeta> = {
  buy: { label: "BUY", cls: "text-wire-green glow-green", arrow: "▲" },
  sell: { label: "SELL", cls: "text-wire-purple glow-purple", arrow: "▼" },
  send: { label: "SEND", cls: "text-wire-cyan glow-cyan", arrow: "→" },
  drop: { label: "DROP", cls: "text-wire-green glow-green", arrow: "🎁" },
};

function actionMeta(action: string): ActionMeta {
  return (
    ACTION_MAP[action] ?? {
      label: action.toUpperCase(),
      cls: "text-wire-cyan",
      arrow: "•",
    }
  );
}

function timeAgo(ts: number): string {
  const t = Math.max(0, Math.floor(Date.now() / 1000 - ts));
  if (t < 60) return `${t}s`;
  if (t < 3600) return `${Math.floor(t / 60)}m`;
  if (t < 86400) return `${Math.floor(t / 3600)}h`;
  return `${Math.floor(t / 86400)}d`;
}

export function LiveFeed() {
  const [items, setItems] = useState<FeedItem[]>([]);
  const [stats, setStats] = useState<FeedStats>({ total: 0, volumeUsd: 0 });
  const [loaded, setLoaded] = useState(false);
  const [highlight, setHighlight] = useState<Set<number>>(new Set());
  const [, setTick] = useState(0);
  const seen = useRef(new Set<number>());

  useEffect(() => {
    let alive = true;
    const load = async () => {
      try {
        const res = await fetch("/api/feed?limit=25", { cache: "no-store" });
        if (!res.ok) return;
        const data: FeedResponse = await res.json();
        if (!alive) return;
        const fresh = new Set<number>();
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
    const poll = setInterval(load, 8000);
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
            root@wirebot:~$ tail -f /var/log/wire/transactions
          </span>
        </div>
        <div className="flex items-center gap-5 shrink-0">
          <span className="hidden md:inline text-wire-muted text-xs font-mono tracking-widest">
            {stats.total.toLocaleString()} TX · $
            {Math.round(stats.volumeUsd).toLocaleString()} VOL
          </span>
          <span className="text-wire-cyan text-xs font-mono flex items-center gap-1.5">
            <span className="w-1.5 h-1.5 rounded-full bg-wire-cyan animate-blink"></span>{" "}
            LIVE
          </span>
        </div>
      </div>
      <div className="bg-wire-card">
        <div className="px-6 py-4 font-mono text-xs md:text-sm max-h-[440px] overflow-y-auto">
          {!loaded || items.length === 0 ? (
            <div className="text-wire-muted py-8 text-center">
              <span className="cursor">CONNECTING TO LEDGER</span>
            </div>
          ) : (
            <div className="space-y-1.5">
              {items.map((item) => {
                const action = actionMeta(item.action);
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
                    <span className={`shrink-0 w-[70px] ${action.cls}`}>
                      {action.arrow} {action.label}
                    </span>
                    <span className="flex-1 min-w-0 truncate">
                      <a
                        href={`https://x.com/${item.actor}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-wire-cyan hover:glow-cyan hover:underline"
                      >
                        @{item.actor}
                      </a>
                      <span className="text-wire-muted">
                        {" "}
                        {item.verb}{" "}
                      </span>
                      <span className="text-wire-cyan">
                        {item.amountLabel}{" "}
                      </span>
                      <span className="text-wire-cyan glow-cyan">
                        ${item.ticker}
                      </span>
                      {item.counterparty && (
                        <>
                          <span className="text-wire-muted"> → </span>
                          <a
                            href={`https://x.com/${item.counterparty}`}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-wire-cyan hover:glow-cyan hover:underline"
                          >
                            @{item.counterparty}
                          </a>
                        </>
                      )}
                    </span>
                    <div className="flex items-center gap-3 shrink-0">
                      {item.tweetUrl && (
                        <a
                          href={item.tweetUrl}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-wire-border hover:text-wire-cyan hidden sm:inline"
                          title="View tweet on X"
                        >
                          <XIcon
                            width={12}
                            height={12}
                            className="inline-block align-middle"
                          />
                        </a>
                      )}
                      <a
                        href={item.txUrl}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-wire-border hover:text-wire-cyan tracking-wider hidden sm:inline"
                        title="View on Blockscout"
                      >
                        {item.txShort} ↗
                      </a>
                    </div>
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
