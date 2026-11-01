import assert from "node:assert/strict";
import test from "node:test";
import { mkdtemp, readdir, readFile, rm, stat, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { setImmediate } from "node:timers/promises";
import { loadState, saveState } from "./run-monitor.mjs";
import { isLiquidityIncident, monitorOnce, readSnapshot, sendTelegram } from "./liquidity-monitor.mjs";

function fixture(previous = 100n, current = 69n) {
  const calls = [];
  let persisted;
  const options = {
    state: { version: 1, target: "test-pool", incident: null },
    readLiquidity: () => {
      calls.push("read");
      return Promise.resolve([{ collateral: "test-collateral", blockNumber: 500, previous, current }]);
    },
    pauseDollar: () => Promise.resolve(calls.push("dollar")),
    pausePool: () => Promise.resolve(calls.push("pool")),
    notify: (text) => Promise.resolve(calls.push(text)),
    saveState: (state) => {
      persisted = JSON.parse(JSON.stringify(state));
      calls.push("save");
      return Promise.resolve();
    },
  };
  return { options, calls, persisted: () => persisted };
}

const unavailable = () => Promise.reject(new Error("unavailable"));

test("strict 30% threshold, zero baseline, increases and large E18 values", () => {
  assert.equal(isLiquidityIncident(100n, 70n), false);
  assert.equal(isLiquidityIncident(100n, 71n), false);
  assert.equal(isLiquidityIncident(100n, 69n), true);
  assert.equal(isLiquidityIncident(0n, 0n), false);
  assert.equal(isLiquidityIncident(0n, 100n), false);
  assert.equal(isLiquidityIncident(100n, 101n), false);
  assert.equal(isLiquidityIncident(100n, 0n), true);
  const baseline = 10n ** 30n;
  assert.equal(isLiquidityIncident(baseline, (baseline * 7n) / 10n), false);
  assert.equal(isLiquidityIncident(baseline, (baseline * 7n) / 10n - 1n), true);
  assert.throws(() => isLiquidityIncident(-1n, 0n), RangeError);
  assert.throws(() => isLiquidityIncident(100, 69), RangeError);
});

test("snapshots compare raw collateral over a fixed historical window at confirmed block tags", async () => {
  const tags = [];
  const provider = { getBlockNumber: () => Promise.resolve(1000) };
  const pool = {
    allCollaterals: ({ blockTag }) => {
      assert.equal(blockTag, 698);
      return Promise.resolve(["first", "second"]);
    },
    collateralUsdBalance: unavailable, // An insolvent free-balance getter must not hide theft.
  };
  const readBalance = (collateral, blockTag) => {
    tags.push([collateral, blockTag]);
    return Promise.resolve(blockTag === 698 ? 100n : collateral === "first" ? 69n : 100n);
  };
  assert.deepEqual(await readSnapshot(provider, pool, readBalance, 300, 2), [
    { collateral: "first", blockNumber: 998, previous: 100n, current: 69n },
    { collateral: "second", blockNumber: 998, previous: 100n, current: 100n },
  ]);
  assert.deepEqual(tags, [["first", 698], ["first", 998], ["second", 698], ["second", 998]]);
  await assert.rejects(readSnapshot(provider, pool, readBalance, 1000, 2), /Insufficient block history/);
  await assert.rejects(readSnapshot(provider, pool, unavailable, 300, 2));
});

test("healthy pools do not pause or send alerts", async () => {
  for (const current of [70n, 90n, 110n]) {
    const { options, calls } = fixture(100n, current);
    assert.deepEqual(await monitorOnce(options), []);
    assert.deepEqual(calls, ["read"]);
    assert.equal(options.state.incident, null);
  }
});

test("incidents persist before side effects, pause both targets, and alert once", async () => {
  const { options, calls, persisted } = fixture();
  assert.deepEqual(await monitorOnce(options), []);
  assert.deepEqual(calls.slice(0, 2), ["read", "save"]);
  assert.ok(calls[2].startsWith("DOLLAR SECURITY INCIDENT"));
  assert.ok(calls[2].includes("100 -> 69"));
  assert.ok(calls.includes("dollar"));
  assert.ok(calls.includes("pool"));
  assert.ok(calls.some((call) => call.includes("confirmed disabled")));
  assert.equal(persisted().incident.lastReportedStatus, "true/true");
  const before = calls.length;
  await monitorOnce(options);
  assert.deepEqual(calls.slice(before), ["save"]);
});

test("Dollar failure does not block pool shutdown; restart retries despite liquidity recovery", async () => {
  const { options, calls, persisted } = fixture();
  options.pauseDollar = unavailable;
  assert.deepEqual(await monitorOnce(options), ["dollarPaused"]);
  assert.ok(calls.includes("pool"));
  assert.ok(calls.some((call) => call.includes("UNCONFIRMED; retrying")));
  assert.equal(persisted().incident.dollarPaused, false);
  options.state = persisted();
  options.readLiquidity = unavailable;
  options.pausePool = unavailable; // Already confirmed; must not call again.
  options.pauseDollar = () => Promise.resolve(calls.push("retry-dollar"));
  const before = calls.length;
  assert.deepEqual(await monitorOnce(options), []);
  assert.ok(calls.slice(before).includes("retry-dollar"));
  assert.equal(persisted().incident.lastReportedStatus, "true/true");
});

test("pool failure does not undo token pause and only the pool action is retried", async () => {
  const { options, calls } = fixture();
  options.pausePool = unavailable;
  assert.deepEqual(await monitorOnce(options), ["poolPaused"]);
  assert.equal(options.state.incident.dollarPaused, true);
  options.pauseDollar = unavailable;
  options.pausePool = () => Promise.resolve(calls.push("retry-pool"));
  assert.deepEqual(await monitorOnce(options), []);
  assert.ok(calls.includes("retry-pool"));
});

test("Telegram outages do not block shutdown and notifications retry after restart", async () => {
  const { options, calls, persisted } = fixture();
  options.notify = unavailable;
  assert.deepEqual(await monitorOnce(options), ["incident notification", "status notification"]);
  assert.ok(calls.includes("dollar"));
  assert.ok(calls.includes("pool"));
  options.state = persisted();
  options.notify = (text) => Promise.resolve(calls.push(text));
  options.readLiquidity = unavailable;
  options.pauseDollar = unavailable;
  options.pausePool = unavailable;
  assert.deepEqual(await monitorOnce(options), []);
  assert.equal(persisted().incident.alerted, true);
  assert.equal(persisted().incident.lastReportedStatus, "true/true");
});

test("disk failures do not block emergency actions", async () => {
  const { options, calls } = fixture();
  options.saveState = unavailable;
  const failures = await monitorOnce(options);
  assert.ok(failures.includes("state persistence"));
  assert.ok(calls.includes("dollar"));
  assert.ok(calls.includes("pool"));
});

test("read failures do not manufacture a zero balance or pause a healthy pool", async () => {
  const { options, calls } = fixture();
  options.readLiquidity = unavailable;
  await assert.rejects(monitorOnce(options));
  assert.equal(options.state.incident, null);
  assert.deepEqual(calls, []);
});

test("repeated failed responses do not spam unchanged shutdown status", async () => {
  const { options, calls } = fixture();
  options.pauseDollar = unavailable;
  options.pausePool = unavailable;
  await monitorOnce(options);
  const before = calls.length;
  await monitorOnce(options);
  assert.deepEqual(calls.slice(before), ["save"]);
});

test("Telegram includes the configured forum topic and checks API-level failures", async () => {
  const config = { token: "test-token", chatId: "-100123", topicId: 42 };
  await sendTelegram(config, "test alert", (url, request) => {
    assert.equal(url, "https://api.telegram.org/bottest-token/sendMessage");
    assert.equal(request.method, "POST");
    assert.deepEqual(JSON.parse(request.body), { chat_id: "-100123", message_thread_id: 42, text: "test alert" });
    assert.ok(request.signal instanceof AbortSignal);
    return Promise.resolve({ ok: true, json: () => Promise.resolve({ ok: true }) });
  });
  for (const response of [{ ok: false }, { ok: true, json: () => Promise.resolve({ ok: false }) }]) {
    await assert.rejects(sendTelegram(config, "test alert", () => Promise.resolve(response)), /Telegram notification failed/);
  }
  await sendTelegram({ token: "test-token", chatId: "-100123" }, "no topic", (_url, request) => {
    assert.equal("message_thread_id" in JSON.parse(request.body), false);
    return Promise.resolve({ ok: true, json: () => Promise.resolve({ ok: true }) });
  });
});

test("incident state survives atomic file writes, is private, and rejects invalid targets/data", async (t) => {
  const directory = await mkdtemp(join(process.cwd(), ".monitor-test-"));
  t.after(() => rm(directory, { recursive: true, force: true }));
  const file = join(directory, "state.json");
  const initial = { version: 1, target: "test-pool", incident: null };
  assert.deepEqual(await loadState(file, initial.target), initial);
  const { options } = fixture();
  options.saveState = (state) => saveState(file, state);
  await monitorOnce(options);
  assert.deepEqual(await loadState(file, initial.target), options.state);
  assert.equal((await stat(file)).mode & 0o777, 0o600);
  assert.deepEqual(await readdir(directory), ["state.json"]);
  await assert.rejects(loadState(file, "another-pool"), /target mismatch/);
  const invalid = JSON.parse(await readFile(file, "utf8"));
  invalid.incident.poolPaused = "true";
  await writeFile(file, JSON.stringify(invalid));
  await assert.rejects(loadState(file, initial.target), /Invalid incident state/);
  await writeFile(file, "not json");
  await assert.rejects(loadState(file, initial.target), /Unreadable monitor state/);
});

test("a drained collateral triggers shutdown even when another collateral grows", async () => {
  const { options } = fixture();
  options.readLiquidity = () =>
    Promise.resolve([
      { collateral: "growing", blockNumber: 500, previous: 1000n, current: 2000n },
      { collateral: "drained", blockNumber: 500, previous: 100n, current: 0n },
    ]);
  await monitorOnce(options);
  assert.equal(options.state.incident.collateral, "drained");
  assert.equal(options.state.incident.poolPaused, true);
});

test("a pending Telegram request never delays pool or Dollar shutdown", async () => {
  const { options, calls } = fixture();
  let releaseAlert;
  const delayed = new Promise((resolve) => {
    releaseAlert = resolve;
  });
  let notifications = 0;
  options.notify = () => ++notifications === 1 ? delayed : Promise.resolve();
  const pending = monitorOnce(options);
  await setImmediate();
  assert.ok(calls.includes("pool"));
  assert.ok(calls.includes("dollar"));
  assert.ok(calls.indexOf("pool") < calls.indexOf("dollar"));
  releaseAlert();
  assert.deepEqual(await pending, []);
});
