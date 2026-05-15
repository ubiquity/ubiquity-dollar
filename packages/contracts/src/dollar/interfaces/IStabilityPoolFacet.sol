// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @notice Interface for the Stability Pool Facet
interface IStabilityPoolFacet {
    // --- Events ---

    event DepositedToPool(address indexed sender, uint256 amount);
    event WithdrawnFromPool(address indexed sender, uint256 amount);
    event RewardsHarvested(
        address indexed sender,
        uint256 ethReward,
        uint256 lqtyReward
    );
    event StabilityPoolAddressSet(address indexed stabilityPool);
    event RewardThresholdSet(uint256 threshold);
    event SpTreasuryAddressSet(address indexed treasury);

    // --- View Functions ---

    function stabilityPoolAddress() external view returns (address);
    function totalPrincipalInPool() external view returns (uint256);
    function rewardThreshold() external view returns (uint256);
    function spTreasuryAddress() external view returns (address);
    function getDepositedLUSD() external view returns (uint256);
    function getPendingETHReward() external view returns (uint256);
    function getPendingLQTYReward() external view returns (uint256);

    // --- External Functions ---

    function depositToPool(uint256 amount) external;
    function withdrawFromPool(uint256 amount) external;
    function harvestRewards() external;

    // --- Restricted Functions ---

    function setStabilityPoolAddress(address _stabilityPool) external;
    function setRewardThreshold(uint256 _threshold) external;
    function setSpTreasuryAddress(address _treasury) external;
}
