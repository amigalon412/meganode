export function TokenSection() {
  return (
    <section id="token" className="border-b border-wire-border px-8 py-20 scroll-mt-16">
      <div className="max-w-5xl mx-auto">
        <div className="font-mono text-xs text-wire-muted tracking-[0.4em] mb-2">
          {"// $BLUR"}
        </div>
        <div className="font-mono text-[10px] text-wire-border mb-6">
          ╠══════════════════════════════════════════════════════════════╣
        </div>
        <h2 className="font-mono text-2xl md:text-3xl text-wire-cyan glow-cyan mb-4 leading-snug md:leading-9">
          A token that earns its keep.
        </h2>
        <p className="font-mono text-sm text-wire-muted leading-relaxed max-w-3xl mb-10">
          <span className="text-wire-cyan">$BLUR</span> will be the token behind the protocol. Its
          utility is tied to real usage: as the vaults grow, fee revenue buys $BLUR off the market
          and the contract burns it — supply falls by the amount bought, and you can check that
          against the token yourself. Value from what the protocol actually does — not hype.
        </p>
        <div className="bg-black border border-wire-border p-6 md:p-8">
          <div className="font-mono text-[10px] text-wire-muted tracking-[0.3em] mb-3">
            CONTRACT ADDRESS
          </div>
          <div className="font-mono text-sm text-wire-cyan glow-cyan mb-3">NOT LAUNCHED YET</div>
          <div className="font-mono text-xs text-wire-muted leading-relaxed max-w-2xl">
            There is no $BLUR contract to buy. When one is deployed, its address will appear here
            and in the docs, and a buy link will appear alongside it. Until then, treat any address
            presented as $BLUR — anywhere, by anyone — as fake.
          </div>
        </div>
      </div>
    </section>
  );
}
