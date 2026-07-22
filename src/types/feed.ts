/** What produced the line. Drives the label and colour, not the content. */
export type FeedKind = "price" | "yield" | "vault";

export interface FeedItem {
  /** Stable across polls so the component can tell a new line from a redraw. */
  id: string;
  kind: FeedKind;
  /** The thing being reported: a ticker, a venue name, a vault name. */
  subject: string;
  /** The reading itself. */
  value: string;
  /** Optional context after the value. */
  detail?: string;
  /** Explorer link to the contract the reading came from. */
  linkUrl: string;
  linkShort: string;
  /**
   * When the chain says this changed -- a Chainlink round's updatedAt, a block
   * timestamp. Never a made-up age.
   */
  ts: number;
}

export interface FeedStats {
  blockNumber: number;
  /** Null until a vault is deployed; the UI must not print a zero as if it were real. */
  tvlUsd: number | null;
  vaultsDeployed: number;
}

export interface FeedResponse {
  items: FeedItem[];
  stats: FeedStats;
}
