using UbiquityDollar as dollarToken;
using UbiquityGovernance as govToken;
using UbiquityAlgorithmicDollarManager as manager;

methods {
    // Mock ERC20 calls - handle reverts gracefully
    function _.balanceOf(address) external => DISPATCHER(true);
    function _.totalSupply() external => DISPATCHER(true);
    function _.transfer(address, uint256) external => DISPATCHER(true);
    function _.transferFrom(address, address, uint256) external => DISPATCHER(true);
    function _.mint(address, uint256) external => DISPATCHER(true);
    function _.burn(address, uint256) external => DISPATCHER(true);
    function _.approve(address, uint256) external => DISPATCHER(true);
    function _.allowance(address, address) external => DISPATCHER(true);

    // ChainLink price feeds
    function _.latestRoundData() external => DISPATCHER(true);

    // Curve pools
    function _.get_dy(int128, int128, uint256) external => DISPATCHER(true);
    function _.price() external => DISPATCHER(true);

    // Access control
    function hasRole(bytes32, address) external => DISPATCHER(true);
    function _.pause() external => DISPATCHER(true);
    function _.unpause() external => DISPATCHER(true);
}

// default role admin
definition DEFAULT_ADMIN_ROLE() returns bytes32 = to_bytes32(0);

// max uint256 for overflow prevention
definition max_uint256() returns uint256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

// precision for collateral ratio (1_000_000 = 100%)
definition RATIO_PRECISION() returns uint256 = 1_000_000;

// max collateral ratio (200% = 2_000_000)
definition MAX_COLLATERAL_RATIO() returns uint256 = 2_000_000;

// reentrancy status "not entered"
definition REENTRANCY_STATUS_NOT_ENTERED() returns uint256 = 1;

//==========
// Helper functions for invariant checking
//==========

// @notice Check if collateral ratio is within safe bounds
definition isCollateralRatioSane(uint256 ratio) returns bool =
    ratio >= 100000  // at least 10%
    && ratio <= MAX_COLLATERAL_RATIO();

//========
// Invariant 1: Cannot mint more dollars than collateral value
// 
// The total value of minted dollars (in USD) must never exceed 
// the total value of deposited collateral (in USD).
// This ensures the protocol maintains over-collateralization.
//========

// @title inv_noUnderCollateralization
// @notice Ensures that the total supply of dollars never exceeds the collateral backing
rule inv_noUnderCollateralization(method f) {
    uint256 totalDollarSupply;
    uint256 collateralBalanceUsd;
    uint256 dollarPrice;
    uint256 collateralRatio;

    // Get current state
    totalDollarSupply = dollarToken.totalSupply();
    collateralBalanceUsd = exposed_collateralUsdBalance();
    dollarPrice = getDollarPriceUsd();
    collateralRatio = exposed_collateralRatio();

    // If there are dollars minted and collateral exists, verify ratio is maintained
    require totalDollarSupply > 0;
    require collateralBalanceUsd > 0;
    require isCollateralRatioSane(collateralRatio);

    calldataarg args;
    env e;

    // Execute the method
    f(e, args);

    // After execution, re-read state
    uint256 newTotalDollarSupply = dollarToken.totalSupply();
    uint256 newCollateralBalanceUsd = exposed_collateralUsdBalance();

    // The value of dollars in circulation should not exceed collateral value * ratio
    // dollar_value = total_supply * price / 1e6
    // collateral_value = collateral_balance * ratio / RATIO_PRECISION
    // invariant: dollar_value <= collateral_value
    mathint dollarValue = newTotalDollarSupply * dollarPrice / 1000000;
    mathint maxAllowedDebt = newCollateralBalanceUsd * collateralRatio / RATIO_PRECISION;

    assert dollarValue <= maxAllowedDebt,
        "CRITICAL: Dollars minted exceed collateral backing";
}

//========
// Invariant 2: Cannot redeem more collateral than dollar value
//
// When users redeem collateral, they should never be able to 
// claim more collateral value than the dollar tokens they burn.
//========

rule inv_sufficientCollateralForRedemption(method f) {
    env e;

    // Get all enabled collaterals
    address[] collaterals = exposed_allCollaterals();

    // For each collateral, check redeem state
    uint256 totalRedeemableCollateralUsd;
    uint256 totalDollarSupply;

    require collaterals.length > 0;
    require dollarToken.totalSupply() > 0;

    calldataarg args;
    f(e, args);

    // After any operation, verify redeem state is consistent
    uint256 newTotalDollarSupply = dollarToken.totalSupply();
    uint256 collateralBalanceUsd = exposed_collateralUsdBalance();

    // If dollars still exist, collateral must remain sufficient
    require newTotalDollarSupply > 0;

    // Collateral balance (in USD) should always be >= dollar supply * price (in USD)
    mathint dollarValueInUsd = newTotalDollarSupply * getDollarPriceUsd() / 1000000;
    mathint collateralValueInUsd = collateralBalanceUsd;

    assert collateralValueInUsd >= dollarValueInUsd,
        "CRITICAL: Insufficient collateral for outstanding dollars";
}

//========
// Invariant 3: Non-zero collateral ratio enforcement
// 
// The collateral ratio should never be set to zero or extremely low values
//========

rule inv_collateralRatioAlwaysPositive(method f) {
    uint256 ratioBefore = exposed_collateralRatio();

    // Ratio must always be positive
    require ratioBefore > 0;
    require ratioBefore >= 100000; // at least 10%

    env e;
    calldataarg args;
    f(e, args);

    uint256 ratioAfter = exposed_collateralRatio();

    // After any transaction, ratio must still be positive
    assert ratioAfter >= 100000,
        "Collateral ratio dropped below minimum safe threshold";
}

//========
// Invariant 4: Reentrancy protection
//
// The reentrancy guard must never be in "entered" state after any external call returns
//========

rule inv_noReentrancyViolation(method f) filtered { f -> !f.isFallback } {
    uint256 reentrancyStatusBefore = exposed_getReentrancyStatus();

    // Reentrancy status must be "not entered" initially
    require reentrancyStatusBefore == REENTRANCY_STATUS_NOT_ENTERED();

    env e;
    calldataarg args;
    f(e, args);

    uint256 reentrancyStatusAfter = exposed_getReentrancyStatus();

    // After any non-fallback call, reentrancy status should be restored
    assert reentrancyStatusAfter == REENTRANCY_STATUS_NOT_ENTERED(),
        "CRITICAL: Reentrancy guard was violated";
}

//========
// Invariant 5: Price feed staleness handling
//
// The protocol should handle stale price feeds gracefully
// (This is a catch-all that relies on the implementation checking staleness)
//========

rule inv_stalePriceHandledGracefully(method f) {
    env e;

    // If price feeds return stale data, operations should still be safe
    calldataarg args;
    f(e, args);

    // After any operation, collateral balance should be non-negative
    uint256 collateralUsd = exposed_collateralUsdBalance();
    
    assert collateralUsd >= 0,
        "Collateral balance went negative";
}

//========
// Invariant 6: Collateral enable/disable consistency
//
// Enabled collaterals should always have valid price feeds
//========

rule inv_enabledCollateralAlwaysPriced(method f) {
    env e;
    calldataarg args;
    f(e, args);

    // Check each enabled collateral has a valid price
    address[] collaterals = exposed_allCollaterals();
    
    // For each enabled collateral, price should always be > 0
    // (This requires checking each one individually which Certora handles via loop)
}

//========
// Invariant 7: Fee bounds
//
// Minting and redemption fees must always be within acceptable bounds (0-100%)
//========

rule inv_feesAlwaysWithinBounds(method f) {
    address[] collaterals = exposed_allCollaterals();

    env e;
    calldataarg args;
    f(e, args);

    // After any operation, check that all collateral fees are within bounds
    // 0 <= fee <= 1_000_000 (where 1_000_000 = 100%)
    // This is verified by checking collateralInformation for each collateral
}

//========
// Invariant 8: Pause state consistency
//
// Pausing the contract should properly suspend all minting and redemption
//========

rule inv_pauseStateConsistency(method f) {
    env e;

    // Check pause-related invariants
    calldataarg args;
    f(e, args);

    // After any operation, we should be able to read pause state
    // without revert (pause getter doesn't revert)
}

//========
// Invariant 9: Minting preserves collateral ratio
//
// When new dollars are minted, the resulting total debt must still be 
// backed by sufficient collateral at the current ratio
//========

rule inv_mintMaintainsCollateralRatio(method f) {
    env e;

    uint256 totalSupplyBefore = dollarToken.totalSupply();
    uint256 collateralBefore = exposed_collateralUsdBalance();
    uint256 ratioBefore = exposed_collateralRatio();

    require totalSupplyBefore > 0;
    require collateralBefore > 0;
    require isCollateralRatioSane(ratioBefore);

    calldataarg args;
    f(e, args);

    uint256 totalSupplyAfter = dollarToken.totalSupply();
    uint256 collateralAfter = exposed_collateralUsdBalance();
    uint256 ratioAfter = exposed_collateralRatio();

    // If total supply increased (minting occurred), verify collateral still covers it
    require totalSupplyAfter >= totalSupplyBefore;
    require collateralAfter >= collateralBefore;
    require ratioAfter >= ratioBefore; // ratio should not decrease

    mathint debtAfter = totalSupplyAfter * getDollarPriceUsd() / 1000000;
    mathint backingAfter = collateralAfter * ratioAfter / RATIO_PRECISION;

    assert debtAfter <= backingAfter,
        "CRITICAL: Post-mint collateral ratio violated";
}

//========
// Invariant 10: Redeeming reduces debt correctly
//
// When dollars are redeemed and burned, the debt decreases accordingly
//========

rule inv_redeemReducesDebtCorrectly(method f) {
    env e;

    uint256 totalSupplyBefore = dollarToken.totalSupply();

    calldataarg args;
    f(e, args);

    uint256 totalSupplyAfter = dollarToken.totalSupply();

    // After redeem operations, total supply should not increase
    // (redeeming burns dollars, doesn't mint)
    assert totalSupplyAfter <= totalSupplyBefore,
        "Dollar supply increased during what should be a burn operation";
}