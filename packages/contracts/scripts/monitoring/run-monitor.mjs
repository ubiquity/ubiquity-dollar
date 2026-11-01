import { readFile, rename, writeFile } from "node:fs/promises";
import { setTimeout } from "node:timers/promises";
import { isAbsolute } from "node:path";
import { pathToFileURL } from "node:url";
import { monitorOnce, readSnapshot, sendTelegram } from "./liquidity-monitor.mjs";

function required(name) {
  if (!process.env[name]) throw new Error(`Missing ${name}`);
  return process.env[name];
}

function positiveInteger(name, fallback) {
  const value = process.env[name] ?? String(fallback);
  if (!/^[1-9]\d*$/.test(value) || !Number.isSafeInteger(Number(value))) throw new Error(`Invalid ${name}`);
  return Number(value);
}

export async function loadState(file, target) {
  let state;
  try {
    state = JSON.parse(await readFile(file, "utf8"));
  } catch (error) {
    if (error.code === "ENOENT") return { version: 1, target, incident: null };
    throw new Error("Unreadable monitor state; manual review required");
  }
  if (state?.version !== 1 || state.target !== target) throw new Error("Monitor state target mismatch");
  const incident = state.incident;
  if (
    incident !== null &&
    (!incident ||
      typeof incident.collateral !== "string" ||
      !incident.collateral ||
      !Number.isSafeInteger(incident.blockNumber) ||
      incident.blockNumber < 0 ||
      typeof incident.previous !== "string" ||
      !/^\d+$/.test(incident.previous) ||
      typeof incident.current !== "string" ||
      !/^\d+$/.test(incident.current) ||
      typeof incident.alerted !== "boolean" ||
      typeof incident.dollarPaused !== "boolean" ||
      typeof incident.poolPaused !== "boolean" ||
      typeof incident.lastReportedStatus !== "string" ||
      !/^(|(true|false)\/(true|false))$/.test(incident.lastReportedStatus))
  ) {
    throw new Error("Invalid incident state; manual review required");
  }
  return state;
}

export async function saveState(file, value) {
  const temporary = `${file}.${process.pid}.tmp`;
  await writeFile(temporary, JSON.stringify(value), { mode: 0o600 });
  await rename(temporary, file);
}

async function main() {
  const telegram = {
    token: required("MONITOR_TELEGRAM_BOT_TOKEN"),
    chatId: required("MONITOR_TELEGRAM_CHAT_ID"),
    topicId: process.env.MONITOR_TELEGRAM_TOPIC_ID ? positiveInteger("MONITOR_TELEGRAM_TOPIC_ID") : undefined,
  };
  const notify = (text) => sendTelegram(telegram, text);
  try {
    const rpcUrl = required("MONITOR_RPC_URL");
    const poolAddress = required("MONITOR_POOL_ADDRESS");
    const dollarAddress = required("MONITOR_DOLLAR_ADDRESS");
    const privateKey = required("MONITOR_PRIVATE_KEY");
    const stateFile = required("MONITOR_STATE_FILE");
    if (!isAbsolute(stateFile)) throw new Error("MONITOR_STATE_FILE must be absolute");
    const chainId = positiveInteger("MONITOR_CHAIN_ID", 1);
    const lookback = positiveInteger("MONITOR_LOOKBACK_BLOCKS", 300);
    const confirmations = positiveInteger("MONITOR_CONFIRMATIONS", 2);
    const pollMs = positiveInteger("MONITOR_POLL_MS", 15_000);
    const { Contract, FetchRequest, JsonRpcProvider, Wallet, getAddress, id } = await import("ethers");
    const request = new FetchRequest(rpcUrl);
    request.timeout = 10_000;
    const provider = new JsonRpcProvider(request);
    const signer = new Wallet(privateKey, provider);
    const pool = new Contract(
      getAddress(poolAddress),
      [
        "function allCollaterals() view returns (address[])",
        "function pausePool()",
        "function hasRole(bytes32,address) view returns (bool)",
        "function dollarTokenAddress() view returns (address)",
      ],
      signer
    );
    const dollar = new Contract(
      getAddress(dollarAddress),
      ["function paused() view returns (bool)", "function pause()", "function getManager() view returns (address)"],
      signer
    );
    if (
      (await provider.getNetwork()).chainId !== BigInt(chainId) ||
      getAddress(await dollar.getManager()) !== pool.target ||
      getAddress(await pool.dollarTokenAddress()) !== dollar.target ||
      !(await pool.hasRole(id("PAUSER_ROLE"), signer.address))
    ) {
      throw new Error("Wrong chain, contracts or missing PAUSER_ROLE");
    }
    // eth_call checks that the upgraded selector exists and the signer can use it.
    await pool.pausePool.staticCall();
    const target = `${chainId}:${pool.target}:${dollar.target}:${lookback}:${confirmations}`;
    const state = await loadState(stateFile, target);
    // Fail at startup rather than silently running without durable incident state.
    await saveState(stateFile, state);
    const confirm = async (transaction) => {
      const receipt = await transaction.wait(confirmations, 60_000);
      if (!receipt || receipt.status !== 1) throw new Error("Shutdown transaction not confirmed");
    };
    const readBalance = (collateral, blockTag) =>
      new Contract(collateral, ["function balanceOf(address) view returns (uint256)"], provider).balanceOf(pool.target, { blockTag });
    let unhealthy = false;
    let successful = false;
    for (;;) {
      try {
        const failures = await monitorOnce({
          state,
          readLiquidity: () => readSnapshot(provider, pool, readBalance, lookback, confirmations),
          pauseDollar: async () => {
            if (!(await dollar.paused())) await confirm(await dollar.pause());
          },
          pausePool: async () => confirm(await pool.pausePool()),
          notify,
          saveState: (value) => saveState(stateFile, value),
        });
        console.log(`${new Date().toISOString()} Dollar monitor: ${failures.length ? failures.join(", ") : "check complete"}`);
        successful = failures.length === 0;
        unhealthy = false;
      } catch {
        // Never log raw provider/HTTP errors: they can contain credentials.
        console.error("Dollar monitor: liquidity check failed; retrying");
        if (!unhealthy) {
          unhealthy = await notify(`Dollar monitoring degraded: liquidity check failed.\nTarget: ${target}\nCheck RPC/archive availability immediately.`).then(
            () => true,
            () => false
          );
        }
        successful = false;
      }
      if (process.argv.includes("--once")) {
        if (!successful) process.exitCode = 1;
        break;
      }
      await setTimeout(pollMs);
    }
  } catch {
    await notify("Dollar monitoring STOPPED during startup. Check configuration, permissions, upgraded pool selector and state file immediately.").catch(
      () => {}
    );
    throw new Error("Dollar monitor startup failed (sensitive error details suppressed)");
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch(() => {
    console.error("Dollar monitor stopped; check required MONITOR_* configuration and RPC connectivity. No credentials were logged.");
    process.exitCode = 1;
  });
}
