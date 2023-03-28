// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IBondingCurve {
    function setParams(
        uint32 _connectorWeight, 
        uint256 _baseY
    ) external; 

    function deposit(uint256 _collateralDeposited, address _recipient)
        external
        returns (uint256);

    function withdraw(uint256 _amount) external;
}
