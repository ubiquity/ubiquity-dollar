// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IStabilityPool {
    function provideToSP(uint256 _amount, address _frontEndTag) external;
    function withdrawFromSP(uint256 _amount) external;
    function withdrawETHGainToTrove(address _upperHint, address _lowerHint) external;
    function registerFrontEnd(uint256 _kickbackRate) external;
    function getDepositorETHGain(address _depositor) external view returns (uint256);
    function getDepositorLQTYGain(address _depositor) external view returns (uint256);
    function getCompoundedLUSDDeposit(address _depositor) external view returns (uint256);
}
