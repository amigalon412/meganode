"use client";

import {
  BAR_FILL,
  BAR_TRACK,
  formatUsd,
  STRATEGIES,
  type StrategyId,
} from "@/lib/strategies";

interface StrategyPickerProps {
  selected: StrategyId;
  onSelect: (id: StrategyId) => void;
}

export function StrategyPicker({ selected, onSelect }: StrategyPickerProps) {
  return (
    <section className="border border-wire-border bg-black p-6 md:p-8">
      <div className="flex items-baseline justify-between mb-5">
        <h2 className="font-mono text-sm text-wire-cyan glow-cyan tracking-[0.3em]">
          SELECT STRATEGY
        </h2>
        <span className="font-mono text-[10px] text-wire-muted tracking-[0.2em]">
          3 VAULTS
        </span>
      </div>
      <div className="font-mono text-[10px] text-wire-border mb-5">
        ╠══════════════════════════════════════════════════════════════╣
      </div>
      <div className="space-y-px bg-wire-border">
        {STRATEGIES.map((s) => {
          const active = s.id === selected;
          return (
            <button
              key={s.id}
              type="button"
              onClick={() => onSelect(s.id)}
              aria-pressed={active}
              className={
                "w-full text-left p-5 transition-all group " +
                (active
                  ? "bg-wire-card outline outline-wire-cyan glow-box-cyan"
                  : "bg-black hover:bg-wire-card")
              }
            >
              <div className="flex items-baseline justify-between gap-4 mb-2">
                <span className="flex items-baseline gap-2 min-w-0">
                  <span
                    className={
                      "font-mono text-[10px] " +
                      (active ? "text-wire-cyan" : "text-wire-dim")
                    }
                  >
                    {active ? "▸" : " "}
                  </span>
                  <span
                    className={
                      "font-mono text-lg tracking-widest transition-all " +
                      (active
                        ? "text-wire-cyan glow-cyan"
                        : "text-wire-cyan group-hover:glow-cyan")
                    }
                  >
                    {s.name}
                  </span>
                </span>
                <span
                  className={
                    "font-mono text-xl whitespace-nowrap " +
                    (active ? "text-wire-cyan glow-cyan" : "text-wire-cyan")
                  }
                >
                  {s.split}
                </span>
              </div>
              <div className="relative h-3 mb-3 font-mono text-xs leading-3 tracking-tighter">
                <div className="absolute inset-0 overflow-hidden whitespace-nowrap text-wire-dim">
                  {BAR_TRACK}
                </div>
                <div
                  className={
                    "absolute inset-y-0 left-0 overflow-hidden whitespace-nowrap " +
                    s.barClass +
                    (active ? " text-wire-cyan glow-cyan" : " text-wire-cyan")
                  }
                >
                  {BAR_FILL}
                </div>
              </div>
              <div className="flex items-baseline justify-between gap-4 font-mono text-[10px] tracking-[0.2em]">
                <span className="text-wire-muted truncate">{s.short}</span>
                <span className="text-wire-muted whitespace-nowrap">
                  {formatUsd(s.tvlUsd)} TVL
                </span>
              </div>
            </button>
          );
        })}
      </div>
    </section>
  );
}
