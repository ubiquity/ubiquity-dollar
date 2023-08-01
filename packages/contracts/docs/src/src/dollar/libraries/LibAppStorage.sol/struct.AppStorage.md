# AppStorage
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/fc55925e18af3f4cb5171ecd66ba4c48dc994260/src/dollar/libraries/LibAppStorage.sol)

Shared struct used as a storage in the `LibAppStorage` library


```solidity
struct AppStorage {
    uint256 reentrancyStatus;
    address dollarTokenAddress;
    address creditNftAddress;
    address creditNFTCalculatorAddress;
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

