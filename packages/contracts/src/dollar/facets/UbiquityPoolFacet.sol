// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

// Modified from FraxPool.sol by Frax Finance
// https://github.com/FraxFinance/frax-solidity/blob/master/src/hardhat/contracts/Frax/Pools/FraxPool.sol

import {LibUbiquityPool} from "../libraries/LibUbiquityPool.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";
import {IMetaPool} from "../interfaces/IMetaPool.sol";
import "../interfaces/IUbiquityPool.sol";

/**
 * @notice Ubiquity pool facet
 * @notice Allows users to:
 * - deposit collateral in exchange for Ubiquity Dollars
 * - redeem Ubiquity Dollars in exchange for the earlier provided collateral
 */
contract UbiquityPoolFacet is Modifiers, IUbiquityPool {
    /// @inheritdoc IUbiquityPool
    function mintDollar(
        address collateralAddress,
        uint256 collateralAmount,
        uint256 dollarOutMin
    ) external {
        LibUbiquityPool.mintDollar(
            collateralAddress,
            collateralAmount,
            dollarOutMin
        );
    }

    /// @inheritdoc IUbiquityPool
    function redeemDollar(
        address collateralAddress,
        uint256 dollarAmount,
        uint256 collateralOutMin
    ) external {
        LibUbiquityPool.redeemDollar(
            collateralAddress,
            dollarAmount,
            collateralOutMin
        );
    }

    /// @inheritdoc IUbiquityPool
    function collectRedemption(address collateralAddress) external {
        LibUbiquityPool.collectRedemption(collateralAddress);
    }

    /// @inheritdoc IUbiquityPool
    function addToken(
        address collateralAddress,
        IMetaPool collateralMetaPool
    ) external onlyAdmin {
        LibUbiquityPool.addToken(collateralAddress, collateralMetaPool);
    }

    /// @inheritdoc IUbiquityPool
    function setRedeemActive(
        address collateralAddress,
        bool notRedeemPaused
    ) external onlyAdmin {
        LibUbiquityPool.setRedeemActive(collateralAddress, notRedeemPaused);
    }

    /// @inheritdoc IUbiquityPool
    function getRedeemActive(
        address _collateralAddress
    ) external view returns (bool) {
        return LibUbiquityPool.getRedeemActive(_collateralAddress);
    }

    /// @inheritdoc IUbiquityPool
    function setMintActive(
        address collateralAddress,
        bool notMintPaused
    ) external onlyAdmin {
        LibUbiquityPool.setMintActive(collateralAddress, notMintPaused);
    }

    /// @inheritdoc IUbiquityPool
    function getMintActive(
        address _collateralAddress
    ) external view returns (bool) {
        return LibUbiquityPool.getMintActive(_collateralAddress);
    }

    /// @inheritdoc IUbiquityPool
    function getRedeemCollateralBalances(
        address account,
        address collateralAddress
    ) external view returns (uint256) {
        return
            LibUbiquityPool.getRedeemCollateralBalances(
                account,
                collateralAddress
            );
    }
}
