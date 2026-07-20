interface SecurityCard {
  tag: string;
  num: string;
  title: string;
  body: string;
}

const cards: SecurityCard[] = [
  {
    tag: "[KEY]",
    num: "01",
    title: "NON-CUSTODIAL BY DESIGN",
    body: "Every position is yours. Withdrawals are permissionless and in-kind, so you get your pro-rata slice back even when markets are closed.",
  },
  {
    tag: "[BOT]",
    num: "02",
    title: "AUTOMATED, BOUNDED",
    body: "An off-chain keeper harvests, rebalances and DCAs, but on-chain guards cap its reach. Designed so a compromised keeper can't touch your principal.",
  },
  {
    tag: "[FEE]",
    num: "03",
    title: "REAL YIELD, HONEST FEE",
    body: "Yield is real lending interest, not emissions. The 5% fee is designed to apply only to gains above a high-water mark, never your deposit.",
  },
];

export function SecuritySection() {
  return (
    <section className="border-b border-wire-border px-8 py-20">
      <div className="max-w-5xl mx-auto">
        <div className="font-mono text-xs text-wire-muted tracking-[0.4em] mb-2">
          {"// WHY BLUR"}
        </div>
        <div className="font-mono text-[10px] text-wire-border mb-6">
          ╠══════════════════════════════════════════════════════════════╣
        </div>
        <h2 className="font-mono text-2xl md:text-3xl text-wire-cyan glow-cyan mb-8 leading-snug md:leading-9">
          Built to be trusted.
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-px bg-wire-border">
          {cards.map((card) => (
            <div
              key={card.num}
              className="bg-black p-6 hover:bg-wire-card transition-colors"
            >
              <div className="font-mono text-xs text-wire-border mb-1">
                ┌─────────┐
              </div>
              <div className="font-mono text-xs text-wire-cyan mb-1">
                │ {card.tag} {card.num} │
              </div>
              <div className="font-mono text-xs text-wire-border mb-4">
                └─────────┘
              </div>
              <div className="font-mono text-sm text-wire-cyan glow-cyan mb-3">
                {card.title}
              </div>
              <div className="font-mono text-xs text-wire-muted leading-relaxed">
                {card.body}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
