export interface FeedItem {
  id: number;
  action: string;
  actor: string;
  system: boolean;
  pre: string;
  asset: string;
  post: string;
  txShort: string;
  txUrl: string;
  tweetUrl: string | null;
  ts: number;
}

export interface FeedStats {
  total: number;
  tvlUsd: number;
}

export interface FeedResponse {
  items: FeedItem[];
  stats: FeedStats;
}
