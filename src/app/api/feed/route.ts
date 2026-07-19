import { NextResponse } from "next/server";
import { FEED_ITEMS, FEED_STATS } from "@/lib/feed-data";
import type { FeedResponse } from "@/types/feed";

export async function GET(request: Request) {
  const limitParam = new URL(request.url).searchParams.get("limit");
  const limit = Math.max(1, Number(limitParam) || 25);
  const now = Math.floor(Date.now() / 1000);

  const body: FeedResponse = {
    items: FEED_ITEMS.slice(0, limit).map(({ ageSeconds, ...item }) => ({
      ...item,
      ts: now - ageSeconds,
    })),
    stats: FEED_STATS,
  };

  return NextResponse.json(body);
}
