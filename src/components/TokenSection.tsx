"use client";

import { useState } from "react";

const CONTRACT = "0x8ecea3d0e648db646d824aa51eedeb16ac3d6878";
const BUY_URL =
  "https://app.uniswap.org/swap?chain=robinhood&inputCurrency=NATIVE&outputCurrency=0x8ecea3d0e648db646d824aa51eedeb16ac3d6878";

export function TokenSection() {
  const [copied, setCopied] = useState(false);

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(CONTRACT);
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {}
  };

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
          <span className="text-wire-cyan">$BLUR</span> is the token behind the protocol, live on
          Robinhood Chain. Its utility is tied to real usage: as the vaults grow, $BLUR is bought
          back off the market and retired to an address with no known key. The contract has no burn
          function, so supply stays fixed and the float shrinks instead. Value from what the
          protocol actually does — not hype.
        </p>
        <div className="bg-black border border-wire-border p-6 md:p-8">
          <div className="font-mono text-[10px] text-wire-muted tracking-[0.3em] mb-3">
            CONTRACT ADDRESS
          </div>
          <div className="flex flex-col md:flex-row md:items-center gap-4">
            <code className="font-mono text-xs md:text-sm text-wire-cyan glow-cyan break-all flex-1">
              {CONTRACT}
            </code>
            <div className="flex items-center gap-3 shrink-0">
              <button
                onClick={copy}
                className="font-mono text-xs text-wire-cyan border border-wire-border px-4 py-2.5 hover:border-wire-cyan hover:glow-cyan transition-all tracking-widest"
              >
                {copied ? "COPIED ✓" : "COPY"}
              </button>
              <a
                href={BUY_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="font-mono text-xs text-black bg-wire-cyan px-4 py-2.5 hover:opacity-90 hover:shadow-[0_0_30px_rgba(214,254,81,0.35)] transition-all tracking-widest whitespace-nowrap"
              >
                BUY $BLUR ↗
              </a>
            </div>
          </div>
          <div className="font-mono text-[10px] text-wire-muted mt-5 flex items-center gap-2">
            <span className="w-1.5 h-1.5 rounded-full bg-wire-cyan animate-blink"></span>
            LIVE ON ROBINHOOD CHAIN
          </div>
        </div>
      </div>
    </section>
  );
}
