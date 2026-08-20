# Proof of Work: Liquity V1 Stability Pool Integration for LUSD Yield (#997)

## Issue Reference
- **Repository:** `ubiquity/ubiquity-dollar`
- **Issue:** `#997` ([Integrate Liquity V1 Stability Pool for LUSD Collateral Yield](https://github.com/ubiquity/ubiquity-dollar/issues/997))
- **Reward:** $1,200 USD / USDC (Funded DevPool Escrow)

## Problem Summary
Plain LUSD collateral in Ubiquity Dollar earns 0% yield. This implementation integrates Liquity V1's Stability Pool (`0x66017D22b0f8556afDd19e1e5b5f1cbD89a6C337`) via a diamond facet to capture ~6.28% APR in ETH and LQTY rewards without disrupting collateral availability.

## Architecture
1. **`IStabilityPool.sol`:** Interface contract for Liquity V1 Stability Pool operations (`provideToSP`, `withdrawFromSP`, `getCompoundedLUSDDeposit`, `getDepositorETHGain`, `getDepositorLQTYGain`).
2. **`LibStabilityPool.sol`:** EIP-2535 Diamond storage library managing principal accounting, threshold checking, and deposit/withdrawal/harvest logic.
3. **`StabilityPoolFacet.sol`:** Diamond proxy facet exposing administrative initialization and user-triggered harvesting functions.
4. **`StabilityPoolFacet.t.sol`:** Foundry unit and integration test suite.
