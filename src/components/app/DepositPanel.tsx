"use client";

import { useState } from "react";
import type { Strategy } from "@/lib/strategies";

type Mode = "deposit" | "withdraw";

interface DepositPanelProps {
  strategy: Strategy;
}

export function DepositPanel({ strategy }: DepositPanelProps) {
  const [mode, setMode] = useState<Mode>("deposit");
  const [amount, setAmount] = useState("");

  const rows: { label: string; value: string }[] = [
    { label: "Wallet balance", value: "—" },
    { label: "Strategy", value: strategy.name },
    {
      label: mode === "deposit" ? "You receive" : "You redeem",
      value: mode === "deposit" ? "blur-shares" : "USDG + basket",
    },
  ];

  return (
    <div className="border border-wire-border bg-black">
      <div className="flex items-center gap-2.5 px-5 py-3.5 border-b border-wire-border bg-wire-card">
        <span className="font-mono text-xs text-wire-cyan/50 tracking-widest">
          ◉ ◉ ◉
        </span>
        <span className="font-mono text-sm text-wire-muted tracking-widest">
          root@blurvault:~$ {mode}
        </span>
        <span className="ml-auto font-mono text-sm text-wire-cyan animate-blink">
          █
        </span>
      </div>

      <div className="p-6 space-y-6">
        <div className="grid grid-cols-2 gap-px bg-wire-border">
          {(["deposit", "withdraw"] as Mode[]).map((m) => (
            <button
              key={m}
              type="button"
              onClick={() => setMode(m)}
              aria-pressed={mode === m}
              className={
                "font-mono text-sm py-3 tracking-widest transition-all " +
                (mode === m
                  ? "bg-wire-cyan text-black font-bold"
                  : "bg-black text-wire-muted hover:text-wire-cyan")
              }
            >
              {m.toUpperCase()}
            </button>
          ))}
        </div>

        <div className="flex items-center gap-3 border border-wire-border px-5 py-5 focus-within:border-wire-cyan transition-colors">
          <input
            value={amount}
            onChange={(e) => setAmount(e.target.value.replace(/[^0-9.]/g, ""))}
            inputMode="decimal"
            placeholder="0"
            aria-label={`Amount to ${mode}`}
            className="flex-1 min-w-0 bg-transparent font-mono text-3xl text-wire-cyan placeholder:text-wire-cyan/25 outline-none"
          />
          <span className="flex items-center gap-2 font-mono text-sm text-wire-muted tracking-widest shrink-0">
            <span className="w-1.5 h-1.5 rounded-full bg-wire-cyan" />
            USDG
          </span>
        </div>

        <div className="space-y-2.5">
          {rows.map((r) => (
            <div
              key={r.label}
              className="flex items-baseline justify-between gap-4 font-mono text-sm border-b border-dashed border-wire-border pb-3"
            >
              <span className="text-wire-muted">{r.label}</span>
              <span className="text-wire-cyan">{r.value}</span>
            </div>
          ))}
        </div>

        <button
          type="button"
          className="w-full bg-wire-cyan text-black font-mono font-bold text-base py-4 tracking-widest hover:opacity-90 hover:shadow-[0_0_40px_rgba(214,254,81,0.35)] transition-all"
        >
          CONNECT WALLET
        </button>

        <div className="font-mono text-xs text-wire-muted text-center tracking-[0.15em] leading-relaxed">
          NON-CUSTODIAL · NO ADMIN CAN MOVE YOUR FUNDS
        </div>
      </div>
    </div>
  );
}
