import Link from "next/link";
import { STRATEGIES } from "@/lib/strategies";
import { AsciiRule } from "@/components/AsciiRule";

export function CommandsSection() {
  return (
    <section id="vaults" className="border-b border-wire-border px-8 py-20 scroll-mt-16">
      <div className="max-w-5xl mx-auto">
        <div className="font-mono text-xs text-wire-muted tracking-[0.4em] mb-2">
          {"// CHOOSE A STRATEGY"}
        </div>
        <AsciiRule className="text-[10px] text-wire-border mb-6" />
        <h2 className="font-mono text-2xl md:text-3xl text-wire-cyan glow-cyan mb-4 leading-snug md:leading-9">
          One deposit. Three ways to grow.
        </h2>
        <p className="font-mono text-sm text-wire-muted leading-relaxed max-w-3xl mb-10">
          Pick how much of your idle cash chases the market. Every strategy keeps a
          stablecoin yield floor and rebalances on its own.
        </p>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-px bg-wire-border">
          {STRATEGIES.map((s) => (
            <div
              key={s.name}
              className="bg-black p-6 hover:bg-wire-card transition-colors group flex flex-col"
            >
              <div className="font-mono text-xs text-wire-dim mb-1">┌─ {s.num}</div>
              <div className="flex items-baseline justify-between mb-1">
                <span className="font-mono text-lg text-wire-cyan group-hover:glow-cyan transition-all tracking-widest">
                  {s.name}
                </span>
                <span className="font-mono text-2xl text-wire-cyan glow-cyan">
                  {s.split}
                </span>
              </div>
              <div className="font-mono text-[10px] text-wire-muted tracking-[0.2em] mb-4">
                {s.tag}
              </div>
              <div className="font-mono text-xs text-wire-muted leading-relaxed mb-5 flex-1">
                {s.description}
              </div>
              <div className="space-y-1 mb-5">
                {s.rows.map((r) => (
                  <div
                    key={r.label}
                    className="flex items-center justify-between font-mono text-xs"
                  >
                    <span className="text-wire-muted">{r.label}</span>
                    <span className="text-wire-cyan">{r.pct}</span>
                  </div>
                ))}
              </div>
              <Link
                href="/app"
                className="font-mono text-xs text-wire-cyan text-center border border-wire-border px-4 py-2.5 hover:border-wire-cyan hover:glow-cyan transition-all tracking-widest"
              >
                CHOOSE {s.name} →
              </Link>
              <div className="font-mono text-xs text-wire-dim mt-3">└─</div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
