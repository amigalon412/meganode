export interface FeedItem {
  id: number;
  action: string;
  actor: string;
  verb: string;
  amountLabel: string;
  ticker: string;
  counterparty: string | null;
  txShort: string;
  txUrl: string;
  tweetUrl: string | null;
  ts: number;
}

export interface FeedStats {
  total: number;
  volumeUsd: number;
}

export interface FeedResponse {
  items: FeedItem[];
  stats: FeedStats;
}
