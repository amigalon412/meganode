interface Command {
  command: string;
  description: string;
}

const commands: Command[] = [
  {
    command: "@blurbotRH buy $50 NVDA",
    description: "Buy any tokenized stock or ETF with your USDG balance",
  },
  {
    command: "@blurbotRH sell all TSLA",
    description: "Liquidate a full position — or a fixed dollar amount",
  },
  {
    command: "@blurbotRH buy $20 MAG7",
    description: "Buy an index basket in one tap (MAG7, AI6…)",
  },
  {
    command: "@blurbotRH send @handle $25 AAPL",
    description: "Send any asset to an X handle — even non-users",
  },
  {
    command: "@blurbotRH buy $10 BLUR",
    description: "Trade community tokens & native ETH via WETH pools",
  },
  {
    command: "@blurbotRH drop $5 NVDA to first 10",
    description: "Airdrop to the first N unique repliers — 1 per person",
  },
];

export function CommandsSection() {
  return (
    <section className="border-b border-wire-border px-8 py-20">
      <div className="max-w-5xl mx-auto">
        <div className="font-mono text-xs text-wire-muted tracking-[0.4em] mb-2">
          {"// SUPPORTED COMMANDS"}
        </div>
        <div className="font-mono text-[10px] text-wire-border mb-8">
          ╠══════════════════════════════════════════════════════════════╣
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-px bg-wire-border">
          {commands.map((item) => (
            <div
              key={item.command}
              className="bg-black p-6 hover:bg-wire-card transition-colors group"
            >
              <div className="font-mono text-xs text-wire-dim mb-1">┌─</div>
              <div className="font-mono text-sm text-wire-cyan group-hover:glow-cyan transition-all mb-2">
                {item.command}
              </div>
              <div className="font-mono text-xs text-wire-muted">
                {item.description}
              </div>
              <div className="font-mono text-xs text-wire-dim mt-2">└─</div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
