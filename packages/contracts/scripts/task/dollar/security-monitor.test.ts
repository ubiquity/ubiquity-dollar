import test from "node:test";
import assert from "node:assert/strict";

import { evaluateLiquidityIncident } from "./security-monitor";

test("does not trigger when there is no previous baseline", () => {
  const result = evaluateLiquidityIncident(0n, 100n, 3000);
  assert.equal(result.triggered, false);
  assert.equal(result.dropBps, 0);
});

test("does not trigger when collateral balance increases", () => {
  const result = evaluateLiquidityIncident(1000n, 1200n, 3000);
  assert.equal(result.triggered, false);
  assert.equal(result.dropBps, 0);
});

test("does not trigger below threshold", () => {
  const result = evaluateLiquidityIncident(1000n, 750n, 3000);
  assert.equal(result.dropBps, 2500);
  assert.equal(result.triggered, false);
});

test("triggers at or above threshold", () => {
  const result = evaluateLiquidityIncident(1000n, 699n, 3000);
  assert.equal(result.dropBps, 3010);
  assert.equal(result.triggered, true);
});
