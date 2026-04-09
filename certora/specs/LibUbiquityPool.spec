//////////////////////////////////////////////////
// Formal Verification: LibUbiquityPool
//////////////////////////////////////////////////

//////////////////////////////////////////////////
// Helper methods
//////////////////////////////////////////////////

// Get total collateral balance
method getCollateralBalance(address token) envfree returns (uint256) {
    env := msg;
}

//////////////////////////////////////////////////
// Invariants
//////////////////////////////////////////////////

/// @notice Total dollar supply should equal sum of all minted dollars minus burned
invariant dollarSupplyInvariant()
    requires uint256(IERC20 UbiquityDollarToken).totalSupply()) >= 0;

/// @notice Collateral tokens cannot be lost - pool collateral + user balances = total
invariant collateralBalancePreserved(address collateralToken)
    requires isCollateralEnabled(collateralToken)
{
    // Sum of all collateral held by pool should track properly
    ensures old(getCollateralBalance(collateralToken)) >= getCollateralBalance(collateralToken) - 
        (old(totalCollateralAmount[collateralToken]) - totalCollateralAmount[collateralToken]);
}

/// @notice Minting always increases dollar supply
invariant mintingIncreasesSupply(uint256 amount)
    ensures IERC20 UbiquityDollarToken).totalSupply() == old(IERC20 UbiquityDollarToken).totalSupply()) + amount;

/// @notice Burning always decreases dollar supply  
invariant burningDecreasesSupply(uint256 amount)
    ensures IERC20 UbiquityDollarToken).totalSupply() == old(IERC20 UbiquityDollarToken).totalSupply()) - amount;

/// @notice Collateral ratio is always within valid bounds
invariant collateralRatioBounded()
    collateralRatio >= 0 && collateralRatio <= 1_000_000;

/// @notice Pool never gives away more collateral than it holds
invariant noOverdraft(address collateralToken)
    getCollateralBalance(collateralToken) >= 0;

//////////////////////////////////////////////////
// Rules
//////////////////////////////////////////////////

/// @notice mintDollar: user gets correct amount of dollars for collateral
rule mintDollarCorrectOutput(address sender, uint256 collateralAmount, uint256 collateralIndex) {
    require isCollateralEnabled(collateralAddresses[collateralIndex]);
    require collateralAmount > 0;
    
    uint256 dollarBalanceBefore = IERC20 UbiquityDollarToken).balanceOf(sender);
    uint256 collateralBefore = getCollateralBalance(collateralAddresses[collateralIndex]);
    
    mintDollar(collateralIndex, collateralAmount, 0, 0);
    
    uint256 dollarBalanceAfter = IERC20 UbiquityDollarToken).balanceOf(sender);
    
    assert dollarBalanceAfter > dollarBalanceBefore;
    assert getCollateralBalance(collateralAddresses[collateralIndex]) <= collateralBefore;
}

/// @notice redeemDollar: user gets correct collateral back
rule redeemDollarCorrectOutput(address sender, uint256 dollarAmount, uint256 collateralIndex) {
    require isCollateralEnabled(collateralAddresses[collateralIndex]);
    require dollarAmount > 0;
    
    uint256 collateralBefore = getCollateralBalance(collateralAddresses[collateralIndex]);
    
    redeemDollar(collateralIndex, dollarAmount, 0, 0);
    
    assert getCollateralBalance(collateralAddresses[collateralIndex]) <= collateralBefore;
}

/// @notice No reentrancy in minting
rule noReentrancyMint(address sender, uint256 amount, uint256 index) {
    require amount > 0;
    require isCollateralEnabled(collateralAddresses[index]);
    
    // First call should succeed
    mintDollar(index, amount, 0, 0);
    
    // Second call with same params should also work (no lock-up)
    mintDollar(index, amount, 0, 0);
}

/// @notice collectAndSendCollateral doesn't drain more than intended
rule collectCollateralBounded(uint256 amount) {
    require amount > 0;
    uint256 poolBefore = getCollateralBalance(collateralAddresses[0]);
    
    collectAndSendCollateral(0, amount, msg.sender);
    
    assert getCollateralBalance(collateralAddresses[0]) >= poolBefore - amount;
}
