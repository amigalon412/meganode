const PHRASES = [
  "TRADE ANYTHING",
  "TRANSFER ANYWHERE",
  "EXECUTE INSTANTLY",
  "POWERED ONCHAIN",
  "NO APP REQUIRED",
  "YOUR KEYS YOUR FUNDS",
  "ROBINHOOD CHAIN",
  "NON-CUSTODIAL",
];

export function TickerMarquee() {
  return (
    <div className="border-b border-wire-border bg-wire-card overflow-hidden py-2">
      <div className="flex animate-marquee whitespace-nowrap">
        {[...PHRASES, ...PHRASES].map((phrase, i) => (
          <span
            key={`${phrase}-${i}`}
            className="font-mono text-xs tracking-[0.3em] text-wire-muted mx-10"
          >
            {phrase}{" "}
            <span className="text-wire-cyan">◆</span>
          </span>
        ))}
      </div>
    </div>
  );
}
