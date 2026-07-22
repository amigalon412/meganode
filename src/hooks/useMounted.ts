"use client";

import { useSyncExternalStore } from "react";

// Nothing ever changes, so the subscription is a no-op -- the whole point is
// the difference between the server snapshot and the client one.
const subscribe = () => () => {};
const onClient = () => true;
const onServer = () => false;

/**
 * True only after hydration.
 *
 * Wallet state cannot exist on the server, so any component that renders it
 * must render the disconnected markup first and swap afterwards -- otherwise
 * the server HTML and the first client render disagree and React discards the
 * tree.
 */
export function useMounted(): boolean {
  return useSyncExternalStore(subscribe, onClient, onServer);
}
