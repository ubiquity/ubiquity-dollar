// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import {LibUbiquityPool} from "../libraries/LibUbiquityPool.sol";

/**
 * @notice Ubiquity pool interface
 * @notice Allows users to:
 * - deposit collateral in exchange for Ubiquity Dollars
 * - redeem Ubiquity Dollars in exchange for the earlier provided collateral
 */
interface IUbiquityPool {
    //=====================
    // Views
    //=====================

    /**
     * @notice Returns all collateral addresses
     * @return All collateral addresses
     */
    function allCollaterals() external view returns (address[] memory);

    /**
     * @notice Returns collateral information
     * @param collateralAddress Address of the collateral token
     * @return returnData Collateral info
     */
    function collateralInformation(
        address collateralAddress
    )
        external
        view
        returns (LibUbiquityPool.CollateralInformation memory returnData);

    /**
     * @notice Returns USD value of all collateral tokens held in the pool, in E18
     * @return balanceTally USD value of all collateral tokens
     */
    function collateralUsdBalance()
        external
        view
        returns (uint256 balanceTally);

    /**
     * @notice Returns free collateral balance (i.e. that can be borrowed by AMO minters)
     * @param collateralIndex collateral token index
     * @return Amount of free collateral
     */
    function freeCollateralBalance(
        uint256 collateralIndex
    ) external view returns (uint256);

    /**
     * @notice Returns Dollar value in collateral tokens
     * @param collateralIndex collateral token index
     * @param dollarAmount Amount of Dollars
     * @return Value in collateral tokens
     */
    function getDollarInCollateral(
        uint256 collateralIndex,
        uint256 dollarAmount
    ) external view returns (uint256);

    /**
     * @notice Returns Ubiquity Dollar token USD price (1e6 precision) from Curve Metapool (Ubiquity Dollar, Curve Tri-Pool LP)
     * @return dollarPriceUsd USD price of Ubiquity Dollar
     */
    function getDollarPriceUsd() external view returns (uint256 dollarPriceUsd);

    //====================
    // Public functions
    //====================

    /**
     * @notice Mints Dollars in exchange for collateral tokens
     * @param collateralIndex Collateral token index
     * @param dollarAmount Amount of dollars to mint
     * @param dollarOutMin Min amount of dollars to mint (slippage protection)
     * @param maxCollateralIn Max amount of collateral to send (slippage protection)
     * @return totalDollarMint Amount of Dollars minted
     * @return collateralNeeded Amount of collateral sent to the pool
     */
    function mintDollar(
        uint256 collateralIndex,
        uint256 dollarAmount,
        uint256 dollarOutMin,
        uint256 maxCollateralIn
    ) external returns (uint256 totalDollarMint, uint256 collateralNeeded);

    /**
     * @notice Burns redeemable Ubiquity Dollars and sends back 1 USD of collateral token for every 1 Ubiquity Dollar burned
     * @dev Redeem process is split in two steps:
     * @dev 1. `redeemDollar()`
     * @dev 2. `collectRedemption()`
     * @dev This is done in order to prevent someone using a flash loan of a collateral token to mint, redeem, and collect in a single transaction/block
     * @param collateralIndex Collateral token index being withdrawn
     * @param dollarAmount Amount of Ubiquity Dollars being burned
     * @param collateralOutMin Minimum amount of collateral tokens that'll be withdrawn, used to set acceptable slippage
     * @return collateralOut Amount of collateral tokens ready for redemption
     */
    function redeemDollar(
        uint256 collateralIndex,
        uint256 dollarAmount,
        uint256 collateralOutMin
    ) external returns (uint256 collateralOut);

    /**
     * @notice Used to collect collateral tokens after redeeming/burning Ubiquity Dollars
     * @dev Redeem process is split in two steps:
     * @dev 1. `redeemDollar()`
     * @dev 2. `collectRedemption()`
     * @dev This is done in order to prevent someone using a flash loan of a collateral token to mint, redeem, and collect in a single transaction/block
     * @param collateralIndex Collateral token index being collected
     * @return collateralAmount Amount of collateral tokens redeemed
     */
    function collectRedemption(
        uint256 collateralIndex
    ) external returns (uint256 collateralAmount);

    //=========================
    // AMO minters functions
    //=========================

    /**
     * @notice Allows AMO minters to borrow collateral to make yield in external
     * protocols like Compound, Curve, erc...
     * @dev Bypasses the gassy mint->redeem cycle for AMOs to borrow collateral
     * @param collateralAmount Amount of collateral to borrow
     */
    function amoMinterBorrow(uint256 collateralAmount) external;

    //========================
    // Restricted functions
    //========================

    /**
     * @notice Adds a new AMO minter
     * @param amoMinterAddress AMO minter address
     */
    function addAmoMinter(address amoMinterAddress) external;

    /**
     * @notice Adds a new collateral token
     * @param collateralAddress Collateral token address
     * @param chainLinkPriceFeedAddress Chainlink's price feed address
     * @param poolCeiling Max amount of available tokens for collateral
     */
    function addCollateralToken(
        address collateralAddress,
        address chainLinkPriceFeedAddress,
        uint256 poolCeiling
    ) external;

    /**
     * @notice Removes AMO minter
     * @param amoMinterAddress AMO minter address to remove
     */
    function removeAmoMinter(address amoMinterAddress) external;

    /**
     * @notice Sets collateral ChainLink price feed params
     * @param collateralAddress Collateral token address
     * @param chainLinkPriceFeedAddress ChainLink price feed address
     * @param stalenessThreshold Threshold in seconds when chainlink answer should be considered stale
     */
    function setCollateralChainLinkPriceFeed(
        address collateralAddress,
        address chainLinkPriceFeedAddress,
        uint256 stalenessThreshold
    ) external;

    /**
     * @notice Updates collateral token price in USD from ChainLink price feed
     * @param collateralIndex Collateral token index
     */
    function updateChainLinkCollateralPrice(uint256 collateralIndex) external;

    /**
     * @notice Sets mint and redeem fees, 1_000_000 = 100%
     * @param collateralIndex Collateral token index
     * @param newMintFee New mint fee
     * @param newRedeemFee New redeem fee
     */
    function setFees(
        uint256 collateralIndex,
        uint256 newMintFee,
        uint256 newRedeemFee
    ) external;

    /**
     * @notice Sets max amount of collateral for a particular collateral token
     * @param collateralIndex Collateral token index
     * @param newCeiling Max amount of collateral
     */
    function setPoolCeiling(
        uint256 collateralIndex,
        uint256 newCeiling
    ) external;

    /**
     * @notice Sets mint and redeem price thresholds, 1_000_000 = $1.00
     * @param newMintPriceThreshold New mint price threshold
     * @param newRedeemPriceThreshold New redeem price threshold
     */
    function setPriceThresholds(
        uint256 newMintPriceThreshold,
        uint256 newRedeemPriceThreshold
    ) external;

    /**
     * @notice Sets a redemption delay in blocks
     * @dev Redeeming is split in 2 actions:
     * @dev 1. `redeemDollar()`
     * @dev 2. `collectRedemption()`
     * @dev `newRedemptionDelayBlocks` sets number of blocks that should be mined after which user can call `collectRedemption()`
     * @param newRedemptionDelayBlocks Redemption delay in blocks
     */
    function setRedemptionDelayBlocks(
        uint256 newRedemptionDelayBlocks
    ) external;

    /**
     * @notice Toggles (i.e. enables/disables) a particular collateral token
     * @param collateralIndex Collateral token index
     */
    function toggleCollateral(uint256 collateralIndex) external;

    /**
     * @notice Toggles pause for mint/redeem/borrow methods
     * @param collateralIndex Collateral token index
     * @param toggleIndex Method index. 0 - toggle mint pause, 1 - toggle redeem pause, 2 - toggle borrow by AMO pause
     */
    function toggleMintRedeemBorrow(
        uint256 collateralIndex,
        uint8 toggleIndex
    ) external;
}
