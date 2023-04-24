// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

// Modified from FraxPool.sol by Frax Finance
// https://github.com/FraxFinance/frax-solidity/blob/master/src/hardhat/contracts/Frax/Pools/FraxPool.sol

import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {UbiquityDollarToken} from "../core/UbiquityDollarToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
//import "../../Governance/AccessControl.sol";
import {IStableSwap3Pool} from "../interfaces/IStableSwap3Pool.sol";
import {IMetaPool} from "../interfaces/IMetaPool.sol";
import {LibAppStorage} from "./LibAppStorage.sol";

library LibUbiquityPool {
    using SafeMath for uint256;

    bytes32 constant UBIQUITY_POOL_STORAGE_POSITION = 
        keccak256("ubiquity.contracts.ubiquity.pool.storage");

    function ubiquityPoolStorage() internal pure returns(UbiquityPoolStorage storage uPoolStorage) {
        bytes32 position = UBIQUITY_POOL_STORAGE_POSITION;
        assembly {
            uPoolStorage.slot := position
        }
    }

    struct UbiquityPoolStorage {
        /* ========== STATE VARIABLES ========== */

        
        address[] collateralAddresses;
        mapping(address => IMetaPool) collatMetaPools;
        mapping(address => uint256) missingDecimals;
        mapping(address => uint256) tokenBalances;
        
        address timelockAddress;
        
        address ubiquityDollarTokenAddress;
        UbiquityDollarToken ubiquityDollarToken;
        IMetaPool dollarMetaPool;
        address dollarTWAPOracleAddress;

        IStableSwap3Pool curve3Pool;
        address curve3PoolAddress;

        uint256 mintingFee;
        uint256 redemptionFee;
        uint256 buybackFee;
        uint256 recollatFee;

        mapping (address => mapping(address => uint256)) redeemCollateralBalances;
        mapping (address => uint256) unclaimedPoolCollateral;
        mapping (address => uint256) lastRedeemed;

        
        // Pool_ceiling is the total units of collateral that a pool contract can hold
        uint256 poolCeiling;

        // Stores price of the collateral, if price is paused
        uint256 pausedPrice;

        // Number of blocks to wait before being able to collectRedemption()
        uint256 redemptionDelay;

        // Min USD value of UbiquityDollar for minting to happen
        uint256 dollarFloor;
    }

    function mintDollar(
        address collateralAddress, 
        uint256 collateralAmount, 
        uint256 dollarOutMin
        ) external 
    {   
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();
        uint256 dollarPriceUSD = getDollarPriceUSD();
        require(
            checkCollateralToken(collateralAddress), 
            "Collateral Token not approved"
        );
        require(
            dollarPriceUSD >= poolStorage.dollarFloor, 
            "UbiquytyDollar value must be 1 USD or greater to mint"
        );

        uint256 collateralAmountD18 = collateralAmount * poolStorage.missingDecimals[collateralAddress];

        uint256 dollarAmountD18 = calcMintDollarAmount(
            collateralAmountD18, 
            getCollateralPriceUSD(collateralAddress), 
            dollarPriceUSD);

        dollarAmountD18 = dollarAmountD18.sub(poolStorage.mintingFee);
        require(dollarOutMin <= dollarAmountD18, "Slippage limit reached");

        ubiquityPoolStorage().tokenBalances[collateralAddress] = 
            poolStorage.tokenBalances[collateralAddress]
            .add(collateralAmount);

        TransferHelper.safeTransferFrom(collateralAddress, msg.sender, address(this), collateralAmount);
        poolStorage.ubiquityDollarToken.mint(msg.sender, dollarAmountD18);
    }

    function redeemDollar(
        address collateralAddress,
        uint256 dollarAmount,
        uint256 collateralOutMin
    ) external 
    {   
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();

        uint256 dollarPriceUSD = getDollarPriceUSD();

        require(
            checkCollateralToken(collateralAddress), 
            "Collateral Token not approved"
        );
        require(
            dollarPriceUSD < poolStorage.dollarFloor,
            "UbiquityDollar value must be less than 1 USD to redeem"
        );
        
        uint256 dollarAmountPrecision = 
            dollarAmount.div(
                10 ** poolStorage.missingDecimals[collateralAddress]
            );
        uint256 collateralOut = calcRedeemCollateralAmount(
            dollarAmountPrecision, 
            getCollateralPriceUSD(collateralAddress), 
            dollarPriceUSD);
        
        collateralOut = collateralOut.sub(poolStorage.redemptionFee);

        require(
            collateralOut <= 
            poolStorage.tokenBalances[collateralAddress].sub(
                poolStorage.unclaimedPoolCollateral[collateralAddress]
            ), 
            "Requested amount exceeds balance"
        );
        require(
            collateralOutMin <= collateralOut,
            "Slippage limit reached"
        );

        poolStorage.redeemCollateralBalances[msg.sender][collateralAddress] =
            poolStorage.redeemCollateralBalances[
                msg.sender] 
                [collateralAddress]
            .add(collateralOut);

        poolStorage.unclaimedPoolCollateral[collateralAddress] =
            poolStorage.unclaimedPoolCollateral[     collateralAddress]
            .add(collateralOut);

        poolStorage.lastRedeemed[msg.sender] = block.number;
    }

    function collectRedemption() external {
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();
        require(
            poolStorage.lastRedeemed[msg.sender] + poolStorage.redemptionDelay >= block.number,
            "Must wait for redemptionDelay blocks before collecting");
    }

    function checkCollateralToken(
        address collateralAddress
        ) internal 
        returns(bool isCollateral) 
    {
        address[] memory collateralAddresses_ = ubiquityPoolStorage().collateralAddresses;
        for(uint256 i; i < collateralAddresses_.length; ++i){
            if(collateralAddress == collateralAddresses_[i]){
                isCollateral = true;
            }
        }
    }

    function calcMintDollarAmount(
        uint256 collateralAmountD18, 
        uint256 collateralPriceUSD, 
        uint256 dollarPriceUSD
        ) internal 
        pure 
        returns(uint256 dollarOut) 
    {
        dollarOut = collateralAmountD18.mul(collateralPriceUSD).div(dollarPriceUSD);
    }

    function calcRedeemCollateralAmount(
        uint256 dollarAmountD18, 
        uint256 collateralPriceUSD, 
        uint256 dollarPriceUSD
        ) internal 
        pure 
        returns(uint256 collateralOut) 
    {
        collateralOut = dollarAmountD18.mul(dollarPriceUSD).div(collateralPriceUSD);
    }

    function getDollarPriceUSD() 
        internal 
        returns(uint256 dollarPriceUSD) 
    {
        uint256 dollarPrice = ubiquityPoolStorage().dollarMetaPool.get_dy(0, 1, 10e18);
        uint256 curve3PriceUSD = getCurve3PriceUSD();
        dollarPriceUSD = (dollarPrice.mul(10e18)).div(curve3PriceUSD);
    }

    function getCollateralPriceUSD(
        address collateralAddress
        ) 
        internal 
        returns(uint256 collateralPriceUSD) 
    {
        IMetaPool collatMetaPool = ubiquityPoolStorage().collatMetaPools[collateralAddress];
        uint256 collateralPrice = collatMetaPool.get_dy(0, 1, 10e18);
        uint256 curve3PriceUSD = getCurve3PriceUSD();
        collateralPriceUSD = (collateralPrice.mul(10e18)).div(curve3PriceUSD);
    }

    function getCurve3PriceUSD() internal returns(uint256 curve3PriceUSD) {
        curve3PriceUSD = ubiquityPoolStorage().curve3Pool.get_virtual_price();
    }
}