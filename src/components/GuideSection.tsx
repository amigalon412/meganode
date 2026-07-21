import Link from "next/link";

type GuideStep = {
  num: string;
  title: string;
  body: string;
};

const STEPS: GuideStep[] = [
  {
    num: "01",
    title: "YOU DEPOSIT",
    body: "USDG in. Your money starts earning on-chain lending yield the moment it lands — no lockup, no waiting.",
  },
  {
    num: "02",
    title: "IT GROWS",
    body: "A keeper rebalances a slice into the tokenized-stock basket toward your target split. No clicks, no timing.",
  },
  {
    num: "03",
    title: "YOU KEEP CONTROL",
    body: "Redeem anytime, in-kind. Withdrawals are permissionless and pro-rata — nobody can pause or block your exit.",
  },
  {
    num: "04",
    title: "$BLUR TIGHTENS",
    body: "5% of yield buys back $BLUR off the market and fuels incentives. Real usage feeds the token — not hype.",
  },
];

const DIVIDER = `╠${"═".repeat(62)}╣`;

export function GuideSection() {
  return (
    <section id="flywheel" className="border-b border-wire-border px-8 py-20 scroll-mt-16">
      <div className="max-w-5xl mx-auto">
        <div className="font-mono text-xs text-wire-muted tracking-[0.4em] mb-2">
          {"// THE FLYWHEEL"}
        </div>
        <div className="font-mono text-[10px] text-wire-border mb-6">{DIVIDER}</div>
        <h2 className="font-mono text-2xl md:text-3xl text-wire-cyan glow-cyan mb-10 leading-snug md:leading-9">
          Set it once. It compounds itself.
        </h2>
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
          <Link
            href="/docs"
            className="font-mono text-xs text-wire-cyan border border-wire-border px-5 py-2.5 hover:border-wire-cyan hover:glow-cyan transition-all tracking-widest"
          >
            OPEN DOCS →
          </Link>
        </div>
      </div>
    </section>
  );
}
