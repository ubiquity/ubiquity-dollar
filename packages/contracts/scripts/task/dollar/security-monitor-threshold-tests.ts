/**
 * Boundary test: exact-threshold case (dropBps === thresholdBps)
 * Run: node --import=tsx --test scripts/task/dollar/security-monitor-boundary.test.ts
 */

import { evaluateLiquidityIncident, parseThresholdBps } from "./security-monitor.js";
import { describe, it } from "node:test";
import assert from "node:assert";

// ---------------------------------------------------------------------------
// evaluateLiquidityIncident — exact-threshold boundary (dropBps === thresholdBps)
// ---------------------------------------------------------------------------

const PREVIOUS_TOTAL = 10_000_000_000_000_000_000n; // 10 ETH * 10**18

describe("evaluateLiquidityIncident — exact threshold boundary", () => {
  /**
   * Exact-threshold: drop is precisely 3000 bps = thresholdBps.
   * triggered MUST be true (>= comparison, so equal qualifies as an incident).
   */
  it("exact threshold (dropBps === thresholdBps) triggers incident", () => {
    // Previous: 10 ETH, Current: 7 ETH → 30% drop = 3000 bps
    const currentTotal = 7_000_000_000_000_000_000n; // 7 ETH
    const thresholdBps = 3000;

    const result = evaluateLiquidityIncident(PREVIOUS_TOTAL, currentTotal, thresholdBps);

    assert.strictEqual(
      result.triggered,
      true,
      `Expected triggered=true when dropBps (${result.dropBps}) === thresholdBps (${thresholdBps}); got triggered=${result.triggered}`
    );
    assert.strictEqual(result.dropBps, 3000, `Expected dropBps=3000, got dropBps=${result.dropBps}`);
  });

  /**
   * Just below threshold: drop is 2999 bps < thresholdBps.
   * triggered MUST be false.
   */
  it("just below threshold does NOT trigger", () => {
    // Previous: 10 ETH, Current: 7.001 ETH → drop = 2999 bps
    const prev = 10_000_000_000_000_000_000n;
    const curr = 7_001_000_000_000_000_000n;
    const thresholdBps = 3000;

    const result = evaluateLiquidityIncident(prev, curr, thresholdBps);

    assert.strictEqual(
      result.triggered,
      false,
      `Expected triggered=false when dropBps (${result.dropBps}) < thresholdBps (${thresholdBps}); got triggered=${result.triggered}`
    );
  });

  /**
   * Just above threshold: drop is 3001 bps > thresholdBps.
   * triggered MUST be true.
   */
  it("just above threshold triggers", () => {
    // Previous: 10 ETH, Current: 6.999 ETH → drop = 3001 bps
    const prev = 10_000_000_000_000_000_000n;
    const curr = 6_999_000_000_000_000_000n;
    const thresholdBps = 3000;

    const result = evaluateLiquidityIncident(prev, curr, thresholdBps);

    assert.strictEqual(
      result.triggered,
      true,
      `Expected triggered=true when dropBps (${result.dropBps}) > thresholdBps (${thresholdBps}); got triggered=${result.triggered}`
    );
  });
});

describe("parseThresholdBps — boundary values", () => {
  it("minimum valid (0 bps)", () => {
    assert.strictEqual(parseThresholdBps(0), 0);
  });

  it("maximum valid (10000 bps)", () => {
    assert.strictEqual(parseThresholdBps(10000), 10000);
  });

  it("rejects negative", () => {
    assert.throws(() => parseThresholdBps(-1), /must be an integer/);
  });

  it("rejects > 10000", () => {
    assert.throws(() => parseThresholdBps(10001), /must be an integer/);
  });
});
