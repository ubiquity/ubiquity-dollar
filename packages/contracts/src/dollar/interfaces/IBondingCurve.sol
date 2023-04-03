// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IBondingCurve {
    function setParams(
        uint32 _connectorWeight, 
        uint256 _baseY
    ) external; 

    function connectorWeight() external returns (uint32);

    function baseY() external returns (uint256);
    
    function poolBalance() external returns (uint256);

    function deposit(uint256 _collateralDeposited, address _recipient)
        external;

    function withdraw(uint256 _amount) external;
}
