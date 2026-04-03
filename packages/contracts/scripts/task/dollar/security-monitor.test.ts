import { evaluateLiquidityIncident, parseThresholdBps } from "./security-monitor";
import { describe, it } from "node:test";
import assert from "node:assert";

describe("evaluateLiquidityIncident", () => {
  it("triggers when drop exceeds threshold", () => {
    // 1000 USD -> 650 USD = 35% drop = 3500 bps > 3000
    const previous = 1_000_000_000_000_000_000_000n;
    const current = 650_000_000_000_000_000_000n;
    const result = evaluateLiquidityIncident(previous, current, 3000);
    assert.strictEqual(result.triggered, true);
    assert.strictEqual(result.dropBps, 3500);
  });

  it("does not trigger when drop is below threshold", () => {
    // 1000 USD -> 950 USD = 5% drop = 500 bps < 3000
    const previous = 1_000_000_000_000_000_000_000n;
    const current = 950_000_000_000_000_000_000n;
    const result = evaluateLiquidityIncident(previous, current, 3000);
    assert.strictEqual(result.triggered, false);
    assert.strictEqual(result.dropBps, 500);
  });

  it("does not trigger on zero previous total", () => {
    const result = evaluateLiquidityIncident(0n, 1_000_000_000_000_000_000n, 3000);
    assert.strictEqual(result.triggered, false);
    assert.strictEqual(result.dropBps, 0);
  });

  it("does not trigger when current >= previous (no drop)", () => {
    const previous = 1_000_000_000_000_000_000_000n;
    const current = 1_000_000_000_000_000_000_000n;
    const result = evaluateLiquidityIncident(previous, current, 3000);
    assert.strictEqual(result.triggered, false);
    assert.strictEqual(result.dropBps, 0);
  });

  it("triggers exactly at threshold", () => {
    // 1000 USD -> 700 USD = 30% drop = 3000 bps >= 3000
    const previous = 1_000_000_000_000_000_000_000n;
    const current = 700_000_000_000_000_000_000n;
    const result = evaluateLiquidityIncident(previous, current, 3000);
    assert.strictEqual(result.triggered, true);
    assert.strictEqual(result.dropBps, 3000);
  });
});

describe("parseThresholdBps", () => {
  it("accepts valid integer threshold", () => {
    assert.strictEqual(parseThresholdBps(3000), 3000);
    assert.strictEqual(parseThresholdBps(0), 0);
    assert.strictEqual(parseThresholdBps(10000), 10000);
  });

  it("rejects NaN", () => {
    assert.throws(() => parseThresholdBps("not-a-number"), /SECURITY_MONITOR_THRESHOLD_BPS must be an integer/);
  });

  it("rejects negative values", () => {
    assert.throws(() => parseThresholdBps(-1), /SECURITY_MONITOR_THRESHOLD_BPS must be an integer/);
  });

  it("rejects values above 10000", () => {
    assert.throws(() => parseThresholdBps(10001), /SECURITY_MONITOR_THRESHOLD_BPS must be an integer/);
  });

  it("rejects non-integer floats", () => {
    assert.throws(() => parseThresholdBps(3.5), /SECURITY_MONITOR_THRESHOLD_BPS must be an integer/);
  });
});
