# Formal Verification: LibUbiquityPool

## Overview
This directory contains formal verification specifications for the `LibUbiquityPool` library, which handles collateral deposits, dollar minting, and dollar redemption.

## Verification Tools

### 1. Certora Prover
Located in `certora/`:
- `specs/LibUbiquityPool.spec` — Formal specification with invariants and rules
- `conf/LibUbiquityPool.conf` — Certora configuration

**Invariants verified:**
- Dollar supply consistency (mint increases, burn decreases)
- Collateral balance preservation (no token loss)
- Collateral ratio bounds (0 to 1,000,000)
- No overdraft (pool never gives more than it holds)

**Rules verified:**
- `mintDollarCorrectOutput` — Correct dollar output for collateral input
- `redeemDollarCorrectOutput` — Correct collateral output for dollar input
- `noReentrancyMint` — No reentrancy in minting
- `collectCollateralBounded` — Collateral collection bounded correctly

### 2. Halmos Symbolic Tests
Located in `packages/contracts/test/formal/`:
- `LibUbiquityPoolHalmos.t.sol` — Symbolic tests with Halmos

**Properties tested:**
- Mint always increases supply
- Burn always decreases supply
- Collateral ratio bounded
- No negative balances
- Transfer preserves total supply

## Running

```bash
# Certora
certoraRun certora/conf/LibUbiquityPool.conf

# Halmos
halmos --contract LibUbiquityPoolHalmosTest
```

## Results
All invariants and rules are designed to pass. Any violations indicate potential bugs in the pool implementation.
