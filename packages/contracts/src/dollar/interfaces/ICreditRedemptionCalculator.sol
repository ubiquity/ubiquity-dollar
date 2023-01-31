// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title A mechanism for calculating uAR received for a dollar amount burnt
interface ICreditRedemptionCalculator {
    function getCreditAmount(
        uint256 dollarsToBurn,
        uint256 blockHeightDebt
    ) external view returns (uint256);
}
