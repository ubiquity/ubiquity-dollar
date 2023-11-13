// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import {IUbiquityPoolV2} from "../interfaces/IUbiquityPoolV2.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";
import {LibUbiquityPoolV2} from "../libraries/LibUbiquityPoolV2.sol";

/**
 * @notice Ubiquity pool facet
 * @notice Allows users to:
 * - deposit collateral in exchange for Ubiquity Dollars
 * - redeem Ubiquity Dollars in exchange for the earlier provided collateral
 */
contract UbiquityPoolFacetV2 is IUbiquityPoolV2, Modifiers {
    //=====================
    // Views
    //=====================

    function allCollaterals() external view returns (address[] memory) {
        return LibUbiquityPoolV2.allCollaterals();
    }

    function collateralInformation(
        address collateralAddress
    )
        external
        view
        returns (LibUbiquityPoolV2.CollateralInformation memory returnData)
    {
        return LibUbiquityPoolV2.collateralInformation(collateralAddress);
    }

    function collateralUsdBalance()
        external
        view
        returns (uint256 balanceTally)
    {
        return LibUbiquityPoolV2.collateralUsdBalance();
    }

    function freeCollateralBalance(
        uint256 collateralIndex
    ) external view returns (uint256) {
        return LibUbiquityPoolV2.freeCollateralBalance(collateralIndex);
    }

    function getDollarInCollateral(
        uint256 collateralIndex,
        uint256 dollarAmount
    ) external view returns (uint256) {
        return
            LibUbiquityPoolV2.getDollarInCollateral(
                collateralIndex,
                dollarAmount
            );
    }

    function getDollarPriceUsd()
        external
        view
        returns (uint256 dollarPriceUsd)
    {
        return LibUbiquityPoolV2.getDollarPriceUsd();
    }

    //====================
    // Public functions
    //====================

    function mintDollar(
        uint256 collateralIndex,
        uint256 dollarAmount,
        uint256 dollarOutMin,
        uint256 maxCollateralIn
    ) external returns (uint256 totalDollarMint, uint256 collateralNeeded) {
        return
            LibUbiquityPoolV2.mintDollar(
                collateralIndex,
                dollarAmount,
                dollarOutMin,
                maxCollateralIn
            );
    }

    function redeemDollar(
        uint256 collateralIndex,
        uint256 dollarAmount,
        uint256 collateralOutMin
    ) external returns (uint256 collateralOut) {
        return
            LibUbiquityPoolV2.redeemDollar(
                collateralIndex,
                dollarAmount,
                collateralOutMin
            );
    }

    function collectRedemption(
        uint256 collateralIndex
    ) external returns (uint256 collateralAmount) {
        return LibUbiquityPoolV2.collectRedemption(collateralIndex);
    }

    //=========================
    // AMO minters functions
    //=========================

    function amoMinterBorrow(uint256 collateralAmount) external {
        LibUbiquityPoolV2.amoMinterBorrow(collateralAmount);
    }

    //========================
    // Restricted functions
    //========================

    function addAmoMinter(address amoMinterAddress) external onlyAdmin {
        LibUbiquityPoolV2.addAmoMinter(amoMinterAddress);
    }

    function addCollateralToken(
        address collateralAddress,
        uint256 poolCeiling,
        uint256[] memory initialFees
    ) external onlyAdmin {
        LibUbiquityPoolV2.addCollateralToken(
            collateralAddress,
            poolCeiling,
            initialFees
        );
    }

    function removeAmoMinter(address amoMinterAddress) external onlyAdmin {
        LibUbiquityPoolV2.removeAmoMinter(amoMinterAddress);
    }

    function setCollateralPrice(
        uint256 collateralIndex,
        uint256 newPrice
    ) external onlyAdmin {
        LibUbiquityPoolV2.setCollateralPrice(collateralIndex, newPrice);
    }

    function setFees(
        uint256 collateralIndex,
        uint256 newMintFee,
        uint256 newRedeemFee
    ) external onlyAdmin {
        LibUbiquityPoolV2.setFees(collateralIndex, newMintFee, newRedeemFee);
    }

    function setPoolCeiling(
        uint256 collateralIndex,
        uint256 newCeiling
    ) external onlyAdmin {
        LibUbiquityPoolV2.setPoolCeiling(collateralIndex, newCeiling);
    }

    function setPriceThresholds(
        uint256 newMintPriceThreshold,
        uint256 newRedeemPriceThreshold
    ) external onlyAdmin {
        LibUbiquityPoolV2.setPriceThresholds(
            newMintPriceThreshold,
            newRedeemPriceThreshold
        );
    }

    function setRedemptionDelay(uint256 newRedemptionDelay) external onlyAdmin {
        LibUbiquityPoolV2.setRedemptionDelay(newRedemptionDelay);
    }

    function toggleCollateral(uint256 collateralIndex) external onlyAdmin {
        LibUbiquityPoolV2.toggleCollateral(collateralIndex);
    }

    function toggleMRB(
        uint256 collateralIndex,
        uint8 toggleIndex
    ) external onlyAdmin {
        LibUbiquityPoolV2.toggleMRB(collateralIndex, toggleIndex);
    }
}
