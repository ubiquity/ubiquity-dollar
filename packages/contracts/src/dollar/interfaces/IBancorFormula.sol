// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/// @title Bancor Formula interface
/// @notice Forked from Bancor Protocol
/// @dev
interface IBancorFormula {
    function calculatePurchaseReturn(
        uint256 _supply,
        uint256 _connectorBalance,
        uint32 _connectorWeight,
        uint256 _depositAmount
    ) external view returns (uint256);

    function calculateSaleReturn(
        uint256 _sellAmount,
        uint32 _connectorWeight,
        uint256 _supply,
        uint256 _connectorBalance
    ) external view returns (uint256);
}
