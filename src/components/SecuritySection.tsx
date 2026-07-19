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
    title: "YOUR KEYS, ALWAYS",
    body: "Export your raw private key from the dashboard. No permission needed. Walk away to any wallet at any time.",
  },
  {
    tag: "[BOT]",
    num: "02",
    title: "BOT NEVER HOLDS KEYS",
    body: "The language model only parses intent into JSON. All execution is deterministic code with per-tx spending limits.",
  },
  {
    tag: "[SND]",
    num: "03",
    title: "PRE-GENERATED WALLETS",
    body: "Send to @anyone — even if they’ve never heard of us. They log in with X and the funds are already there.",
  },
];

export function SecuritySection() {
  return (
    <section className="border-b border-wire-border px-8 py-20">
      <div className="max-w-5xl mx-auto">
        <div className="font-mono text-xs text-wire-muted tracking-[0.4em] mb-2">
          {"// SECURITY MODEL"}
        </div>
        <div className="font-mono text-[10px] text-wire-border mb-8">
          ╠══════════════════════════════════════════════════════════════╣
        </div>
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
