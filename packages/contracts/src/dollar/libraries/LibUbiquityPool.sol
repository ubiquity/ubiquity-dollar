// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

// Modified from FraxPool.sol by Frax Finance
// https://github.com/FraxFinance/frax-solidity/blob/master/src/hardhat/contracts/Frax/Pools/FraxPool.sol

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {UbiquityDollarToken} from "../core/UbiquityDollarToken.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Ubiquity} from "../interfaces/IERC20Ubiquity.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IStableSwap3Pool} from "../interfaces/IStableSwap3Pool.sol";
import {IMetaPool} from "../interfaces/IMetaPool.sol";
import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";
import {LibTWAPOracle} from "./LibTWAPOracle.sol";

/**
 * @notice Ubiquity pool library
 * @notice Allows users to:
 * - deposit collateral in exchange for Ubiquity Dollars
 * - redeem Ubiquity Dollars in exchange for the earlier provided collateral
 */
library LibUbiquityPool {
    using SafeMath for uint256;
    using SafeMath for uint8;
    using SafeERC20 for IERC20;

    /// @notice Storage slot used to store data for this library
    bytes32 constant UBIQUITY_POOL_STORAGE_POSITION =
        bytes32(
            uint256(keccak256("ubiquity.contracts.ubiquity.pool.storage")) - 1
        );

    /**
     * @notice Returns struct used as a storage for this library
     * @return uPoolStorage Struct used as a storage
     */
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

    /// @notice Struct used as a storage for this library
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

    // Custom Modifiers //

    /// @notice Checks whether redeem is enabled for the `collateralAddress` token
    modifier redeemActive(address collateralAddress) {
        require(
            ubiquityPoolStorage().collateralRedeemActive[collateralAddress]
        );
        _;
    }

    /// @notice Checks whether mint is enabled for the `collateralAddress` token
    modifier mintActive(address collateralAddress) {
        require(ubiquityPoolStorage().collateralMintActive[collateralAddress]);
        _;
    }

    // User Functions //

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

    /**
     * @notice Used to collect collateral tokens after redeeming/burning Ubiquity Dollars
     * @dev Redeem process is split in two steps:
     * @dev 1. `redeemDollar()`
     * @dev 2. `collectRedemption()`
     * @dev This is done in order to prevent someone using a flash loan of a collateral token to mint, redeem, and collect in a single transaction/block
     * @param collateralAddress address of the collateral token being collected
     */
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

    // ADMIN FUNCTIONS //

    /**
     * @notice Admin function for whitelisting a token as collateral
     * @param collateralAddress Address of the token being whitelisted
     * @param collateralMetaPool 3CRV Metapool for the token being whitelisted
     */
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
    ) internal view returns (uint256) {
        return
            ubiquityPoolStorage().redeemCollateralBalances[account][
                collateralAddress
            ];
    }

    /**
     * @notice Admin function to pause and unpause redemption for a specific collateral token
     * @param collateralAddress Address of the token being affected
     * @param notRedeemPaused True to turn on redemption for token, false to pause redemption of token
     */
    function setRedeemActive(
        address collateralAddress,
        bool notRedeemPaused
    ) internal {
        ubiquityPoolStorage().collateralRedeemActive[
            collateralAddress
        ] = notRedeemPaused;
    }

    /**
     * @notice Checks whether redeem is enabled for the `collateralAddress` token
     * @param collateralAddress Token address to check
     * @return Whether redeem is enabled for the `collateralAddress` token
     */
    function getRedeemActive(
        address collateralAddress
    ) internal view returns (bool) {
        return ubiquityPoolStorage().collateralRedeemActive[collateralAddress];
    }

    /**
     * @notice Checks whether mint is enabled for the `collateralAddress` token
     * @param collateralAddress Token address to check
     * @return Whether mint is enabled for the `collateralAddress` token
     */
    function getMintActive(
        address collateralAddress
    ) internal view returns (bool) {
        return ubiquityPoolStorage().collateralMintActive[collateralAddress];
    }

    /**
     * @notice Admin function to pause and unpause minting for a specific collateral token
     * @param collateralAddress Address of the token being affected
     * @param notMintPaused True to turn on minting for token, false to pause minting for token
     */
    function setMintActive(
        address collateralAddress,
        bool notMintPaused
    ) internal {
        ubiquityPoolStorage().collateralMintActive[
            collateralAddress
        ] = notMintPaused;
    }

    // CHECK FUNCTIONS //

    /**
     * @notice Checks whether `collateralAddress` token is approved by admin to be used as a collateral
     * @param collateralAddress Token address
     * @return isCollateral Whether token is approved to be used as a collateral
     */
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

    // CALC FUNCTIONS //

    /**
     * @notice Returns the amount of dollars to mint
     * @param collateralAmountD18 Amount of collateral tokens
     * @param collateralPriceCurve3Pool USD price of a single collateral token
     * @param curve3PriceUSD USD price from the Curve Tri-Pool (DAI, USDC, USDT)
     * @return dollarOut Amount of Ubiquity Dollars to mint
     */
    function calcMintDollarAmount(
        uint256 collateralAmountD18,
        uint256 collateralPriceCurve3Pool,
        uint256 curve3PriceUSD
    ) internal pure returns (uint256 dollarOut) {
        dollarOut = collateralAmountD18.mul(collateralPriceCurve3Pool).div(
            curve3PriceUSD
        );
    }

    /**
     * @notice Returns the amount of collateral tokens ready for collecting
     * @dev Redeem process is split in two steps:
     * @dev 1. `redeemDollar()`
     * @dev 2. `collectRedemption()`
     * @dev This is done in order to prevent someone using a flash loan of a collateral token to mint, redeem, and collect in a single transaction/block
     * @param dollarAmountD18 Amount of Ubiquity Dollars to redeem
     * @param collateralPriceCurve3Pool USD price of a single collateral token
     * @param curve3PriceUSD USD price from the Curve Tri-Pool (DAI, USDC, USDT)
     * @return collateralOut Amount of collateral tokens ready to be collectable
     */
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

    /**
     * @notice Returns Ubiquity Dollar token USD price from Metapool (Ubiquity Dollar, Curve Tri-Pool LP)
     * @return dollarPriceUSD USD price of Ubiquity Dollar
     */
    function getDollarPriceUsd()
        internal
        view
        returns (uint256 dollarPriceUSD)
    {
        dollarPriceUSD = LibTWAPOracle.getTwapPrice();
    }

    /**
     * @notice Returns the latest price of the `collateralAddress` token from Curve Metapool
     * @param collateralAddress Collateral token address
     * @return collateralPriceCurve3Pool Collateral token price from Curve Metapool
     */
    function getCollateralPriceCurve3Pool(
        address collateralAddress
    ) internal view returns (uint256 collateralPriceCurve3Pool) {
        IMetaPool collateralMetaPool = ubiquityPoolStorage()
            .collateralMetaPools[collateralAddress];

        collateralPriceCurve3Pool = collateralMetaPool
            .get_price_cumulative_last()[0];
    }

    /**
     * @notice Returns USD price from Tri-Pool (DAI, USDC, USDT)
     * @return curve3PriceUSD USD price
     */
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
