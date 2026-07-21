"use client";

import { useState } from "react";
import { DepositPanel } from "@/components/app/DepositPanel";
import { EmptyCard } from "@/components/app/EmptyCard";
import { StrategyPicker } from "@/components/app/StrategyPicker";
import {
  formatUsd,
  STRATEGIES,
  TOTAL_TVL_USD,
  type StrategyId,
} from "@/lib/strategies";

export function VaultApp() {
  const [selected, setSelected] = useState<StrategyId>("balanced");
  const strategy = STRATEGIES.find((s) => s.id === selected) ?? STRATEGIES[1];

  const stats = [
    {
      label: "TOTAL VALUE LOCKED",
      value: formatUsd(TOTAL_TVL_USD),
      sub: "ACROSS 3 VAULTS",
      lit: true,
    },
    {
      label: "YOUR POSITION",
      value: "—",
      sub: `IN ${strategy.name}`,
      lit: false,
    },
    {
      label: "WALLET",
      value: "—",
      sub: "USDG AVAILABLE",
      lit: false,
    },
  ];

  return (
    <div className="px-6 md:px-8 py-10 md:py-14">
      <div className="max-w-6xl mx-auto">
        <div className="font-mono text-xs text-wire-muted tracking-[0.4em] mb-2">
          {"// VAULT TERMINAL"}
        </div>
        <div className="font-mono text-[10px] text-wire-border mb-6">
          ╠══════════════════════════════════════════════════════════════╣
        </div>
        <h1 className="font-mono text-2xl md:text-3xl text-wire-cyan glow-cyan mb-8 leading-snug md:leading-9">
          Put your cash to work.
        </h1>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-px bg-wire-border border border-wire-border mb-6">
          {stats.map((s) => (
            <div key={s.label} className="bg-black px-6 py-5">
              <div className="font-mono text-[10px] text-wire-muted tracking-[0.25em] mb-2">
                {s.label}
              </div>
              <div
                className={
                  "font-mono text-2xl mb-1 " +
                  (s.lit ? "text-wire-cyan glow-cyan" : "text-wire-cyan")
                }
              >
                {s.value}
              </div>
              <div className="font-mono text-[10px] text-wire-muted tracking-[0.2em]">
                {s.sub}
              </div>
            </div>
          ))}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-[1fr_360px] gap-6 items-start">
          <div className="space-y-6">
            <StrategyPicker selected={selected} onSelect={setSelected} />

            <EmptyCard
              title="YOUR POSITION"
              badge={strategy.name}
              body="Connect a wallet to see your balance, allocation and live value."
            />

            <EmptyCard
              title="AUTO-SAVE"
              badge="DCA"
              body="Top up toward a target on autopilot. Connect a wallet to set it up."
              caption="PERMISSIONLESS · MOVES ONLY USDG YOU APPROVE · CAPPED AT YOUR TARGET"
            >
              <button
                type="button"
                className="w-full font-mono text-xs text-wire-cyan border border-wire-border py-3 mt-4 tracking-widest hover:border-wire-cyan hover:glow-cyan transition-all"
              >
                CONNECT WALLET
              </button>
            </EmptyCard>
          </div>

          <div className="lg:sticky lg:top-20">
            <DepositPanel strategy={strategy} />
          </div>
        </div>
      </div>
    </div>
  );
}
