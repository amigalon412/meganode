"use client";

import { useEffect, useState } from "react";
import { XIcon } from "@/components/icons";

const ASCII = `
██╗    ██╗██╗██████╗ ███████╗
██║    ██║██║██╔══██╗██╔════╝
██║ █╗ ██║██║██████╔╝█████╗  
██║███╗██║██║██╔══██╗██╔══╝  
╚███╔███╔╝██║██║  ██║███████╗
 ╚══╝╚══╝ ╚═╝╚═╝  ╚═╝╚══════╝
`.trim();

const BOOT = [
  { delay: 0, text: "> SYSTEM BOOT  .............. [OK]" },
  { delay: 700, text: "> CHAIN LINK   .............. [OK]" },
  { delay: 1400, text: "> WALLET LAYER .............. [OK]" },
  { delay: 2100, text: "> LISTENING ON @wirebotRH ....... [ACTIVE]" },
];

export function HeroSection() {
  const [shown, setShown] = useState<number[]>([]);

  useEffect(() => {
    const timeouts = BOOT.map((e, i) =>
      setTimeout(() => setShown((s) => [...s, i]), e.delay)
    );
    return () => {
      timeouts.forEach((t) => clearTimeout(t));
    };
  }, []);

  return (
    <section className="min-h-[78vh] flex flex-col items-center justify-center px-8 py-16 border-b border-wire-border text-center">
      <div className="font-mono text-[10px] text-wire-muted mb-8 tracking-widest hidden md:block">
        <div>┌──────────────────────────────┐</div>
        <div>│  ROBINHOOD CHAIN · ID: 4663  │</div>
        <div>│  STATUS: ████████████  LIVE  │</div>
        <div>└──────────────────────────────┘</div>
      </div>
      <pre
        className="font-mono text-[10px] md:text-[14px] lg:text-[18px] leading-tight text-wire-cyan glow-cyan glitch mb-8 animate-flicker whitespace-pre"
        data-text={ASCII}
      >
        {ASCII}
      </pre>
      <div className="font-mono text-base md:text-lg text-wire-muted mb-4 tracking-[0.25em] flex items-center gap-2 justify-center">
        <span className="text-wire-cyan">▶</span>THE COMMAND LAYER FOR FINANCE
      </div>
      <p className="font-mono text-xs md:text-sm text-wire-muted max-w-xl mb-10 leading-relaxed md:leading-5">
        Buy, sell, send and airdrop tokenized stocks, ETFs, index baskets and
        tokens on Robinhood Chain — by posting a tweet. No app. No seed phrase.
        Your keys, always.
      </p>
      <div className="mb-10 space-y-1 text-left inline-block">
        {BOOT.map((e, i) => (
          <div
            key={e.text}
            className={
              "font-mono text-sm transition-all duration-200 " +
              (shown.includes(i) ? "opacity-100" : "opacity-0") +
              " " +
              (i === BOOT.length - 1 ? "text-wire-cyan" : "text-wire-muted")
            }
          >
            {e.text}
          </div>
        ))}
        {shown.length === BOOT.length && (
          <div className="text-wire-cyan font-mono text-sm cursor" />
        )}
      </div>
      <div className="space-y-3 flex flex-col items-center">
        <button className="flex items-center gap-3 bg-wire-cyan text-black font-mono font-bold text-base px-10 py-4 hover:opacity-90 hover:shadow-[0_0_40px_rgba(0,255,255,0.35)] transition-all disabled:opacity-30 tracking-widest">
          SIGN IN WITH <XIcon width={15} height={15} /> →
        </button>
        <div className="font-mono text-xs text-wire-muted">
          _ SELF-CUSTODIAL WALLET · GENERATED IN ONE TAP · NO SEED PHRASE
        </div>
      </div>
    </section>
  );
}
