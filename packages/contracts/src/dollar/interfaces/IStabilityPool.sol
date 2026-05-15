// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @notice Interface for the Liquity V1 Stability Pool
/// @dev See: https://github.com/liquity/dev/blob/main/packages/contracts/contracts/StabilityPool.sol
interface IStabilityPool {
    // --- Events ---

    event UserDepositChanged(address indexed _depositor, uint256 _newDeposit);
    event ETHGainWithdrawn(address indexed _depositor, uint256 _ETH);
    event LQTYPaidToDepositor(address indexed _depositor, uint256 _LQTY);
    event StabilityPoolETHBalanceUpdated(uint256 _newBalance);
    event StabilityPoolLUSDBalanceUpdated(uint256 _newBalance);

    // --- Functions ---

    function provideToSP(uint256 _amount, address _frontEndTag) external;
    function withdrawFromSP(uint256 _amount) external;
    function getDepositorETHGain(address _depositor) external view returns (uint256);
    function getDepositorLQTYGain(address _depositor) external view returns (uint256);
    function getCompoundedLUSDDeposit(address _depositor) external view returns (uint256);
    function withdrawETHGainToTrove(address _depositor) external;

    function getTotalLUSDDeposits() external view returns (uint256);
    function getETH() external view returns (uint256);
    function getCurrentScale() external view returns (uint256);
    function getCurrentEpoch() external view returns (uint256);

    function LUSD() external view returns (address);
    function lqtyToken() external view returns (address);
}
