import { cn } from "@/lib/utils";

/** Long enough to reach the edge of any container we put it in. */
const RULE = `╠${"═".repeat(62)}╣`;

interface AsciiRuleProps {
  /** Size and colour, e.g. "text-[10px] text-wire-border mb-6". */
  className?: string;
  /** Shorter runs for narrow columns; the default suits full-width sections. */
  length?: number;
}

/**
 * The decorative terminal rule under a section heading.
 *
 * It is drawn as a fixed-length string, which is fine until the viewport is
 * narrower than the string. Box-drawing characters have no break opportunities,
 * so the run cannot wrap: it widens its container instead, and on a phone that
 * stretched the whole page past the viewport. `overflow-x-hidden` on <main>
 * then clipped the excess -- taking real content with it, which is how a
 * strategy's split and its "NOT DEPLOYED" label ended up cut off mid-word.
 *
 * Clipping the rule itself is what fixes that: it still runs to the edge of its
 * container at any width, and it stops making the page wider than the screen.
 */
export function AsciiRule({ className, length }: AsciiRuleProps) {
  const rule = length ? `╠${"═".repeat(length)}╣` : RULE;
  return (
    <div
      aria-hidden="true"
      className={cn("font-mono overflow-hidden whitespace-nowrap select-none", className)}
    >
      {rule}
    </div>
  );
}
