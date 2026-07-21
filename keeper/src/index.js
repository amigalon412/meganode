import { createPublicClient, createWalletClient, http, defineChain, formatUnits } from "viem";
import { privateKeyToAccount } from "viem/accounts";

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

const RPC_URL = process.env.RPC_URL ?? "https://rpc.mainnet.chain.robinhood.com";
const VAULT = required("VAULT_ADDRESS");
const GUARD = required("GUARD_ADDRESS");

// Do not act on dust. A call that allocates less than this is not worth the gas
// or the block space, and spamming small allocations only feeds venue rounding.
const MIN_DEPLOY = BigInt(process.env.MIN_DEPLOY_UNITS ?? 100_000_000); // 100 USDG
const POLL_MS = Number(process.env.POLL_MS ?? 60_000);

// Dry run is the default on purpose. Sending transactions requires opting in.
const DRY_RUN = process.env.DRY_RUN !== "false";
const ONCE = process.argv.includes("--once");

const robinhood = defineChain({
  id: 4663,
  name: "Robinhood Chain",
  nativeCurrency: { name: "Ether", symbol: "ETH", decimals: 18 },
  rpcUrls: { default: { http: [RPC_URL] } },
});

// ---------------------------------------------------------------------------
// ABIs — only what is used
// ---------------------------------------------------------------------------

const vaultAbi = [
  { name: "asset", type: "function", stateMutability: "view", inputs: [], outputs: [{ type: "address" }] },
  { name: "totalAssets", type: "function", stateMutability: "view", inputs: [], outputs: [{ type: "uint256" }] },
  { name: "bufferBps", type: "function", stateMutability: "view", inputs: [], outputs: [{ type: "uint16" }] },
  { name: "guard", type: "function", stateMutability: "view", inputs: [], outputs: [{ type: "address" }] },
  { name: "sharePrice", type: "function", stateMutability: "view", inputs: [], outputs: [{ type: "uint256" }] },
];

const guardAbi = [
  { name: "isKeeper", type: "function", stateMutability: "view", inputs: [{ type: "address" }], outputs: [{ type: "bool" }] },
  { name: "isVault", type: "function", stateMutability: "view", inputs: [{ type: "address" }], outputs: [{ type: "bool" }] },
  { name: "paused", type: "function", stateMutability: "view", inputs: [], outputs: [{ type: "bool" }] },
  { name: "cooldown", type: "function", stateMutability: "view", inputs: [], outputs: [{ type: "uint32" }] },
  { name: "maxDeployPerCall", type: "function", stateMutability: "view", inputs: [], outputs: [{ type: "uint256" }] },
  { name: "lastActionAt", type: "function", stateMutability: "view", inputs: [{ type: "address" }], outputs: [{ type: "uint256" }] },
  { name: "deployIdle", type: "function", stateMutability: "nonpayable", inputs: [{ type: "address" }], outputs: [{ type: "uint256" }] },
];

const erc20Abi = [
  { name: "balanceOf", type: "function", stateMutability: "view", inputs: [{ type: "address" }], outputs: [{ type: "uint256" }] },
  { name: "decimals", type: "function", stateMutability: "view", inputs: [], outputs: [{ type: "uint8" }] },
];

// ---------------------------------------------------------------------------

const publicClient = createPublicClient({ chain: robinhood, transport: http(RPC_URL) });

// The key is only read when actually sending. A dry run never touches it, so
// the bot can be inspected and left running without one present.
let account = null;
let walletClient = null;
if (!DRY_RUN) {
  const pk = required("KEEPER_PRIVATE_KEY");
  account = privateKeyToAccount(pk.startsWith("0x") ? pk : `0x${pk}`);
  walletClient = createWalletClient({ account, chain: robinhood, transport: http(RPC_URL) });
}

function required(name) {
  const v = process.env[name];
  if (!v) {
    console.error(`missing required env var: ${name}`);
    process.exit(1);
  }
  return v;
}

function log(...args) {
  console.log(new Date().toISOString(), ...args);
}

/// Reads chain state and decides whether a call is warranted. Every reason to
/// skip is reported rather than swallowed, so a quiet keeper is explainable.
async function evaluate() {
  const [asset, totalAssets, bufferBps, vaultGuard] = await Promise.all([
    publicClient.readContract({ address: VAULT, abi: vaultAbi, functionName: "asset" }),
    publicClient.readContract({ address: VAULT, abi: vaultAbi, functionName: "totalAssets" }),
    publicClient.readContract({ address: VAULT, abi: vaultAbi, functionName: "bufferBps" }),
    publicClient.readContract({ address: VAULT, abi: vaultAbi, functionName: "guard" }),
  ]);

  if (vaultGuard.toLowerCase() !== GUARD.toLowerCase()) {
    return { act: false, reason: `vault trusts a different guard (${vaultGuard})` };
  }

  const [decimals, idle, paused, cooldown, cap, lastAt] = await Promise.all([
    publicClient.readContract({ address: asset, abi: erc20Abi, functionName: "decimals" }),
    publicClient.readContract({ address: asset, abi: erc20Abi, functionName: "balanceOf", args: [VAULT] }),
    publicClient.readContract({ address: GUARD, abi: guardAbi, functionName: "paused" }),
    publicClient.readContract({ address: GUARD, abi: guardAbi, functionName: "cooldown" }),
    publicClient.readContract({ address: GUARD, abi: guardAbi, functionName: "maxDeployPerCall" }),
    publicClient.readContract({ address: GUARD, abi: guardAbi, functionName: "lastActionAt", args: [VAULT] }),
  ]);

  if (paused) return { act: false, reason: "guard is paused" };

  const now = BigInt(Math.floor(Date.now() / 1000));
  if (lastAt !== 0n && now < lastAt + BigInt(cooldown)) {
    const wait = Number(lastAt + BigInt(cooldown) - now);
    return { act: false, reason: `cooling down, ${wait}s left` };
  }

  const target = (totalAssets * BigInt(bufferBps)) / 10_000n;
  const deployable = idle > target ? idle - target : 0n;
  const wouldDeploy = deployable > cap ? cap : deployable;

  const fmt = (v) => `${formatUnits(v, decimals)}`;
  const state = `idle=${fmt(idle)} buffer=${fmt(target)} deployable=${fmt(deployable)} cap=${fmt(cap)}`;

  if (wouldDeploy < MIN_DEPLOY) {
    return { act: false, reason: `below threshold (${fmt(wouldDeploy)} < ${fmt(MIN_DEPLOY)})`, state };
  }

  return { act: true, amount: wouldDeploy, state, fmt };
}

async function tick() {
  let decision;
  try {
    decision = await evaluate();
  } catch (err) {
    log("read failed:", err.shortMessage ?? err.message);
    return;
  }

  if (!decision.act) {
    log(`skip: ${decision.reason}${decision.state ? ` | ${decision.state}` : ""}`);
    return;
  }

  log(`allocate ${decision.fmt(decision.amount)} | ${decision.state}`);

  if (DRY_RUN) {
    log("dry run, not sending. set DRY_RUN=false to act.");
    return;
  }

  try {
    // Simulate first. The guard reverts on every limit it enforces, and finding
    // that out locally is free where finding it out on-chain is not.
    const { request } = await publicClient.simulateContract({
      address: GUARD,
      abi: guardAbi,
      functionName: "deployIdle",
      args: [VAULT],
      account,
    });
    const hash = await walletClient.writeContract(request);
    log("sent", hash);
    const receipt = await publicClient.waitForTransactionReceipt({ hash });
    log("mined in block", receipt.blockNumber, "status", receipt.status);
  } catch (err) {
    log("send failed:", err.shortMessage ?? err.message);
  }
}

async function main() {
  log(`keeper starting | vault=${VAULT} guard=${GUARD}`);
  log(`mode=${DRY_RUN ? "DRY RUN" : "LIVE"} poll=${POLL_MS}ms minDeploy=${MIN_DEPLOY}`);

  if (!DRY_RUN) {
    const registered = await publicClient.readContract({
      address: GUARD, abi: guardAbi, functionName: "isKeeper", args: [account.address],
    });
    log(`keeper address ${account.address} registered=${registered}`);
    if (!registered) {
      log("this address is not an allowed keeper; every call would revert. exiting.");
      process.exit(1);
    }
  }

  await tick();
  if (ONCE) return;

  setInterval(tick, POLL_MS);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
