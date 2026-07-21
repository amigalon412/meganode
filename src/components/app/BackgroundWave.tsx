/**
 * Oscilloscope traces drifting behind the terminal. Each path repeats on a
 * period that divides the 50% translate the animation applies, so the loop has
 * no visible seam. Spread down the viewport so the signal reads in the gutters
 * either side of the content column.
 */
const TRACE_TIGHT =
  "M0,120 C100,25 300,215 400,120 C500,25 700,215 800,120 C900,25 1100,215 1200,120 C1300,25 1500,215 1600,120";
const TRACE_WIDE =
  "M0,120 C200,45 600,195 800,120 C1000,45 1400,195 1600,120";

interface Trace {
  d: string;
  band: string;
  anim: string;
  width: number;
  opacity: number;
  dash?: string;
}

const TRACES: Trace[] = [
  {
    d: TRACE_WIDE,
    band: "top-[4%] h-[34vh]",
    anim: "animate-wave-slow",
    width: 2,
    opacity: 0.3,
  },
  {
    d: TRACE_TIGHT,
    band: "top-[32%] h-[30vh]",
    anim: "animate-wave-fast",
    width: 1.5,
    opacity: 0.45,
    dash: "14 10",
  },
  {
    d: TRACE_WIDE,
    band: "top-[62%] h-[36vh]",
    anim: "animate-wave-mid",
    width: 2,
    opacity: 0.22,
  },
];

export function BackgroundWave() {
  return (
    <div
      aria-hidden
      className="fixed inset-0 z-0 overflow-hidden pointer-events-none"
    >
      {TRACES.map((t, i) => (
        <div key={i} className={"absolute inset-x-0 " + t.band}>
          <svg
            viewBox="0 0 1600 240"
            preserveAspectRatio="none"
            className={"absolute inset-y-0 left-0 w-[200%] h-full " + t.anim}
          >
            <path
              d={t.d}
              fill="none"
              stroke="var(--cyan)"
              strokeWidth={t.width}
              strokeOpacity={t.opacity}
              strokeDasharray={t.dash}
            />
          </svg>
        </div>
      ))}
    </div>
  );
}
