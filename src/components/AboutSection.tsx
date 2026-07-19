type AboutCard = {
  title: string;
  body: string;
};

const cards: AboutCard[] = [
  {
    title: "STOCKS & ETFS",
    body: "50+ tokenized equities (NVDA, TSLA, SPY…) settled in USDG via Uniswap v4 pools.",
  },
  {
    title: "INDEX BASKETS",
    body: "One-tap diversified exposure — MAG7, AI6 and more, minted through the Vimen protocol.",
  },
  {
    title: "TOKENS & ETH",
    body: "Native ETH and community tokens (like $BLUR) routed through WETH liquidity.",
  },
  {
    title: "SEND BY @HANDLE",
    body: "Transfer assets to any X user — even before they sign up. Funds wait in their wallet.",
  },
  {
    title: "AIRDROPS",
    body: "Reward your replies: “drop $5 of NVDA to first 10 replies”. One claim per person.",
  },
  {
    title: "YOUR KEYS",
    body: "MPC-backed wallet, exportable private key, non-custodial by design.",
  },
];

export function AboutSection() {
  return (
    <section id="about" className="border-b border-wire-border px-8 py-20 scroll-mt-16">
      <div className="max-w-5xl mx-auto">
        <div className="font-mono text-xs text-wire-muted tracking-[0.4em] mb-2">{"// WHAT IS BLUR"}</div>
        <div className="font-mono text-[10px] text-wire-border mb-10">╠══════════════════════════════════════════════════════════════╣</div>
        <h2 className="font-mono text-2xl md:text-3xl text-wire-cyan glow-cyan mb-6 leading-snug md:leading-9">Trade the market from your timeline.</h2>
        <p className="font-mono text-sm text-wire-muted leading-relaxed max-w-3xl mb-10">
          BLUR is a non-custodial trading bot that lives on X. Mention{" "}
          <span className="text-wire-cyan">@blurbotRH</span> in plain language and it executes real
          on-chain trades on Robinhood Chain — tokenized stocks & ETFs, index baskets, native ETH
          and community tokens. A language model only reads your intent; every transaction is
          signed by deterministic code inside your own wallet, with hard spending limits. You can
          export your private key any time and walk away.
        </p>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-px bg-wire-border">
          {cards.map((card) => (
            <div key={card.title} className="bg-black p-6 hover:bg-wire-card transition-colors">
              <div className="font-mono text-sm text-wire-cyan glow-cyan mb-2">{card.title}</div>
              <div className="font-mono text-xs text-wire-muted leading-relaxed">{card.body}</div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
