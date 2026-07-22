"use client";

import { erc20Abi, formatUnits, type Address } from "viem";
import { useAccount, useReadContracts } from "wagmi";
import { blurVaultAbi } from "@/lib/abis";
import {
  DEPLOYED_VAULTS,
  USDG,
  USDG_DECIMALS,
  VAULT_ADDRESSES,
} from "@/lib/chain";
import type { StrategyId } from "@/lib/strategies";

/** A vault amount is always denominated in USDG, so always six decimals. */
export function formatUsdg(value: bigint, maximumFractionDigits = 2): string {
  return Number(formatUnits(value, USDG_DECIMALS)).toLocaleString("en-US", {
    style: "currency",
    currency: "USD",
    maximumFractionDigits,
  });
}

export interface VaultView {
  address: Address | null;
  /** Everything the vault holds, both legs, valued in USDG. */
  totalAssets: bigint | undefined;
  /** What the connected wallet's shares are currently worth, in USDG. */
  positionAssets: bigint | undefined;
  shares: bigint | undefined;
  /**
   * False when the oracle cannot price part of the basket -- a stale feed or a
   * stock split the adapter has not acknowledged. Deposits and withdrawals
   * that need a valuation will revert while this is false, so the UI says so
   * rather than letting the user sign a transaction that cannot land.
   */
  isPriceable: boolean | undefined;
  isLoading: boolean;
}

export function useVault(strategy: StrategyId): VaultView {
  const vault = VAULT_ADDRESSES[strategy];
  const { address: account } = useAccount();

  const vaultContract = { address: vault ?? undefined, abi: blurVaultAbi } as const;

  const { data, isLoading } = useReadContracts({
    allowFailure: true,
    contracts: [
      { ...vaultContract, functionName: "totalAssets" },
      { ...vaultContract, functionName: "isPriceable" },
      {
        ...vaultContract,
        functionName: "balanceOf",
        args: [account ?? "0x0000000000000000000000000000000000000000"],
      },
    ],
    query: { enabled: Boolean(vault) },
  });

  const shares = data?.[2]?.status === "success" ? data[2].result : undefined;

  const { data: positionData } = useReadContracts({
    contracts: [
      { ...vaultContract, functionName: "convertToAssets", args: [shares ?? 0n] },
    ],
    query: { enabled: Boolean(vault && account && shares !== undefined) },
  });

  return {
    address: vault,
    totalAssets: data?.[0]?.status === "success" ? data[0].result : undefined,
    isPriceable: data?.[1]?.status === "success" ? data[1].result : undefined,
    shares,
    positionAssets:
      positionData?.[0]?.status === "success" ? positionData[0].result : undefined,
    isLoading,
  };
}

/** Total value locked across every deployed vault. */
export function useTotalValueLocked(): {
  total: bigint | undefined;
  perVault: Partial<Record<StrategyId, bigint>>;
} {
  const { data } = useReadContracts({
    allowFailure: true,
    contracts: DEPLOYED_VAULTS.map(([, address]) => ({
      address,
      abi: blurVaultAbi,
      functionName: "totalAssets" as const,
    })),
    query: { enabled: DEPLOYED_VAULTS.length > 0 },
  });

  if (!data) return { total: undefined, perVault: {} };

  const perVault: Partial<Record<StrategyId, bigint>> = {};
  let total = 0n;
  let sawOne = false;

  DEPLOYED_VAULTS.forEach(([id], i) => {
    const entry = data[i];
    if (entry?.status !== "success") return;
    const value = entry.result as bigint;
    perVault[id] = value;
    total += value;
    sawOne = true;
  });

  // A partial sum would understate TVL without saying so, so only report a
  // total once at least one vault answered.
  return { total: sawOne ? total : undefined, perVault };
}

/** The connected wallet's USDG balance, and what it has approved to `spender`. */
export function useUsdg(spender: Address | null) {
  const { address: account } = useAccount();

  const { data, refetch } = useReadContracts({
    allowFailure: true,
    contracts: [
      {
        address: USDG,
        abi: erc20Abi,
        functionName: "balanceOf",
        args: [account ?? "0x0000000000000000000000000000000000000000"],
      },
      {
        address: USDG,
        abi: erc20Abi,
        functionName: "allowance",
        args: [
          account ?? "0x0000000000000000000000000000000000000000",
          spender ?? "0x0000000000000000000000000000000000000000",
        ],
      },
    ],
    query: { enabled: Boolean(account) },
  });

  return {
    balance: data?.[0]?.status === "success" ? data[0].result : undefined,
    allowance:
      spender && data?.[1]?.status === "success" ? data[1].result : undefined,
    refetch,
  };
}
