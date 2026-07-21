export type StrategyId = "steady" | "balanced" | "growth";

export interface Strategy {
  id: StrategyId;
  num: string;
  name: string;
  split: string;
  /** Share of the vault kept in stablecoin lending yield. */
  stablePct: number;
  /** Share of the vault held as tokenized stocks. */
  stockPct: number;
  tag: string;
  /** One-line label used in the app's strategy picker. */
  short: string;
  /** Width class for the filled half of the picker's allocation bar. */
  barClass: string;
  description: string;
  tvlUsd: number;
  rows: { label: string; pct: string }[];
}

export const STRATEGIES: Strategy[] = [
  {
    id: "steady",
    num: "[01]",
    name: "STEADY",
    split: "100 / 0",
    stablePct: 100,
    stockPct: 0,
    tag: "USDG YIELD · OPEN 24/7",
    short: "YIELD FLOOR ONLY",
    barClass: "w-full",
    description:
      "All stablecoin. Your USDG earns real on-chain lending yield. No stocks, no lockups.",
    tvlUsd: 78400,
    rows: [{ label: "USDG yield", pct: "100%" }],
  },
  {
    id: "balanced",
    num: "[02]",
    name: "BALANCED",
    split: "60 / 40",
    stablePct: 60,
    stockPct: 40,
    tag: "YIELD FLOOR · STOCKS",
    short: "YIELD PLUS A SLICE OF THE MARKET",
    barClass: "w-[60%]",
    description:
      "60% earning yield, 40% in a curated tokenized-stock basket (NVDA · SPY · AAPL · TSLA), auto-rebalanced.",
    tvlUsd: 71120,
    rows: [
      { label: "USDG yield", pct: "60%" },
      { label: "Stocks", pct: "40%" },
    ],
  },
  {
    id: "growth",
    num: "[03]",
    name: "GROWTH",
    split: "30 / 70",
    stablePct: 30,
    stockPct: 70,
    tag: "YIELD FLOOR · STOCKS",
    short: "MOSTLY MARKET",
    barClass: "w-[30%]",
    description:
      "30% yield floor, 70% tokenized stocks. For savers who want their idle cash to chase the market.",
    tvlUsd: 35400,
    rows: [
      { label: "USDG yield", pct: "30%" },
      { label: "Stocks", pct: "70%" },
    ],
  },
];

export const TOTAL_TVL_USD = STRATEGIES.reduce((sum, s) => sum + s.tvlUsd, 0);

/**
 * More block characters than any bar can show — the bar's container clips them,
 * so the fill tracks the container width instead of a fixed cell count.
 */
export const BAR_FILL = "█".repeat(200);
export const BAR_TRACK = "░".repeat(200);

export function formatUsd(value: number): string {
  return value.toLocaleString("en-US", {
    style: "currency",
    currency: "USD",
    maximumFractionDigits: 0,
  });
}
