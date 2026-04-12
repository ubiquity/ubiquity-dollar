import fs from "fs";
import path from "path";
import { OptionDefinition } from "command-line-args";
import { ethers } from "ethers";

import { TaskFuncParam } from "../../shared";

export const optionDefinitions: OptionDefinition[] = [
  { name: "task", defaultOption: true },
  { name: "network", alias: "n", type: String },
  { name: "thresholdBps", alias: "t", type: Number },
  { name: "stateFile", alias: "s", type: String },
  { name: "dryrun", alias: "d", type: Boolean },
];

type MonitorState = {
  lastTotalCollateralUsd: string;
  lastObservedAt: string;
};

type IncidentEvaluation = {
  triggered: boolean;
  dropBps: number;
  previousTotal: bigint;
  currentTotal: bigint;
};

type MonitorConfig = {
  diamondAddress: string;
  dollarTokenAddress: string;
  thresholdBps: number;
  stateFilePath: string;
  dryrun: boolean;
  webhookUrl?: string;
  telegramBotToken?: string;
  telegramChatId?: string;
  telegramThreadId?: string;
};

const POOL_ABI = [
  "function allCollaterals() view returns (address[])",
  "function collateralUsdBalance() view returns (uint256)",
  "function collateralInformation(address) view returns (tuple(uint256 index,string symbol,address collateralAddress,address collateralPriceFeedAddress,uint256 collateralPriceFeedStalenessThreshold,bool isEnabled,uint256 missingDecimals,uint256 price,uint256 poolCeiling,bool isMintPaused,bool isRedeemPaused,bool isBorrowPaused,uint256 mintingFee,uint256 redemptionFee))",
  "function toggleCollateral(uint256 collateralIndex)",
  "function toggleMintRedeemBorrow(uint256 collateralIndex,uint8 toggleIndex)",
] as const;

const DOLLAR_ABI = ["function paused() view returns (bool)", "function pause()"] as const;

type CollateralInfo = {
  index: bigint;
  symbol: string;
  collateralAddress: string;
  isEnabled: boolean;
  isMintPaused: boolean;
  isRedeemPaused: boolean;
  isBorrowPaused: boolean;
};

/**
 * Evaluate whether a collateral liquidity drop constitutes an incident.
 *
 * @param previousTotal - The collateral USD balance from the prior observation.
 * @param currentTotal  - The current collateral USD balance.
 * @param thresholdBps  - Drop size in basis points required to trigger an incident.
 * @returns Incident evaluation with trigger flag, drop size, and raw totals.
 */
export const evaluateLiquidityIncident = (previousTotal: bigint, currentTotal: bigint, thresholdBps: number): IncidentEvaluation => {
  if (previousTotal <= 0n) {
    return { triggered: false, dropBps: 0, previousTotal, currentTotal };
  }

  if (currentTotal >= previousTotal) {
    return { triggered: false, dropBps: 0, previousTotal, currentTotal };
  }

  const drop = previousTotal - currentTotal;
  const dropBps = Number((drop * 10_000n) / previousTotal);
  return {
    triggered: dropBps >= thresholdBps,
    dropBps,
    previousTotal,
    currentTotal,
  };
};

const formatUsd18 = (value: bigint) => ethers.formatUnits(value, 18);

const readState = (stateFilePath: string): MonitorState | null => {
  if (!fs.existsSync(stateFilePath)) {
    return null;
  }

  const raw = fs.readFileSync(stateFilePath, "utf-8");
  return JSON.parse(raw) as MonitorState;
};

const writeState = (stateFilePath: string, currentTotal: bigint) => {
  const state: MonitorState = {
    lastTotalCollateralUsd: currentTotal.toString(),
    lastObservedAt: new Date().toISOString(),
  };

  const dirname = path.dirname(stateFilePath);
  fs.mkdirSync(dirname, { recursive: true });
  fs.writeFileSync(stateFilePath, JSON.stringify(state, null, 2));
};

const DEFAULT_TIMEOUT_MS = 10_000;

/**
 * POST JSON payload to a URL with a fixed timeout.
 *
 * @param url - The destination URL.
 * @param payload - The JSON-serializable body.
 * @throws Error - When the response is non-OK or the request times out.
 */
const postJson = async (url: string, payload: Record<string, unknown>): Promise<void> => {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), DEFAULT_TIMEOUT_MS);
  try {
    const response = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });

    if (!response.ok) {
      const text = await response.text();
      throw new Error(`Webhook request failed with ${response.status}: ${text}`);
    }
  } finally {
    clearTimeout(timeout);
  }
};

/**
 * Send incident notifications via all configured channels (webhook, Telegram).
 * Throws if any notification delivery fails, so the caller does not silently
 * report success when alerts were not actually delivered.
 *
 * @param config - Monitor configuration containing channel credentials.
 * @param message - Summary text for the alert.
 * @param details - Structured data to include in the alert payload.
 * @throws Error - When any notification request fails or times out.
 */
const sendNotifications = async (config: MonitorConfig, message: string, details: Record<string, unknown>): Promise<void> => {
  const tasks: Promise<void>[] = [];

  if (config.webhookUrl) {
    tasks.push(
      postJson(config.webhookUrl, {
        source: "ubiquity-dollar-security-monitor",
        text: message,
        details,
        timestamp: new Date().toISOString(),
      })
    );
  }

  if (config.telegramBotToken && config.telegramChatId) {
    const payload: Record<string, string> = {
      chat_id: config.telegramChatId,
      text: `${message}\n\n${JSON.stringify(details, null, 2)}`,
    };

    if (config.telegramThreadId) {
      payload.message_thread_id = config.telegramThreadId;
    }

    tasks.push(postJson(`https://api.telegram.org/bot${config.telegramBotToken}/sendMessage`, payload));
  }

  if (tasks.length === 0) {
    return;
  }

  const results = await Promise.allSettled(tasks);
  const failures = results.filter((r): r is PromiseRejectedResult => r.status === "rejected");
  if (failures.length > 0) {
    const messages = failures.map((f) => f.reason?.message ?? f.reason);
    throw new Error(`[security-monitor] ${failures.length}/${tasks.length} notification(s) failed: ${messages.join("; ")}`);
  }
};

/**
 * Parse and validate the threshold basis-points setting.
 * Accepts a raw value from CLI args or environment variable.
 *
 * @param raw - The unparsed numeric value.
 * @returns The validated threshold as an integer in basis points.
 * @throws Error - When the value is not an integer between 0 and 10_000.
 */
export const parseThresholdBps = (raw: unknown): number => {
  const value = Number(raw);
  if (!Number.isInteger(value) || value < 0 || value > 10_000) {
    throw new Error(`SECURITY_MONITOR_THRESHOLD_BPS must be an integer in [0, 10000], got: ${raw}`);
  }
  return value;
};

/**
 * Build a validated MonitorConfig from CLI arguments and environment variables.
 *
 * @param params - The task function parameters containing CLI args and environment.
 * @returns A fully-populated MonitorConfig ready for use by the monitor loop.
 * @throws Error - When required environment variables (diamond / token address) are missing.
 */
const getConfig = (params: TaskFuncParam): MonitorConfig => {
  const { args } = params;
  const thresholdBps = parseThresholdBps(args.thresholdBps ?? process.env.SECURITY_MONITOR_THRESHOLD_BPS ?? 3000);
  const stateFilePath = args.stateFile ?? process.env.SECURITY_MONITOR_STATE_FILE ?? path.join(process.cwd(), "monitoring", "security-monitor-state.json");

  // cspell: disable-next-line
  const diamondAddress = process.env.UBQ_DIAMOND_ADDRESS;
  // cspell: disable-next-line
  const dollarTokenAddress = process.env.UBQ_DOLLAR_TOKEN_ADDRESS;

  if (!diamondAddress) {
    // cspell: disable-next-line
    throw new Error("Missing UBQ_DIAMOND_ADDRESS in environment");
  }

  if (!dollarTokenAddress) {
    // cspell: disable-next-line
    throw new Error("Missing UBQ_DOLLAR_TOKEN_ADDRESS in environment");
  }

  return {
    diamondAddress,
    dollarTokenAddress,
    thresholdBps,
    stateFilePath,
    dryrun: Boolean(args.dryrun),
    webhookUrl: process.env.SECURITY_MONITOR_WEBHOOK_URL,
    telegramBotToken: process.env.SECURITY_MONITOR_TELEGRAM_BOT_TOKEN,
    telegramChatId: process.env.SECURITY_MONITOR_TELEGRAM_CHAT_ID,
    telegramThreadId: process.env.SECURITY_MONITOR_TELEGRAM_THREAD_ID,
  };
};

type PoolContract = {
  collateralInformation: (collateralAddress: string) => Promise<CollateralInfo>;
  connect: (signer: ethers.Wallet) => {
    toggleCollateral: (collateralIndex: number) => Promise<{ hash: string; wait: (confirmations: number) => Promise<void> }>;
    toggleMintRedeemBorrow: (collateralIndex: number, toggleIndex: number) => Promise<{ hash: string; wait: (confirmations: number) => Promise<void> }>;
  };
};

type DollarContract = {
  paused: () => Promise<boolean>;
  connect: (signer: ethers.Wallet) => {
    pause: () => Promise<{ hash: string; wait: (confirmations: number) => Promise<void> }>;
  };
};

const executeProtection = async (
  signer: ethers.Wallet,
  poolContract: PoolContract,
  dollarContract: DollarContract,
  collaterals: string[],
  dryrun: boolean
): Promise<string[]> => {
  const txHashes: string[] = [];

  const isDollarPaused = (await dollarContract.paused()) as boolean;
  if (!isDollarPaused) {
    if (dryrun) {
      txHashes.push("dryrun:dollar.pause()");
    } else {
      const tx = await dollarContract.connect(signer).pause();
      await tx.wait(1);
      txHashes.push(tx.hash);
    }
  }

  for (const collateralAddress of collaterals) {
    const info = (await poolContract.collateralInformation(collateralAddress)) as CollateralInfo;
    const index = Number(info.index);

    if (info.isEnabled) {
      if (dryrun) {
        txHashes.push(`dryrun:pool.toggleCollateral(${index})`);
      } else {
        const tx = await poolContract.connect(signer).toggleCollateral(index);
        await tx.wait(1);
        txHashes.push(tx.hash);
      }
    }

    const pauseToggles: Array<{ isPaused: boolean; toggleIndex: number }> = [
      { isPaused: info.isMintPaused, toggleIndex: 0 },
      { isPaused: info.isRedeemPaused, toggleIndex: 1 },
      { isPaused: info.isBorrowPaused, toggleIndex: 2 },
    ];

    for (const pauseToggle of pauseToggles) {
      if (pauseToggle.isPaused) {
        continue;
      }

      if (dryrun) {
        txHashes.push(`dryrun:pool.toggleMintRedeemBorrow(${index},${pauseToggle.toggleIndex})`);
      } else {
        const tx = await poolContract.connect(signer).toggleMintRedeemBorrow(index, pauseToggle.toggleIndex);
        await tx.wait(1);
        txHashes.push(tx.hash);
      }
    }
  }

  return txHashes;
};

/**
 * Top-level monitor task function.
 *
 * Reads the last known total collateral USD from the state file, compares it to the
 * current on-chain value, evaluates whether a liquidity-drop incident has occurred, and
 * — if so — executes on-chain protections (pause dollar, toggle collateral) and sends
 * notifications to all configured channels.  Throws if any notification delivery fails
 * so that the caller does not silently report success when alerts were not delivered.
 *
 * @param params - Task function parameters ({ env, args }).
 * @returns "initialized_baseline" on first run; "ok_drop_bps=N" when no incident; or a
 *          JSON string describing the executed transactions on incident trigger.
 */
const func = async (params: TaskFuncParam) => {
  const config = getConfig(params);

  const provider = new ethers.JsonRpcProvider(params.env.rpcUrl);
  const adminKey = process.env.ADMIN_PRIVATE_KEY ?? params.env.privateKey;
  if (!adminKey) {
    throw new Error("Missing ADMIN_PRIVATE_KEY (or PRIVATE_KEY) environment variable");
  }
  const signer = new ethers.Wallet(adminKey, provider);

  const poolContract = new ethers.Contract(config.diamondAddress, POOL_ABI, signer) as unknown as PoolContract & {
    collateralUsdBalance: () => Promise<bigint>;
    allCollaterals: () => Promise<string[]>;
  };
  const dollarContract = new ethers.Contract(config.dollarTokenAddress, DOLLAR_ABI, signer) as unknown as DollarContract;

  const currentTotalCollateralUsd = (await poolContract.collateralUsdBalance()) as bigint;
  const state = readState(config.stateFilePath);

  if (!state) {
    writeState(config.stateFilePath, currentTotalCollateralUsd);
    return "initialized_baseline";
  }

  const evaluation = evaluateLiquidityIncident(BigInt(state.lastTotalCollateralUsd), currentTotalCollateralUsd, config.thresholdBps);

  if (!evaluation.triggered) {
    writeState(config.stateFilePath, currentTotalCollateralUsd);
    return `ok_drop_bps=${evaluation.dropBps}`;
  }

  const collaterals = (await poolContract.allCollaterals()) as string[];
  const txHashes = await executeProtection(signer, poolContract, dollarContract, collaterals, config.dryrun);

  const details = {
    thresholdBps: config.thresholdBps,
    dropBps: evaluation.dropBps,
    previousTotalCollateralUsd: formatUsd18(evaluation.previousTotal),
    currentTotalCollateralUsd: formatUsd18(evaluation.currentTotal),
    dryrun: config.dryrun,
    diamondAddress: config.diamondAddress,
    dollarTokenAddress: config.dollarTokenAddress,
    txHashes,
  };

  await sendNotifications(config, "⚠️ Ubiquity security monitor incident detected and protections executed.", details);

  writeState(config.stateFilePath, currentTotalCollateralUsd);

  return JSON.stringify(details);
};

export default func;
