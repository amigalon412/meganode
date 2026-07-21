import type { ReactNode } from "react";

interface EmptyCardProps {
  title: string;
  badge: string;
  body: string;
  /** Optional caption rendered under the card body, e.g. a guarantee line. */
  caption?: string;
  children?: ReactNode;
}

export function EmptyCard({ title, badge, body, caption, children }: EmptyCardProps) {
  return (
    <section className="border border-wire-border bg-black p-6 md:p-8">
      <div className="flex items-baseline justify-between gap-4 mb-5">
        <h2 className="font-mono text-sm text-wire-cyan glow-cyan tracking-[0.3em]">
          {title}
        </h2>
        <span className="font-mono text-[10px] text-wire-muted tracking-[0.2em]">
          {badge}
        </span>
      </div>
      <div className="border border-dashed border-wire-border px-6 py-10">
        <p className="font-mono text-xs text-wire-muted text-center leading-relaxed">
          {body}
        </p>
      </div>
      {children}
      {caption && (
        <div className="font-mono text-[10px] text-wire-muted tracking-[0.15em] text-center mt-4">
          {caption}
        </div>
      )}
    </section>
  );
}
