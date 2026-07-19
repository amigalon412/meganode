type GuideStep = {
  num: string;
  title: string;
  body: string;
};

const STEPS: GuideStep[] = [
  {
    num: "01",
    title: "SIGN IN WITH X",
    body: "Connect your X account. WIRE instantly generates a self-custodial wallet tied to your handle — no seed phrase, no setup.",
  },
  {
    num: "02",
    title: "DEPOSIT",
    body: "Fund your wallet from the dashboard. Send USDG for stocks & baskets, and a little ETH for gas (and for token/ETH trades).",
  },
  {
    num: "03",
    title: "TWEET A COMMAND",
    body: "Mention @wirebotRH anywhere in a post: “buy $50 NVDA”, “sell all TSLA”, “send @friend $25 AAPL”, or “buy $20 MAG7”.",
  },
  {
    num: "04",
    title: "GET CONFIRMED",
    body: "The bot replies with the result and a Blockscout link. Everything shows up in the live feed above in real time.",
  },
];

const DIVIDER = `╠${"═".repeat(62)}╣`;

export function GuideSection() {
  return (
    <section id="guide" className="border-b border-wire-border px-8 py-20 scroll-mt-16">
      <div className="max-w-5xl mx-auto">
        <div className="font-mono text-xs text-wire-muted tracking-[0.4em] mb-2">
          {"// QUICK START"}
        </div>
        <div className="font-mono text-[10px] text-wire-border mb-10">{DIVIDER}</div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-px bg-wire-border">
          {STEPS.map((step) => (
            <div key={step.num} className="bg-black p-8 hover:bg-wire-card transition-colors">
              <div className="flex items-baseline gap-3 mb-3">
                <span className="font-mono text-3xl text-wire-cyan glow-cyan">{step.num}</span>
                <span className="font-mono text-sm text-wire-cyan tracking-widest">
                  {step.title}
                </span>
              </div>
              <div className="font-mono text-xs text-wire-muted leading-relaxed">{step.body}</div>
            </div>
          ))}
        </div>
        <div className="mt-8 flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="font-mono text-xs text-wire-muted">
            _ NEED MORE DETAIL? READ THE FULL DOCUMENTATION.
          </div>
          <a
            href="/docs"
            className="font-mono text-xs text-wire-cyan border border-wire-border px-5 py-2.5 hover:border-wire-cyan hover:glow-cyan transition-all tracking-widest"
          >
            OPEN DOCS →
          </a>
        </div>
      </div>
    </section>
  );
}
