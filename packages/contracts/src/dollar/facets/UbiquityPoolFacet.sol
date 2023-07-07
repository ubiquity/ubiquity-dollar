// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

// Modified from FraxPool.sol by Frax Finance
// https://github.com/FraxFinance/frax-solidity/blob/master/src/hardhat/contracts/Frax/Pools/FraxPool.sol

import {LibUbiquityPool} from "../libraries/LibUbiquityPool.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";
import {IMetaPool} from "../interfaces/IMetaPool.sol";
import "../interfaces/IUbiquityPool.sol";

contract UbiquityPoolFacet is Modifiers, IUbiquityPool {
    /// @dev Mints 1 UbiquityDollarToken for every 1USD of CollateralToken deposited
    /// @param collateralAddress address of collateral token being deposited
    /// @param collateralAmount amount of collateral tokens being deposited
    /// @param dollarOutMin minimum amount of UbiquityDollarToken that'll be minted, used to set acceptable slippage
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

    /// @dev Burn UbiquityDollarTokens and receive 1USD of collateral token for every 1 UbiquityDollarToken burned
    /// @param collateralAddress address of collateral token being withdrawn
    /// @param dollarAmount amount of UbiquityDollarTokens being burned
    /// @param collateralOutMin minimum amount of collateral tokens that'll be withdrawn, used to set acceptable slippage
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

    /// @dev used to collect collateral tokens after redeeming/burning UbiquityDollarToken
    ///     this process is split in two in order to prevent someone using a flash loan of a collateral token to mint, redeem, and collect in a single transaction/block
    /// @param collateralAddress address of the collateral token being collected
    function collectRedemption(address collateralAddress) external {
        LibUbiquityPool.collectRedemption(collateralAddress);
    }

    /// @dev admin function for whitelisting a token as collateral
    /// @param collateralAddress the address of the token being whitelisted
    /// @param collateralMetaPool 3CRV Metapool for the token being whitelisted
    function addToken(
        address collateralAddress,
        IMetaPool collateralMetaPool
    ) external onlyAdmin {
        LibUbiquityPool.addToken(collateralAddress, collateralMetaPool);
    }

    /// @dev admin function to pause and unpause redemption for a specific collateral token
    /// @param collateralAddress address of the token being affected
    /// @param notRedeemPaused true to turn on redemption for token, false to pause redemption of token
    function setRedeemActive(
        address collateralAddress,
        bool notRedeemPaused
    ) external onlyAdmin {
        LibUbiquityPool.setRedeemActive(collateralAddress, notRedeemPaused);
    }

    function getRedeemActive(
        address _collateralAddress
    ) external view returns (bool) {
        return LibUbiquityPool.getRedeemActive(_collateralAddress);
    }

    /// @dev admin function to pause and unpause minting for a specific collateral token
    /// @param collateralAddress address of the token being affected
    /// @param notMintPaused true to turn on minting for token, false to pause minting for token
    function setMintActive(
        address collateralAddress,
        bool notMintPaused
    ) external onlyAdmin {
        LibUbiquityPool.setMintActive(collateralAddress, notMintPaused);
    }

    function getMintActive(
        address _collateralAddress
    ) external view returns (bool) {
        return LibUbiquityPool.getMintActive(_collateralAddress);
    }

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
