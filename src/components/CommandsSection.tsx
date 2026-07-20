interface Strategy {
  num: string;
  name: string;
  split: string;
  tag: string;
  description: string;
  rows: { label: string; pct: string }[];
}

const strategies: Strategy[] = [
  {
    num: "[01]",
    name: "STEADY",
    split: "100 / 0",
    tag: "USDG YIELD · OPEN 24/7",
    description:
      "All stablecoin. Your USDG earns real on-chain lending yield. No stocks, no lockups.",
    rows: [{ label: "USDG yield", pct: "100%" }],
  },
  {
    num: "[02]",
    name: "BALANCED",
    split: "60 / 40",
    tag: "YIELD FLOOR · STOCKS",
    description:
      "60% earning yield, 40% in a curated tokenized-stock basket (NVDA · SPY · AAPL · TSLA), auto-rebalanced.",
    rows: [
      { label: "USDG yield", pct: "60%" },
      { label: "Stocks", pct: "40%" },
    ],
  },
  {
    num: "[03]",
    name: "GROWTH",
    split: "30 / 70",
    tag: "YIELD FLOOR · STOCKS",
    description:
      "30% yield floor, 70% tokenized stocks. For savers who want their idle cash to chase the market.",
    rows: [
      { label: "USDG yield", pct: "30%" },
      { label: "Stocks", pct: "70%" },
    ],
  },
];

export function CommandsSection() {
  return (
    <section id="vaults" className="border-b border-wire-border px-8 py-20 scroll-mt-16">
      <div className="max-w-5xl mx-auto">
        <div className="font-mono text-xs text-wire-muted tracking-[0.4em] mb-2">
          {"// CHOOSE A STRATEGY"}
        </div>
        <div className="font-mono text-[10px] text-wire-border mb-6">
          ╠══════════════════════════════════════════════════════════════╣
        </div>
        <h2 className="font-mono text-2xl md:text-3xl text-wire-cyan glow-cyan mb-4 leading-snug md:leading-9">
          One deposit. Three ways to grow.
        </h2>
        <p className="font-mono text-sm text-wire-muted leading-relaxed max-w-3xl mb-10">
          Pick how much of your idle cash chases the market. Every strategy keeps a
          stablecoin yield floor and rebalances on its own.
        </p>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-px bg-wire-border">
          {strategies.map((s) => (
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
              <button className="font-mono text-xs text-wire-cyan border border-wire-border px-4 py-2.5 hover:border-wire-cyan hover:glow-cyan transition-all tracking-widest">
                CHOOSE {s.name} →
              </button>
              <div className="font-mono text-xs text-wire-dim mt-3">└─</div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
