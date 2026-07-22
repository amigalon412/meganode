import { defineChain, getAddress, type Address } from "viem";
import type { StrategyId } from "@/lib/strategies";

/**
 * Robinhood Chain. An Arbitrum Orbit L2 whose gas token is ETH; the stablecoin
 * we take deposits in (USDG) is an ordinary ERC-20 on top.
 *
 * Confirmed against the live chain: eth_chainId returns 0x1237 (4663), and the
 * explorer's own stats endpoint reports ETH as the native coin.
 */
export const robinhoodChain = defineChain({
  id: 4663,
  name: "Robinhood Chain",
  nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 },
  rpcUrls: {
    default: { http: ["https://rpc.mainnet.chain.robinhood.com"] },
  },
  blockExplorers: {
    default: {
      name: "Blockscout",
      url: "https://robinhoodchain.blockscout.com",
    },
  },
});

/** Global Dollar. Six decimals, not eighteen -- do not assume. */
export const USDG: Address = getAddress(
  "0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168",
);
export const USDG_DECIMALS = 6;

/**
 * Reads an address out of the environment, returning null rather than throwing
 * when it is absent or malformed.
 *
 * A missing vault address is the normal state before a deployment, and the UI
 * is built to say so. What it must never do is silently treat a typo as a real
 * contract: getAddress rejects a bad checksum, and anything it rejects becomes
 * null, which surfaces as "not deployed" instead of failed calls to nowhere.
 */
function optionalAddress(value: string | undefined): Address | null {
  if (!value) return null;
  try {
    return getAddress(value.trim());
  } catch {
    return null;
  }
}

/**
 * One BlurVault per strategy. These are read from the environment because they
 * do not exist yet -- nothing is deployed to Robinhood Chain mainnet.
 *
 * Next.js inlines NEXT_PUBLIC_* only at literal property accesses, so each one
 * has to be spelled out here rather than looked up by a computed key.
 */
export const VAULT_ADDRESSES: Record<StrategyId, Address | null> = {
  steady: optionalAddress(process.env.NEXT_PUBLIC_VAULT_STEADY),
  balanced: optionalAddress(process.env.NEXT_PUBLIC_VAULT_BALANCED),
  growth: optionalAddress(process.env.NEXT_PUBLIC_VAULT_GROWTH),
};

export const DEPLOYED_VAULTS = Object.entries(VAULT_ADDRESSES).filter(
  (entry): entry is [StrategyId, Address] => entry[1] !== null,
);

/** True when no vault has been deployed yet, i.e. the app is display-only. */
export const NOTHING_DEPLOYED = DEPLOYED_VAULTS.length === 0;

export function explorerAddressUrl(address: Address): string {
  return `${robinhoodChain.blockExplorers.default.url}/address/${address}`;
}

export function explorerTxUrl(hash: string): string {
  return `${robinhoodChain.blockExplorers.default.url}/tx/${hash}`;
}
