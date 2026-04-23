// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ILiquityStabilityPool {
    function provideToSP(uint256 _amount) external;
    function withdrawFromSP(uint256 _amount) external;
    function getDepositorLQTYGain(address _depositor) external view returns (uint256);
    function getCompoundedLUSDDeposit(address _depositor) external view returns (uint256);
    function claimLQTY() external;
}
