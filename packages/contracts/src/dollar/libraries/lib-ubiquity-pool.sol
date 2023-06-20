// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

// Modified from FraxPool.sol by Frax Finance
// https://github.com/FraxFinance/frax-solidity/blob/master/src/hardhat/contracts/Frax/Pools/FraxPool.sol

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {UbiquityDollarToken} from "../core/ubiquity-dollar-token.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Ubiquity} from "../interfaces/ierc-20-ubiquity.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IStableSwap3Pool} from "../interfaces/i-stable-swap-3-pool.sol";
import {IMetaPool} from "../interfaces/i-meta-pool.sol";
import {LibAppStorage, AppStorage} from "./lib-app-storage.sol";
import {LibTWAPOracle} from "./lib-twap-oracle.sol";

library LibUbiquityPool {
    using SafeMath for uint256;
    using SafeMath for uint8;
    using SafeERC20 for IERC20;

    bytes32 constant UBIQUITY_POOL_STORAGE_POSITION =
        bytes32(
            uint256(keccak256("ubiquity.contracts.ubiquity.pool.storage")) - 1
        );

    function ubiquityPoolStorage()
        internal
        pure
        returns (UbiquityPoolStorage storage uPoolStorage)
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
        mapping(address => bool) collateralRedeemActive;
        mapping(address => bool) collateralMintActive;
        uint256 mintingFee;
        uint256 redemptionFee;
        mapping(address => mapping(address => uint256)) redeemCollateralBalances;
        mapping(address => uint256) unclaimedPoolCollateral;
        mapping(address => uint256) lastRedeemed;
        // Pool_ceiling is the total units of collateral that a pool contract can hold
        uint256 poolCeiling;
        // Stores price of the collateral, if price is paused
        uint256 pausedPrice;
        // Number of blocks to wait before being able to collectRedemption()
        uint256 redemptionDelay;
        // Min USD value of UbiquityDollarToken for minting to happen
        uint256 dollarFloor;
    }

    /// Custom Modifiers ///

    modifier redeemActive(address collateralAddress) {
        require(
            ubiquityPoolStorage().collateralRedeemActive[collateralAddress]
        );
        _;
    }

    modifier mintActive(address collateralAddress) {
        require(ubiquityPoolStorage().collateralMintActive[collateralAddress]);
        _;
    }

    /// User Functions ///

    function mintDollar(
        address collateralAddress,
        uint256 collateralAmount,
        uint256 dollarOutMin
    ) internal mintActive(collateralAddress) {
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();
        uint256 dollarPriceUSD = getDollarPriceUsd();
        require(
            checkCollateralToken(collateralAddress),
            "Collateral Token not approved"
        );
        require(
            dollarPriceUSD >= poolStorage.dollarFloor,
            "Ubiquity Dollar Token value must be 1 USD or greater to mint"
        );

        uint8 missingDecimals = poolStorage.missingDecimals[collateralAddress];
        uint256 collateralAmountD18 = missingDecimals > 0
            ? collateralAmount * poolStorage.missingDecimals[collateralAddress]
            : collateralAmount;

        uint256 dollarAmountD18 = calcMintDollarAmount(
            collateralAmountD18,
            getCollateralPriceCurve3Pool(collateralAddress),
            getCurve3PriceUSD()
        );

        dollarAmountD18 = dollarAmountD18.sub(poolStorage.mintingFee);
        require(dollarOutMin <= dollarAmountD18, "Slippage limit reached");
        IERC20(collateralAddress).safeTransferFrom(
            msg.sender,
            address(this),
            collateralAmount
        );

        poolStorage.tokenBalances[collateralAddress] = poolStorage
            .tokenBalances[collateralAddress]
            .add(collateralAmount);

        IERC20Ubiquity ubiquityDollarToken = IERC20Ubiquity(
            LibAppStorage.appStorage().dollarTokenAddress
        );
        ubiquityDollarToken.mint(msg.sender, dollarAmountD18);
    }

    function redeemDollar(
        address collateralAddress,
        uint256 dollarAmount,
        uint256 collateralOutMin
    ) internal redeemActive(collateralAddress) {
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();

        uint256 dollarPriceUSD = getDollarPriceUsd();

        require(
            checkCollateralToken(collateralAddress),
            "Collateral Token not approved"
        );
        require(
            dollarPriceUSD < poolStorage.dollarFloor,
            "Ubiquity Dollar Token value must be less than 1 USD to redeem"
        );

        uint256 dollarAmountPrecision = dollarAmount.div(
            10 ** poolStorage.missingDecimals[collateralAddress]
        );
        uint256 collateralOut = calcRedeemCollateralAmount(
            dollarAmountPrecision,
            getCollateralPriceCurve3Pool(collateralAddress),
            getCurve3PriceUSD()
        );

        collateralOut = collateralOut.sub(poolStorage.redemptionFee);

        require(
            collateralOut <=
                poolStorage.tokenBalances[collateralAddress].sub(
                    poolStorage.unclaimedPoolCollateral[collateralAddress]
                ),
            "Requested amount exceeds balance"
        );
        require(collateralOutMin <= collateralOut, "Slippage limit reached");

        poolStorage.redeemCollateralBalances[msg.sender][
            collateralAddress
        ] = poolStorage
        .redeemCollateralBalances[msg.sender][collateralAddress].add(
                collateralOut
            );

        poolStorage.unclaimedPoolCollateral[collateralAddress] = poolStorage
            .unclaimedPoolCollateral[collateralAddress]
            .add(collateralOut);

        poolStorage.lastRedeemed[msg.sender] = block.number;
        IERC20Ubiquity ubiquityDollarToken = IERC20Ubiquity(
            LibAppStorage.appStorage().dollarTokenAddress
        );
        ubiquityDollarToken.burnFrom(msg.sender, dollarAmount);
    }

    function collectRedemption(address collateralAddress) internal {
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();
        require(
            poolStorage.lastRedeemed[msg.sender] +
                poolStorage.redemptionDelay >=
                block.number,
            "Too soon to collect"
        );

        bool sendCollateral = false;
        uint256 collateralAmount = 0;

        if (
            poolStorage.redeemCollateralBalances[msg.sender][
                collateralAddress
            ] > 0
        ) {
            collateralAmount = poolStorage.redeemCollateralBalances[msg.sender][
                collateralAddress
            ];
            poolStorage.redeemCollateralBalances[msg.sender][
                collateralAddress
            ] = 0;
            poolStorage.unclaimedPoolCollateral[collateralAddress] = poolStorage
                .unclaimedPoolCollateral[collateralAddress]
                .sub(collateralAmount);

            sendCollateral = true;

            if (sendCollateral) {
                IERC20(collateralAddress).transfer(
                    msg.sender,
                    collateralAmount
                );
            }
        }
    }

    /// ADMIN FUNCTIONS ///

    function addToken(
        address collateralAddress,
        IMetaPool collateralMetaPool
    ) internal {
        require(
            collateralAddress != address(0x0) &&
                address(collateralMetaPool) != address(0x0),
            "0 address detected"
        );
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();
        uint256 defaultDecimals = 18;
        uint256 collateralDecimals = uint256(
            IERC20Metadata(collateralAddress).decimals()
        );

        poolStorage.collateralAddresses.push(collateralAddress);
        poolStorage.collateralMetaPools[collateralAddress] = collateralMetaPool;
        poolStorage.missingDecimals[collateralAddress] = uint8(
            defaultDecimals.sub(collateralDecimals)
        );
    }

    function getRedeemCollateralBalances(
        address account,
        address collateralAddress
    ) internal view returns (uint256) {
        return
            ubiquityPoolStorage().redeemCollateralBalances[account][
                collateralAddress
            ];
    }

    function setRedeemActive(
        address collateralAddress,
        bool redeemPaused_
    ) internal {
        ubiquityPoolStorage().collateralRedeemActive[
            collateralAddress
        ] = redeemPaused_;
    }

    function getRedeemActive(
        address collateralAddress
    ) internal view returns (bool) {
        return ubiquityPoolStorage().collateralRedeemActive[collateralAddress];
    }

    function getMintActive(
        address collateralAddress
    ) internal view returns (bool) {
        return ubiquityPoolStorage().collateralMintActive[collateralAddress];
    }

    function setMintActive(
        address collateralAddress,
        bool mintPaused_
    ) internal {
        ubiquityPoolStorage().collateralMintActive[
            collateralAddress
        ] = mintPaused_;
    }

    /// CHECK FUNCTIONS ///

    function checkCollateralToken(
        address collateralAddress
    ) internal view returns (bool isCollateral) {
        address[] memory collateralAddresses_ = ubiquityPoolStorage()
            .collateralAddresses;
        for (uint256 i; i < collateralAddresses_.length; ++i) {
            if (collateralAddress == collateralAddresses_[i]) {
                isCollateral = true;
            }
        }
    }

    /// CALC FUNCTIONS ///

    function calcMintDollarAmount(
        uint256 collateralAmountD18,
        uint256 collateralPriceCurve3Pool,
        uint256 curve3PriceUSD
    ) internal pure returns (uint256 dollarOut) {
        dollarOut = collateralAmountD18.mul(collateralPriceCurve3Pool).div(
            curve3PriceUSD
        );
    }

    function calcRedeemCollateralAmount(
        uint256 dollarAmountD18,
        uint256 collateralPriceCurve3Pool,
        uint256 curve3PriceUSD
    ) internal pure returns (uint256 collateralOut) {
        uint256 collateralPriceUSD = (collateralPriceCurve3Pool.mul(10e18)).div(
            curve3PriceUSD
        );
        collateralOut = (dollarAmountD18.mul(10e18)).div(collateralPriceUSD);
    }

    function getDollarPriceUsd()
        internal
        view
        returns (uint256 dollarPriceUSD)
    {
        dollarPriceUSD = LibTWAPOracle.getTwapPrice();
    }

    function getCollateralPriceCurve3Pool(
        address collateralAddress
    ) internal view returns (uint256 collateralPriceCurve3Pool) {
        IMetaPool collateralMetaPool = ubiquityPoolStorage()
            .collateralMetaPools[collateralAddress];

        collateralPriceCurve3Pool = collateralMetaPool
            .get_price_cumulative_last()[0];
    }

    function getCurve3PriceUSD()
        internal
        view
        returns (uint256 curve3PriceUSD)
    {
        curve3PriceUSD = LibTWAPOracle.consult(
            LibAppStorage.appStorage().curve3PoolTokenAddress
        );
    }
}
