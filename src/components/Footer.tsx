import Image from "next/image";

const BOX = `╔══════════════════════════════════════════════════════════════════╗
║  BLUR · GROW YOUR BAG, AUTOMATICALLY · blur.finance               ║
╚══════════════════════════════════════════════════════════════════╝`;

export function Footer() {
  return (
    <footer className="px-8 py-12">
      <div className="font-mono text-[10px] text-wire-border mb-6 text-center whitespace-pre overflow-x-auto">{BOX}</div>
      <div className="flex flex-col md:flex-row items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <Image
            src="/images/logo.png"
            alt="BLUR"
            width={22}
            height={22}
            className="rounded opacity-50"
          />
          <span className="wire-title text-wire-cyan opacity-50 tracking-widest text-lg">
            BLUR
          </span>
        </div>
        <div className="flex items-center gap-6 font-mono text-xs text-wire-muted tracking-widest">
          <a href="#vaults" className="hover:text-wire-cyan transition-colors">
            VAULTS
          </a>
          <a href="#flywheel" className="hover:text-wire-cyan transition-colors">
            HOW IT WORKS
          </a>
          <a href="#token" className="hover:text-wire-cyan transition-colors">
            $BLUR
          </a>
          <a href="/docs" className="hover:text-wire-cyan transition-colors">
            DOCS
          </a>
          <a
            href="https://x.com/blurbotRH"
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-wire-cyan transition-colors"
          >
            X
          </a>
        </div>
        <div className="font-mono text-[10px] text-wire-muted text-center max-w-xs">
          NON-CUSTODIAL SOFTWARE ON ROBINHOOD CHAIN · NOT FINANCIAL ADVICE ·
          STOCK TOKENS NOT AVAILABLE TO US PERSONS
        </div>
      </div>
    </footer>
  );
}
