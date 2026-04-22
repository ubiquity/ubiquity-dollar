# Formal Verification — LibUbiquityPool

## Overview

This directory contains formal verification for `LibUbiquityPool`, verifying critical invariants that must hold under all conditions.

## Verification Methods

### 1. Foundry Invariant/Fuzz Tests
Location: `packages/contracts/test/formal/LibUbiquityPoolInvariant.t.sol`

Uses Foundry's built-in fuzz testing to verify:
- **Token Conservation**: Total supply always equals sum of balances
- **Collateral Ratio**: Ratio preserved after mint operations
- **No Token Loss**: Mint/burn operations don't create or destroy tokens unexpectedly
- **Burn Reduces Supply**: Burning always reduces total supply
- **Mint Requires Collateral**: Cannot mint without adequate collateral
- **Price Bounds**: Price values remain within valid range
- **Reentrancy Protection**: No external calls before state changes

### 2. Halmos Symbolic Execution
Location: `packages/contracts/test/formal/LibUbiquityPoolSymbolic.t.sol`

Designed for [Halmos](https://github.com/a16z/halmos) symbolic execution:
- **Mint Collateral Preservation**: No path violates collateral ratio
- **Burn Debt Reduction**: Burning always reduces or maintains debt
- **Swap Conservation**: Constant product invariant holds for all inputs
- **Overflow Protection**: Arithmetic operations don't overflow
- **Governance Consistency**: Reward distribution is fair

## Running Tests

### Fuzz Tests
```bash
forge test --match-path "*Invariant*" -vvv
```

### Symbolic Tests (requires Halmos)
```bash
pip install halmos
halmos --match-test "test_symb"
```

## Properties Verified

| Property | Method | Status |
|----------|--------|--------|
| Token conservation | Fuzz | ✅ |
| Collateral ratio | Fuzz | ✅ |
| No token loss | Fuzz | ✅ |
| Burn correctness | Fuzz | ✅ |
| Mint collateral check | Fuzz | ✅ |
| Price bounds | Fuzz | ✅ |
| Reentrancy | Fuzz | ✅ |
| Swap conservation | Symbolic | ✅ |
| Overflow safety | Symbolic | ✅ |
| Governance fairness | Symbolic | ✅ |
