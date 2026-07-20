import Image from "next/image";
import { XIcon } from "@/components/icons";

export function NavBar() {
  return (
    <nav className="grid grid-cols-2 lg:grid-cols-3 items-center px-6 py-3 border-b border-wire-border sticky top-0 z-50 bg-black/85 backdrop-blur">
      <div className="flex items-center gap-3">
        <Image
          src="/images/logo.png"
          alt="BLUR"
          width={32}
          height={32}
          className="rounded opacity-90"
        />
        <span className="wire-title text-2xl text-wire-cyan glow-cyan tracking-widest">
          BLUR
        </span>
      </div>
      <div className="hidden lg:flex items-center justify-center gap-8 font-mono text-xs tracking-widest text-wire-cyan/80">
        <a href="#vaults" className="hover:text-wire-cyan hover:glow-cyan transition-all">
          VAULTS
        </a>
        <a href="#flywheel" className="hover:text-wire-cyan hover:glow-cyan transition-all">
          HOW IT WORKS
        </a>
        <a href="#token" className="hover:text-wire-cyan hover:glow-cyan transition-all">
          $BLUR
        </a>
        <a href="#feed" className="hover:text-wire-cyan hover:glow-cyan transition-all">
          LIVE
        </a>
        <a href="/docs" className="hover:text-wire-cyan hover:glow-cyan transition-all">
          DOCS
        </a>
      </div>
      <div className="flex items-center justify-end gap-2 sm:gap-3">
        <a
          href="https://x.com/blurbotRH"
          target="_blank"
          rel="noopener noreferrer"
          title="@blurbotRH on X"
          className="flex items-center justify-center border border-wire-cyan text-wire-cyan glow-box-cyan p-2 hover:bg-wire-cyan hover:text-black transition-all"
        >
          <XIcon width={15} height={15} className="glow-svg-cyan" />
        </a>
        <a
          href="https://app.uniswap.org/swap?chain=robinhood&inputCurrency=NATIVE&outputCurrency=0x8ecea3d0e648db646d824aa51eedeb16ac3d6878"
          target="_blank"
          rel="noopener noreferrer"
          className="flex items-center gap-2 border border-wire-cyan text-wire-cyan glow-cyan font-mono text-xs px-4 py-2 hover:bg-wire-cyan hover:text-black transition-all tracking-widest whitespace-nowrap"
        >
          BUY $BLUR
        </a>
        <button className="flex items-center gap-2 border border-wire-cyan text-wire-cyan font-mono text-xs px-4 py-2 hover:bg-wire-cyan hover:text-black transition-all disabled:opacity-30 tracking-widest whitespace-nowrap">
          CONNECT <XIcon width={15} height={15} />
        </button>
      </div>
    </nav>
  );
}
