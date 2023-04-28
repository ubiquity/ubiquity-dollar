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
import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";


library LibUbiquityPool {
    using SafeMath for uint256;

    bytes32 constant UBIQUITY_POOL_STORAGE_POSITION = 
        keccak256("ubiquity.contracts.ubiquity.pool.storage");

    function ubiquityPoolStorage() 
        internal 
        pure 
        returns(UbiquityPoolStorage storage uPoolStorage) 
    {
        bytes32 position = UBIQUITY_POOL_STORAGE_POSITION;
        assembly {
            uPoolStorage.slot := position
        }
    }

    struct UbiquityPoolStorage {
        /* ========== STATE VARIABLES ========== */

        
        address[] collateralAddresses;
        mapping(address => IMetaPool) collateralMetaPools;
        mapping(address => uint8) missingDecimals;
        mapping(address => uint256) tokenBalances;
        mapping(address => bool) collateralNotRedeemPaused;
        mapping(address => bool) collateralNotMintPaused;
        
        //address timelockAddress;
        
        UbiquityDollarToken ubiquityDollarToken;
        IMetaPool dollarMetaPool;

        IStableSwap3Pool curve3Pool;
        address curve3PoolAddress;

        uint256 mintingFee;
        uint256 redemptionFee;

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

    /// Custom Modifiers ///

    modifier notRedeemPaused(address collateralAddress) {
        require(ubiquityPoolStorage().collateralNotRedeemPaused[collateralAddress]);
        _;
    }

    modifier notMintPaused(address collateralAddress) {
        require(ubiquityPoolStorage().collateralNotMintPaused[collateralAddress]);
        _;
    }

    /// User Functions ///

    function mintDollar(
        address collateralAddress, 
        uint256 collateralAmount, 
        uint256 dollarOutMin
    ) 
        internal
        notMintPaused(collateralAddress)
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
            getCollateralPriceCurve3(collateralAddress), 
            getCurve3PriceUSD());

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
    ) 
        internal 
        notRedeemPaused(collateralAddress)
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
            getCollateralPriceCurve3(collateralAddress), 
            getCurve3PriceUSD());
        
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

    function collectRedemption(address collateralAddress) internal {
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();
        require(
            poolStorage.lastRedeemed[msg.sender] + poolStorage.redemptionDelay >= block.number,
            "Must wait for redemptionDelay blocks before collecting");
        
        bool sendCollateral = false;
        uint256 collateralAmount = 0;

        if(poolStorage.redeemCollateralBalances[msg.sender][collateralAddress] > 0){
            collateralAmount = poolStorage.redeemCollateralBalances[msg.sender][collateralAddress];
            poolStorage.redeemCollateralBalances[msg.sender][collateralAddress] = 0;
            poolStorage.unclaimedPoolCollateral[collateralAddress] = poolStorage.unclaimedPoolCollateral[collateralAddress].sub(collateralAmount);

            sendCollateral = true;

            if(sendCollateral){
                TransferHelper.safeTransfer(collateralAddress, msg.sender, collateralAmount);
            }
        }
    }

    /// ADMIN FUNCTIONS ///

    function addToken(address collateralAddress, IMetaPool collateralMetaPool) internal {
        require(collateralAddress != 0x0 && address(collateralMetaPool) != 0x0, "0 address detected");
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();

        poolStorage.collateralAddresses.push(collateralAddress);
        poolStorage.collateralMetaPools[collateralAddress] = collateralMetaPool;
        poolStorage.missingDecimals[collateralAddress] = 18.sub(IERC20(collateralAddress).decimals);
    }

    function setNotRedeemPaused(
        address collateralToken,
        bool notRedeemPaused_
    )
        internal
    {
        ubiquityPoolStorage().collateralNotRedeemPaused[collateralAddress] = 
            notRedeemPaused_;
    }

    function setNotMintPaused(
        address collateralToken,
        bool notMintPaused_
    )
        internal
    {
        ubiquityPoolStorage().collateralNotMintPaused[collateralAddress] = 
            notMintPaused_;
    }

    function initialize(
        IMetaPool dollarMetaPool_,
        address curve3PoolAddress_,
        uint256 mintingFee_,
        uint256 redemptionFee_
    )
        internal 
    {
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();
        AppStorage storage store = LibAppStorage.appStorage();
        poolStorage.dollarMetaPool = dollarMetaPool_;
        poolStorage.ubiquityDollarToken = IERC20(store.dollarTokenAddress);
        poolStorage.curve3Pool = StableSwapPool(curve3PoolAddress_);
        poolStorage.mintingFee = mintingFee_;
        poolStorage.redemptionFee = redemptionFee_;
        
    }

    /// CHECK FUNCTIONS ///

    function checkCollateralToken(
        address collateralAddress
    ) 
        internal 
        returns(bool isCollateral) 
    {
        address[] memory collateralAddresses_ = ubiquityPoolStorage().collateralAddresses;
        for(uint256 i; i < collateralAddresses_.length; ++i){
            if(collateralAddress == collateralAddresses_[i]){
                isCollateral = true;
            }
        }
    }

    /// CALC FUNCTIONS ///

    function calcMintDollarAmount(
        uint256 collateralAmountD18, 
        uint256 collateralPriceCurve3, 
        uint256 curve3PriceUSD
    ) 
        internal 
        pure 
        returns(uint256 dollarOut) 
    {
        dollarOut = collateralAmountD18.mul(collateralPriceUSD).div(curve3PriceUSD);
    }

    function calcRedeemCollateralAmount(
        uint256 dollarAmountD18, 
        uint256 collateralPriceCurve3, 
        uint256 curve3PriceUSD
    ) 
        internal 
        pure 
        returns(uint256 collateralOut) 
    {
        uint256 collteralPriceUSD = (collateralPriceCurve3.mul(10e18)).div(curve3PriceUSD);
        collateralOut = (dollarAmountD18.mul(10e18)).div(collateralPriceUSD);
    }

    function getDollarPriceUSD() 
        internal 
        returns(uint256 dollarPriceUSD) 
    {
        uint256 dollarPrice = ubiquityPoolStorage().dollarMetaPool.get_dy(0, 1, 10e18);
        uint256 curve3PriceUSD = getCurve3PriceUSD();
        dollarPriceUSD = (dollarPrice.mul(10e18)).div(curve3PriceUSD);
    }

    function getCollateralPriceCurve3(
        address collateralAddress
    ) 
        internal 
        returns(uint256 collateralPriceCurve3) 
    {
        IMetaPool collateralMetaPool = ubiquityPoolStorage().collateralMetaPools[collateralAddress];
        collateralPriceCurve3 = collateralMetaPool.get_dy(0, 1, 10e18);
    }

    function getCurve3PriceUSD() internal returns(uint256 curve3PriceUSD) {
        curve3PriceUSD = ubiquityPoolStorage().curve3Pool.get_virtual_price();
    }
}