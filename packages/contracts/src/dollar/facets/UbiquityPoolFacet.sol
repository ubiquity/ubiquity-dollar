// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

// Modified from FraxPool.sol by Frax Finance
// https://github.com/FraxFinance/frax-solidity/blob/master/src/hardhat/contracts/Frax/Pools/FraxPool.sol

import {LibUbiquityPool} from "../libraries/LibUbiquityPool.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

contract UbiquityPoolFacet is Modifiers {
    
    function mintDollar(
        address collateralAddress,
        uint256 collateralAmount,
        uint256 dollarOutMin
    ) 
        external 
    {
        LibUbiquityPool.mintDollar(collateralAddress, collateralAmount, dollarOutMin);
    }

    function redeemDollar(
        address collateralAddress,
        uint256 dollarAmount,
        uint256 collateralOutMin
    ) 
        external 
    {
        LibUbiquityPool.redeemDollar(collateralAddress, dollarAmount, collateralOutMin);
    }

    function collectRedemption(address collateralAddress) external {
        LibUbiquityPool.collectRedemption(collateralAddress);
    }

    function addToken(address collateralAddress, IMetaPool collateralMetaPool) external onlyAdmin {
        LibUbiquityPool.addToken(collateralAddress, collateralMetaPool);
    }

    function setNotRedeemPaused(
        address collateralToken,
        bool notRedeemPaused
    ) 
        external
        onlyAdmin
    {
        LibUbiquityPool.setNotRedeemPaused(collateralToken, notRedeemPaused_);
    }

    function setNotMintPaused(
        address collateralToken,
        bool notMintPaused
    ) 
        external
        onlyAdmin
    {
        LibUbiquityPool.setNotMintPaused(collateralToken, notMintPaused);
    }
}