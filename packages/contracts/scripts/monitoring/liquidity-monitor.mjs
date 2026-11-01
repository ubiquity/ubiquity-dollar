/**
 * @typedef {{collateral: string, blockNumber: number, previous: bigint, current: bigint}} Snapshot
 * @typedef {{collateral: string, blockNumber: number, previous: string, current: string, alerted: boolean,
 * dollarPaused: boolean, poolPaused: boolean, lastReportedStatus: string}} Incident
 * @typedef {{version: number, target: string, incident: Incident | null}} MonitorState
 */

/**
 * Compare native token amounts without rounding at the 30% boundary.
 * @param {bigint} previous
 * @param {bigint} current
 */
export function isLiquidityIncident(previous, current) {
  if (typeof previous !== "bigint" || typeof current !== "bigint" || previous < 0n || current < 0n) {
    throw new RangeError("Liquidity must be non-negative bigint amounts");
  }
  return previous > 0n && (previous - current) * 100n > previous * 30n;
}

/**
 * @param {{getBlockNumber: () => Promise<number>}} provider
 * @param {{allCollaterals: (options: {blockTag: number}) => Promise<string[]>}} pool
 * @param {(collateral: string, blockTag: number) => Promise<bigint>} readBalance
 * @param {number} lookbackBlocks
 * @param {number} confirmations
 * @returns {Promise<Snapshot[]>}
 */
export async function readSnapshot(provider, pool, readBalance, lookbackBlocks, confirmations) {
  const blockNumber = (await provider.getBlockNumber()) - confirmations;
  const previousBlock = blockNumber - lookbackBlocks;
  if (previousBlock < 0) throw new Error("Insufficient block history");
  // Use actual token balances: the free-USD getter can underflow after theft
  // below pending redemptions. Ratios per asset need no price/decimal conversion.
  const collaterals = await pool.allCollaterals({ blockTag: previousBlock });
  return Promise.all(
    collaterals.map(async (collateral) => {
      const [previous, current] = await Promise.all([readBalance(collateral, previousBlock), readBalance(collateral, blockNumber)]);
      return { collateral, blockNumber, previous, current };
    })
  );
}

/**
 * All effects are injected so the incident/retry logic can be tested offline.
 * @param {{state: MonitorState, readLiquidity: () => Promise<Snapshot[]>,
 * pauseDollar: () => Promise<unknown>, pausePool: () => Promise<unknown>,
 * notify: (text: string) => Promise<unknown>, saveState: (state: MonitorState) => Promise<unknown>}} options
 */
export async function monitorOnce({ state, readLiquidity, pauseDollar, pausePool, notify, saveState }) {
  /** @type {string[]} */
  const failures = [];
  const remember = async () => {
    try {
      await saveState(state);
    } catch {
      failures.push("state persistence");
    }
  };
  if (!state.incident) {
    const snapshots = await readLiquidity();
    const snapshot = snapshots.find(({ previous, current }) => isLiquidityIncident(previous, current));
    if (!snapshot) return failures;
    state.incident = {
      collateral: snapshot.collateral,
      blockNumber: snapshot.blockNumber,
      previous: snapshot.previous.toString(),
      current: snapshot.current.toString(),
      alerted: false,
      dollarPaused: false,
      poolPaused: false,
      lastReportedStatus: "",
    };
    await remember();
  }

  // An incident is latched across polls/restarts, even if liquidity recovers.
  const incident = state.incident;
  const details =
    `Target: ${state.target}\nCollateral: ${incident.collateral}\nBlock: ${incident.blockNumber}\nBalance (native units): ${incident.previous} -> ${incident.current}`;
  // Start the alert immediately, but never wait for Telegram before shutdown.
  // Only the main path persists state, avoiding concurrent file writes.
  const alert = (async () => {
    if (!incident.alerted) {
      try {
        await notify(`DOLLAR SECURITY INCIDENT: liquidity loss exceeds 30%.\n${details}\nEmergency shutdown requested.`);
        incident.alerted = true;
      } catch {
        failures.push("incident notification");
      }
    }
  })();

  // Neither a failed notification nor one failed transaction blocks the other action.
  /** @type {Array<["dollarPaused" | "poolPaused", () => Promise<unknown>]>} */
  const actions = [
    ["poolPaused", pausePool],
    ["dollarPaused", pauseDollar],
  ];
  for (const [key, pause] of actions) {
    if (!incident[key]) {
      try {
        await pause();
        incident[key] = true;
        await remember();
      } catch {
        failures.push(key);
      }
    }
  }

  await alert;
  const status = `${incident.dollarPaused}/${incident.poolPaused}`;
  if (status !== incident.lastReportedStatus) {
    try {
      await notify(
        `Dollar emergency shutdown status.\n${details}\nDollar: ${incident.dollarPaused ? "confirmed paused" : "UNCONFIRMED; retrying"}.\nPool collateral: ${
          incident.poolPaused ? "confirmed disabled" : "UNCONFIRMED; retrying"
        }.\nManual investigation and recovery required.`
      );
      incident.lastReportedStatus = status;
      await remember();
    } catch {
      failures.push("status notification");
    }
  }
  // Retry persistence even when all on-chain actions already succeeded.
  await remember();
  return failures;
}

/**
 * @param {{token: string, chatId: string, topicId?: number}} config
 * @param {string} text
 * @param {typeof fetch} [fetchImpl]
 */
export async function sendTelegram({ token, chatId, topicId }, text, fetchImpl = fetch) {
  const body = { chat_id: chatId, text, ...(topicId === undefined ? {} : { message_thread_id: topicId }) };
  const response = await fetchImpl(`https://api.telegram.org/bot${token}/sendMessage`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(10_000),
  });
  if (!response.ok || (await response.json()).ok !== true) throw new Error("Telegram notification failed");
}
