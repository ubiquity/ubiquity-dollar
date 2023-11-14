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

    /// @inheritdoc IUbiquityPoolV2
    function allCollaterals() external view returns (address[] memory) {
        return LibUbiquityPoolV2.allCollaterals();
    }

    /// @inheritdoc IUbiquityPoolV2
    function collateralInformation(
        address collateralAddress
    )
        external
        view
        returns (LibUbiquityPoolV2.CollateralInformation memory returnData)
    {
        return LibUbiquityPoolV2.collateralInformation(collateralAddress);
    }

    /// @inheritdoc IUbiquityPoolV2
    function collateralUsdBalance()
        external
        view
        returns (uint256 balanceTally)
    {
        return LibUbiquityPoolV2.collateralUsdBalance();
    }

    /// @inheritdoc IUbiquityPoolV2
    function freeCollateralBalance(
        uint256 collateralIndex
    ) external view returns (uint256) {
        return LibUbiquityPoolV2.freeCollateralBalance(collateralIndex);
    }

    /// @inheritdoc IUbiquityPoolV2
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

    /// @inheritdoc IUbiquityPoolV2
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

    /// @inheritdoc IUbiquityPoolV2
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

    /// @inheritdoc IUbiquityPoolV2
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

    /// @inheritdoc IUbiquityPoolV2
    function collectRedemption(
        uint256 collateralIndex
    ) external returns (uint256 collateralAmount) {
        return LibUbiquityPoolV2.collectRedemption(collateralIndex);
    }

    //=========================
    // AMO minters functions
    //=========================

    /// @inheritdoc IUbiquityPoolV2
    function amoMinterBorrow(uint256 collateralAmount) external {
        LibUbiquityPoolV2.amoMinterBorrow(collateralAmount);
    }

    //========================
    // Restricted functions
    //========================

    /// @inheritdoc IUbiquityPoolV2
    function addAmoMinter(address amoMinterAddress) external onlyAdmin {
        LibUbiquityPoolV2.addAmoMinter(amoMinterAddress);
    }

    /// @inheritdoc IUbiquityPoolV2
    function addCollateralToken(
        address collateralAddress,
        uint256 poolCeiling
    ) external onlyAdmin {
        LibUbiquityPoolV2.addCollateralToken(collateralAddress, poolCeiling);
    }

    /// @inheritdoc IUbiquityPoolV2
    function removeAmoMinter(address amoMinterAddress) external onlyAdmin {
        LibUbiquityPoolV2.removeAmoMinter(amoMinterAddress);
    }

    /// @inheritdoc IUbiquityPoolV2
    function setCollateralPrice(
        uint256 collateralIndex,
        uint256 newPrice
    ) external onlyAdmin {
        LibUbiquityPoolV2.setCollateralPrice(collateralIndex, newPrice);
    }

    /// @inheritdoc IUbiquityPoolV2
    function setFees(
        uint256 collateralIndex,
        uint256 newMintFee,
        uint256 newRedeemFee
    ) external onlyAdmin {
        LibUbiquityPoolV2.setFees(collateralIndex, newMintFee, newRedeemFee);
    }

    /// @inheritdoc IUbiquityPoolV2
    function setPoolCeiling(
        uint256 collateralIndex,
        uint256 newCeiling
    ) external onlyAdmin {
        LibUbiquityPoolV2.setPoolCeiling(collateralIndex, newCeiling);
    }

    /// @inheritdoc IUbiquityPoolV2
    function setPriceThresholds(
        uint256 newMintPriceThreshold,
        uint256 newRedeemPriceThreshold
    ) external onlyAdmin {
        LibUbiquityPoolV2.setPriceThresholds(
            newMintPriceThreshold,
            newRedeemPriceThreshold
        );
    }

    /// @inheritdoc IUbiquityPoolV2
    function setRedemptionDelay(uint256 newRedemptionDelay) external onlyAdmin {
        LibUbiquityPoolV2.setRedemptionDelay(newRedemptionDelay);
    }

    /// @inheritdoc IUbiquityPoolV2
    function toggleCollateral(uint256 collateralIndex) external onlyAdmin {
        LibUbiquityPoolV2.toggleCollateral(collateralIndex);
    }

    /// @inheritdoc IUbiquityPoolV2
    function toggleMRB(
        uint256 collateralIndex,
        uint8 toggleIndex
    ) external onlyAdmin {
        LibUbiquityPoolV2.toggleMRB(collateralIndex, toggleIndex);
    }
}
