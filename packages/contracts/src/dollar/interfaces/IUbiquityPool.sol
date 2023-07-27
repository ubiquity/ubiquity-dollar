// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.19;

import {IMetaPool} from "./IMetaPool.sol";

/**
 * @notice Ubiquity pool interface
 * @notice Allows users to:
 * - deposit collateral in exchange for Ubiquity Dollars
 * - redeem Ubiquity Dollars in exchange for the earlier provided collateral
 */
interface IUbiquityPool {
    /**
     * @notice Mints 1 Ubiquity Dollar for every 1 USD of `collateralAddress` token deposited
     * @param collateralAddress address of collateral token being deposited
     * @param collateralAmount amount of collateral tokens being deposited
     * @param dollarOutMin minimum amount of Ubiquity Dollars that'll be minted, used to set acceptable slippage
     */
    function mintDollar(
        address collateralAddress,
        uint256 collateralAmount,
        uint256 dollarOutMin
    ) external;

    /**
     * @notice Burns redeemable Ubiquity Dollars and sends back 1 USD of collateral token for every 1 Ubiquity Dollar burned
     * @dev Redeem process is split in two steps:
     * @dev 1. `redeemDollar()`
     * @dev 2. `collectRedemption()`
     * @dev This is done in order to prevent someone using a flash loan of a collateral token to mint, redeem, and collect in a single transaction/block
     * @param collateralAddress address of collateral token being withdrawn
     * @param dollarAmount amount of Ubiquity Dollars being burned
     * @param collateralOutMin minimum amount of collateral tokens that'll be withdrawn, used to set acceptable slippage
     */
    function redeemDollar(
        address collateralAddress,
        uint256 dollarAmount,
        uint256 collateralOutMin
    ) external;

    /**
     * @notice Used to collect collateral tokens after redeeming/burning Ubiquity Dollars
     * @dev Redeem process is split in two steps:
     * @dev 1. `redeemDollar()`
     * @dev 2. `collectRedemption()`
     * @dev This is done in order to prevent someone using a flash loan of a collateral token to mint, redeem, and collect in a single transaction/block
     * @param collateralAddress address of the collateral token being collected
     */
    function collectRedemption(address collateralAddress) external;

    /**
     * @notice Admin function for whitelisting a token as collateral
     * @param collateralAddress Address of the token being whitelisted
     * @param collateralMetaPool 3CRV Metapool for the token being whitelisted
     */
    function addToken(
        address collateralAddress,
        IMetaPool collateralMetaPool
    ) external;

    /**
     * @notice Admin function to pause and unpause redemption for a specific collateral token
     * @param collateralAddress Address of the token being affected
     * @param notRedeemPaused True to turn on redemption for token, false to pause redemption of token
     */
    function setRedeemActive(
        address collateralAddress,
        bool notRedeemPaused
    ) external;

    /**
     * @notice Checks whether redeem is enabled for the `_collateralAddress` token
     * @param _collateralAddress Token address to check
     * @return Whether redeem is enabled for the `_collateralAddress` token
     */
    function getRedeemActive(
        address _collateralAddress
    ) external view returns (bool);

    /**
     * @notice Admin function to pause and unpause minting for a specific collateral token
     * @param collateralAddress Address of the token being affected
     * @param notMintPaused True to turn on minting for token, false to pause minting for token
     */
    function setMintActive(
        address collateralAddress,
        bool notMintPaused
    ) external;

    /**
     * @notice Checks whether mint is enabled for the `_collateralAddress` token
     * @param _collateralAddress Token address to check
     * @return Whether mint is enabled for the `_collateralAddress` token
     */
    function getMintActive(
        address _collateralAddress
    ) external view returns (bool);

    /**
     * @notice Returns the amount of collateral ready for collecting after redeeming
     * @dev Redeem process is split in two steps:
     * @dev 1. `redeemDollar()`
     * @dev 2. `collectRedemption()`
     * @dev This is done in order to prevent someone using a flash loan of a collateral token to mint, redeem, and collect in a single transaction/block
     * @param account Account address for which to check the balance ready to be collected
     * @param collateralAddress Collateral token address
     * @return Collateral token balance ready to be collected after redeeming
     */
    function getRedeemCollateralBalances(
        address account,
        address collateralAddress
    ) external view returns (uint256);
}
