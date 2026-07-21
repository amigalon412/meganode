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
    <section className="border border-wire-border bg-black p-7 md:p-9">
      <div className="flex items-baseline justify-between gap-4 mb-6">
        <h2 className="font-mono text-lg text-wire-cyan glow-cyan tracking-[0.3em]">
          {title}
        </h2>
        <span className="font-mono text-xs text-wire-muted tracking-[0.2em]">
          {badge}
        </span>
      </div>
      <div className="border border-dashed border-wire-border px-8 py-12">
        <p className="font-mono text-sm text-wire-muted text-center leading-relaxed">
          {body}
        </p>
      </div>
      {children}
      {caption && (
        <div className="font-mono text-xs text-wire-muted tracking-[0.15em] text-center mt-5">
          {caption}
        </div>
      )}
    </section>
  );
}
