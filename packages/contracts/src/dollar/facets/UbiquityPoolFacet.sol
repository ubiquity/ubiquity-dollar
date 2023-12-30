// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import {IUbiquityPool} from "../interfaces/IUbiquityPool.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";
import {LibUbiquityPool} from "../libraries/LibUbiquityPool.sol";

/**
 * @notice Ubiquity pool facet
 * @notice Allows users to:
 * - deposit collateral in exchange for Ubiquity Dollars
 * - redeem Ubiquity Dollars in exchange for the earlier provided collateral
 */
contract UbiquityPoolFacet is IUbiquityPool, Modifiers {
    //=====================
    // Views
    //=====================

    /// @inheritdoc IUbiquityPool
    function allCollaterals() external view returns (address[] memory) {
        return LibUbiquityPool.allCollaterals();
    }

    /// @inheritdoc IUbiquityPool
    function collateralInformation(
        address collateralAddress
    )
        external
        view
        returns (LibUbiquityPool.CollateralInformation memory returnData)
    {
        return LibUbiquityPool.collateralInformation(collateralAddress);
    }

    /// @inheritdoc IUbiquityPool
    function collateralUsdBalance()
        external
        view
        returns (uint256 balanceTally)
    {
        return LibUbiquityPool.collateralUsdBalance();
    }

    /// @inheritdoc IUbiquityPool
    function freeCollateralBalance(
        uint256 collateralIndex
    ) external view returns (uint256) {
        return LibUbiquityPool.freeCollateralBalance(collateralIndex);
    }

    /// @inheritdoc IUbiquityPool
    function getDollarInCollateral(
        uint256 collateralIndex,
        uint256 dollarAmount
    ) external view returns (uint256) {
        return
            LibUbiquityPool.getDollarInCollateral(
                collateralIndex,
                dollarAmount
            );
    }

    /// @inheritdoc IUbiquityPool
    function getDollarPriceUsd()
        external
        view
        returns (uint256 dollarPriceUsd)
    {
        return LibUbiquityPool.getDollarPriceUsd();
    }

    //====================
    // Public functions
    //====================

    /// @inheritdoc IUbiquityPool
    function mintDollar(
        uint256 collateralIndex,
        uint256 dollarAmount,
        uint256 dollarOutMin,
        uint256 maxCollateralIn
    ) external returns (uint256 totalDollarMint, uint256 collateralNeeded) {
        return
            LibUbiquityPool.mintDollar(
                collateralIndex,
                dollarAmount,
                dollarOutMin,
                maxCollateralIn
            );
    }

    /// @inheritdoc IUbiquityPool
    function redeemDollar(
        uint256 collateralIndex,
        uint256 dollarAmount,
        uint256 collateralOutMin
    ) external returns (uint256 collateralOut) {
        return
            LibUbiquityPool.redeemDollar(
                collateralIndex,
                dollarAmount,
                collateralOutMin
            );
    }

    /// @inheritdoc IUbiquityPool
    function collectRedemption(
        uint256 collateralIndex
    ) external returns (uint256 collateralAmount) {
        return LibUbiquityPool.collectRedemption(collateralIndex);
    }

    /// @inheritdoc IUbiquityPool
    function updateChainLinkCollateralPrice(uint256 collateralIndex) external {
        LibUbiquityPool.updateChainLinkCollateralPrice(collateralIndex);
    }

    //=========================
    // AMO minters functions
    //=========================

    /// @inheritdoc IUbiquityPool
    function amoMinterBorrow(uint256 collateralAmount) external {
        LibUbiquityPool.amoMinterBorrow(collateralAmount);
    }

    //========================
    // Restricted functions
    //========================

    /// @inheritdoc IUbiquityPool
    function addAmoMinter(address amoMinterAddress) external onlyAdmin {
        LibUbiquityPool.addAmoMinter(amoMinterAddress);
    }

    /// @inheritdoc IUbiquityPool
    function addCollateralToken(
        address collateralAddress,
        address chainLinkPriceFeedAddress,
        uint256 poolCeiling
    ) external onlyAdmin {
        LibUbiquityPool.addCollateralToken(
            collateralAddress,
            chainLinkPriceFeedAddress,
            poolCeiling
        );
    }

    /// @inheritdoc IUbiquityPool
    function removeAmoMinter(address amoMinterAddress) external onlyAdmin {
        LibUbiquityPool.removeAmoMinter(amoMinterAddress);
    }

    /// @inheritdoc IUbiquityPool
    function setCollateralChainLinkPriceFeed(
        address collateralAddress,
        address chainLinkPriceFeedAddress,
        uint256 stalenessThreshold
    ) external onlyAdmin {
        LibUbiquityPool.setCollateralChainLinkPriceFeed(
            collateralAddress,
            chainLinkPriceFeedAddress,
            stalenessThreshold
        );
    }

    /// @inheritdoc IUbiquityPool
    function setFees(
        uint256 collateralIndex,
        uint256 newMintFee,
        uint256 newRedeemFee
    ) external onlyAdmin {
        LibUbiquityPool.setFees(collateralIndex, newMintFee, newRedeemFee);
    }

    /// @inheritdoc IUbiquityPool
    function setPoolCeiling(
        uint256 collateralIndex,
        uint256 newCeiling
    ) external onlyAdmin {
        LibUbiquityPool.setPoolCeiling(collateralIndex, newCeiling);
    }

    /// @inheritdoc IUbiquityPool
    function setPriceThresholds(
        uint256 newMintPriceThreshold,
        uint256 newRedeemPriceThreshold
    ) external onlyAdmin {
        LibUbiquityPool.setPriceThresholds(
            newMintPriceThreshold,
            newRedeemPriceThreshold
        );
    }

    /// @inheritdoc IUbiquityPool
    function setRedemptionDelayBlocks(
        uint256 newRedemptionDelayBlocks
    ) external onlyAdmin {
        LibUbiquityPool.setRedemptionDelayBlocks(newRedemptionDelayBlocks);
    }

    /// @inheritdoc IUbiquityPool
    function toggleCollateral(uint256 collateralIndex) external onlyAdmin {
        LibUbiquityPool.toggleCollateral(collateralIndex);
    }

    /// @inheritdoc IUbiquityPool
    function toggleMintRedeemBorrow(
        uint256 collateralIndex,
        uint8 toggleIndex
    ) external onlyAdmin {
        LibUbiquityPool.toggleMintRedeemBorrow(collateralIndex, toggleIndex);
    }
}
