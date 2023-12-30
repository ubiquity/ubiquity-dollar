# AppStorage
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/cbd28a4612a3e634eb46789c9d7030bc45955983/src/dollar/libraries/LibAppStorage.sol)

Shared struct used as a storage in the `LibAppStorage` library


```solidity
struct AppStorage {
    uint256 reentrancyStatus;
    address dollarTokenAddress;
    address creditNftAddress;
    address creditNftCalculatorAddress;
    address dollarMintCalculatorAddress;
    address stakingShareAddress;
    address stakingContractAddress;
    address stableSwapMetaPoolAddress;
    address curve3PoolTokenAddress;
    address treasuryAddress;
    address governanceTokenAddress;
    address sushiSwapPoolAddress;
    address masterChefAddress;
    address formulasAddress;
    address creditTokenAddress;
    address creditCalculatorAddress;
    address ubiquiStickAddress;
    address bondingCurveAddress;
    address bancorFormulaAddress;
    address curveDollarIncentiveAddress;
    mapping(address => address) _excessDollarDistributors;
    bool paused;
}
```

