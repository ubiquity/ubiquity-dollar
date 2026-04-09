# Formal Verification for LibUbiquityPool

This document describes the formal verification efforts for the `LibUbiquityPool` library, which is the core pool logic for the Ubiquity Dollar protocol.

## Overview

`LibUbiquityPool` is a diamond library that manages collateral-backed minting and redemption of Ubiquity Dollar tokens. It handles:

- **Minting**: Users deposit collateral (and optionally governance tokens) to receive Dollar tokens
- **Redemption**: Users burn Dollar tokens to receive collateral (and optionally governance tokens)
- **AMO Minter Borrowing**: Authorized AMO minters can borrow collateral for yield strategies
- **Price Oracle Integration**: Chainlink price feeds for collateral, ETH/USD, and stable/USD pairs

## Verification Tools

### Certora Prover

The Certora Prover is used to mathematically prove properties about the pool's behavior. The specification is located at `certora/specs/LibUbiquityPool.spec` and the configuration at `certora/conf/LibUbiquityPool.conf`.

### Halmos

Halmos is used for symbolic testing of key mathematical invariants. Tests are located at `packages/contracts/test/formal/LibUbiquityPoolHalmos.t.sol`.

## Verified Properties

### 1. Token Balance Preservation (No Token Loss)

**Invariant**: Collateral token balances in the pool can only decrease through explicit user actions (collectRedemption, amoMinterBorrow). The pool never spontaneously loses tokens.

```
rule invariant_collateralBalanceNonDecreasingSpontaneously
```

**Invariant**: The total held collateral equals the sum of free collateral and unclaimed collateral:

```
totalHeld >= freeCollateralBalance (since unclaimedPoolCollateral >= 0)
```

### 2. Collateral Ratio Maintenance

**Invariant**: The collateral ratio is always bounded between 0 and `PRICE_PRECISION` (1,000,000 = 100%).

```
rule invariant_collateralRatioBounded
```

This ensures the ratio cannot overflow or become meaningless.

### 3. Minting Invariants

**Property**: The amount of Dollar tokens minted is always less than or equal to the requested amount (due to minting fees).

```
rule invariant_mintDollarNoFreeMoney
rule rule_mintingFeeReducesOutput
```

**Property**: Minting respects the pool ceiling — the free collateral balance after minting cannot exceed the configured ceiling.

```
rule invariant_mintRespectsPoolCeiling
```

**Property**: Minting reverts when paused for a given collateral index.

```
rule rule_mintDollarRevertsWhenPaused
```

### 4. Burning/Redemption Invariants

**Property**: The exact `dollarAmount` is burned from the caller during redemption (fees reduce the output, not the burn).

```
rule invariant_redeemDollarBurnsExactAmount
```

**Property**: Governance tokens are minted to the pool during redemption (supply increases).

```
rule invariant_governanceConservationDuringRedemption
```

### 5. Collection Invariants

**Property**: `collectRedemption` transfers exactly the expected amounts of collateral and governance tokens, and zeroes the user's redemption balances.

```
rule invariant_collectRedemptionTransfersCorrectAmounts
```

**Property**: Collection respects the `redemptionDelayBlocks` setting.

```
rule rule_collectRedemptionRespectsDelay
```

### 6. Reentrancy Protection

**Invariant**: The reentrancy guard status returns to `NOT_ENTERED` after every public method execution.

```
rule invariant_reentrancyGuardResets
```

### 7. AMO Minter Security

**Property**: AMO minter borrows are bounded by the free collateral balance.

```
rule invariant_amoBorrowWithinFreeCollateral
rule rule_amoMinterBorrowRequiresAuth
```

## Halmos Symbolic Tests

The Halmos test suite covers:

| Test | Description |
|------|-------------|
| `test_mintDollar_output_le_input` | Minted output ≤ requested input |
| `test_redeemDollar_burns_exact_amount` | Exact burn amount verification |
| `test_freeCollateral_balance_invariant` | Balance = free + unclaimed |
| `test_collateralRatio_bounded` | Ratio ∈ [0, 1e6] |
| `test_getDollarInCollateral_positive` | Positive output for valid inputs |
| `test_fee_math_no_overflow` | Fee calculation correctness |
| `test_collectRedemption_zeroes_balance` | Balances zeroed after collection |
| `test_amoBorrow_bounded` | AMO borrow ≤ free collateral |
| `test_redemption_delay` | Delay block enforcement |
| `test_pool_ceiling_enforcement` | Pool ceiling check |
| `test_governance_conservation_symbolic` | Governance token conservation |

## Running Verification

### Certora

```bash
# Install Certora CLI
pip install certora-cli

# Run verification (from packages/contracts directory)
certoraRun certora/conf/LibUbiquityPool.conf
```

### Halmos

```bash
# Install Halmos
pip install halmos

# Run symbolic tests (from packages/contracts directory)
halmos --contract LibUbiquityPoolHalmosTest
```

## Architecture Notes

### Diamond Pattern

`LibUbiquityPool` is a library used within the EIP-2535 Diamond pattern. The `UbiquityPoolFacet` delegates calls to this library. The Certora specification verifies through the Diamond proxy with the facet extension.

### Storage Layout

The pool uses a dedicated storage slot (`UBIQUITY_POOL_STORAGE_POSITION`) to avoid storage collisions in the diamond pattern. The `AppStorage` struct (via `LibAppStorage`) is used for shared protocol state including the reentrancy guard.

### Price Feeds

The system relies on Chainlink price feeds for:
- Collateral/USD prices
- ETH/USD price
- Stable/USD price

Staleness checks ensure price data freshness. The Certora spec accounts for price feed validation through the harness.

## Limitations

1. **External dependencies**: Chainlink price feeds, Curve pool oracles, and token contracts are modeled as black boxes. The verification assumes they behave correctly.
2. **Integer overflow**: Solidity 0.8.x provides built-in overflow checks, but the verification uses `mathint` (unbounded integers) in Certora to avoid spurious counterexamples.
3. **Admin functions**: Some admin/restricted functions are included in the spec but may require additional harness setup for full verification.

## References

- [Issue #926](https://github.com/ubiquity/ubiquity-dollar/issues/926) — Formal Verification for LibUbiquityPool
- [Certora Documentation](https://docs.certora.com/)
- [Halmos Documentation](https://github.com/a16z/halmos)
- [Existing staking verification](../test/certora/staking.spec) — Reference for Certora specs in this repo
