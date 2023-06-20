// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.19;

import {IMetaPool} from "./i-meta-pool.sol";

interface IUbiquityPool {
    function mintDollar(
        address collateralAddress,
        uint256 collateralAmount,
        uint256 dollarOutMin
    ) external;

    function redeemDollar(
        address collateralAddress,
        uint256 dollarAmount,
        uint256 collateralOutMin
    ) external;

    function collectRedemption(address collateralAddress) external;

    function addToken(
        address collateralAddress,
        IMetaPool collateralMetaPool
    ) external;

    function setRedeemActive(
        address collateralAddress,
        bool notRedeemPaused
    ) external;

    function getRedeemActive(
        address _collateralAddress
    ) external view returns (bool);

    function setMintActive(
        address collateralAddress,
        bool notMintPaused
    ) external;

    function getMintActive(
        address _collateralAddress
    ) external view returns (bool);

    function getRedeemCollateralBalances(
        address account,
        address collateralAddress
    ) external view returns (uint256);
}
