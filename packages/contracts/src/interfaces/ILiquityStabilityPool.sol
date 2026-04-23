// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ILiquityStabilityPool {
    // Правильная сигнатура: есть _frontEndTag
    function provideToSP(uint256 _amount, address _frontEndTag) external;
    function withdrawFromSP(uint256 _amount) external;
    function getDepositorLQTYGain(address _depositor) external view returns (uint256);
    function getCompoundedLUSDDeposit(address _depositor) external view returns (uint256);
    // claimLQTY() удалён — награды начисляются автоматически
}
