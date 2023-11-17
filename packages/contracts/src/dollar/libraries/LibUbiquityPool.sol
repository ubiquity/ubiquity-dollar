// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IDollarAmoMinter} from "../interfaces/IDollarAmoMinter.sol";
import {IERC20Ubiquity} from "../interfaces/IERC20Ubiquity.sol";
import {UBIQUITY_POOL_PRICE_PRECISION} from "./Constants.sol";
import {LibAppStorage} from "./LibAppStorage.sol";
import {LibTWAPOracle} from "./LibTWAPOracle.sol";

/**
 * @notice Ubiquity pool library
 * @notice Allows users to:
 * - deposit collateral in exchange for Ubiquity Dollars
 * - redeem Ubiquity Dollars in exchange for the earlier provided collateral
 * @dev Modified from https://github.com/FraxFinance/frax-solidity/blob/fc9810d72c520d256965b81b6c9cc6aa95d07d9d/src/hardhat/contracts/Frax/Pools/FraxPoolV3.sol
 */
library LibUbiquityPool {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /// @notice Storage slot used to store data for this library
    bytes32 constant UBIQUITY_POOL_STORAGE_POSITION =
        bytes32(
            uint256(keccak256("ubiquity.contracts.ubiquity.pool.storage")) - 1
        );

    /// @notice Struct used as a storage for this library
    struct UbiquityPoolStorage {
        //========
        // Core
        //========
        // minter address -> is it enabled
        mapping(address => bool) amoMinterAddresses;
        //======================
        // Collateral related
        //======================
        // available collateral tokens
        address[] collateralAddresses;
        // collateral address -> collateral index
        mapping(address => uint256) collateralAddressToIndex;
        // Stores price of the collateral, if price is paused. CONSIDER ORACLES EVENTUALLY!!!
        uint256[] collateralPrices;
        // array collateral symbols
        string[] collateralSymbols;
        // collateral address -> is it enabled
        mapping(address => bool) enabledCollaterals;
        // Number of decimals needed to get to E18. collateral index -> missing_decimals
        uint256[] missingDecimals;
        // Total across all collaterals. Accounts for missing_decimals
        uint256[] poolCeilings;
        //====================
        // Redeem related
        //====================
        // user -> block number (collateral independent)
        mapping(address => uint256) lastRedeemed;
        // 1010000 = $1.01
        uint256 mintPriceThreshold;
        // 990000 = $0.99
        uint256 redeemPriceThreshold;
        // address -> collateral index -> balance
        mapping(address => mapping(uint256 => uint256)) redeemCollateralBalances;
        // number of blocks to wait before being able to collectRedemption()
        uint256 redemptionDelay;
        // collateral index -> balance
        uint256[] unclaimedPoolCollateral;
        //================
        // Fees related
        //================
        // minting fee of a particular collateral index, 1_000_000 = 100%
        uint256[] mintingFee;
        // redemption fee of a particular collateral index, 1_000_000 = 100%
        uint256[] redemptionFee;
        //=================
        // Pause related
        //=================
        // whether borrowing collateral by AMO minters is paused for a particular collateral index
        bool[] borrowingPaused;
        // whether minting is paused for a particular collateral index
        bool[] mintPaused;
        // whether redeeming is paused for a particular collateral index
        bool[] redeemPaused;
    }

    /// @notice Struct used for detailed collateral information
    struct CollateralInformation {
        uint256 index;
        string symbol;
        address collateralAddress;
        bool isEnabled;
        uint256 missingDecimals;
        uint256 price;
        uint256 poolCeiling;
        bool mintPaused;
        bool redeemPaused;
        bool borrowingPaused;
        uint256 mintingFee;
        uint256 redemptionFee;
    }

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

    //===========
    // Events
    //===========

    /// @notice Emitted when new AMO minter is added
    event AmoMinterAdded(address amoMinterAddress);
    /// @notice Emitted when AMO minter is removed
    event AmoMinterRemoved(address amoMinterAddress);
    /// @notice Emitted on setting a collateral price
    event CollateralPriceSet(uint256 collateralIndex, uint256 newPrice);
    /// @notice Emitted on enabling/disabling a particular collateral token
    event CollateralToggled(uint256 collateralIndex, bool newState);
    /// @notice Emitted when fees are updated
    event FeesSet(
        uint256 collateralIndex,
        uint256 newMintFee,
        uint256 newRedeemFee
    );
    /// @notice Emitted on toggling pause for mint/redeem/borrow
    event MRBToggled(uint256 collateralIndex, uint8 toggleIndex);
    /// @notice Emitted when new pool ceiling (i.e. max amount of collateral) is set
    event PoolCeilingSet(uint256 collateralIndex, uint256 newCeiling);
    /// @notice Emitted when mint and redeem price thresholds are updated (1_000_000 = $1.00)
    event PriceThresholdsSet(
        uint256 newMintPriceThreshold,
        uint256 newRedeemPriceThreshold
    );
    /// @notice Emitted when a new redemption delay in blocks is set
    event RedemptionDelaySet(uint256 redemptionDelay);

    //=====================
    // Modifiers
    //=====================

    /**
     * @notice Checks whether collateral token is enabled (i.e. mintable and redeemable)
     * @param collateralIndex Collateral token index
     */
    modifier collateralEnabled(uint256 collateralIndex) {
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();
        require(
            poolStorage.enabledCollaterals[
                poolStorage.collateralAddresses[collateralIndex]
            ],
            "Collateral disabled"
        );
        _;
    }

    /**
     * @notice Checks whether a caller is the AMO minter address
     */
    modifier onlyAmoMinters() {
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();
        require(
            poolStorage.amoMinterAddresses[msg.sender],
            "Not an AMO Minter"
        );
        _;
    }

    //=====================
    // Views
    //=====================

    /**
     * @notice Returns all collateral addresses
     * @return All collateral addresses
     */
    function allCollaterals() internal view returns (address[] memory) {
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();
        return poolStorage.collateralAddresses;
    }

    /**
     * @notice Returns collateral information
     * @param collateralAddress Address of the collateral token
     * @return returnData Collateral info
     */
    function collateralInformation(
        address collateralAddress
    ) internal view returns (CollateralInformation memory returnData) {
        // load the storage
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();

        // validation
        require(
            poolStorage.enabledCollaterals[collateralAddress],
            "Invalid collateral"
        );

        // get the index
        uint256 index = poolStorage.collateralAddressToIndex[collateralAddress];

        returnData = CollateralInformation(
            index,
            poolStorage.collateralSymbols[index],
            collateralAddress,
            poolStorage.enabledCollaterals[collateralAddress],
            poolStorage.missingDecimals[index],
            poolStorage.collateralPrices[index],
            poolStorage.poolCeilings[index],
            poolStorage.mintPaused[index],
            poolStorage.redeemPaused[index],
            poolStorage.borrowingPaused[index],
            poolStorage.mintingFee[index],
            poolStorage.redemptionFee[index]
        );
    }

    /**
     * @notice Returns USD value of all collateral tokens held in the pool, in E18
     * @return balanceTally USD value of all collateral tokens
     */
    function collateralUsdBalance()
        internal
        view
        returns (uint256 balanceTally)
    {
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();
        uint256 collateralTokensCount = poolStorage.collateralAddresses.length;
        balanceTally = 0;
        for (uint256 i = 0; i < collateralTokensCount; i++) {
            balanceTally += freeCollateralBalance(i)
                .mul(10 ** poolStorage.missingDecimals[i])
                .mul(poolStorage.collateralPrices[i])
                .div(UBIQUITY_POOL_PRICE_PRECISION);
        }
    }

    /**
     * @notice Returns free collateral balance (i.e. that can be borrowed by AMO minters)
     * @param collateralIndex collateral token index
     * @return Amount of free collateral
     */
    function freeCollateralBalance(
        uint256 collateralIndex
    ) internal view returns (uint256) {
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();
        return
            IERC20(poolStorage.collateralAddresses[collateralIndex])
                .balanceOf(address(this))
                .sub(poolStorage.unclaimedPoolCollateral[collateralIndex]);
    }

    /**
     * @notice Returns Dollar value in collateral tokens
     * @param collateralIndex collateral token index
     * @param dollarAmount Amount of Dollars
     * @return Value in collateral tokens
     */
    function getDollarInCollateral(
        uint256 collateralIndex,
        uint256 dollarAmount
    ) internal view returns (uint256) {
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();
        return
            dollarAmount
                .mul(UBIQUITY_POOL_PRICE_PRECISION)
                .div(10 ** poolStorage.missingDecimals[collateralIndex])
                .div(poolStorage.collateralPrices[collateralIndex]);
    }

    /**
     * @notice Returns Ubiquity Dollar token USD price (1e6 precision) from Curve Metapool (Ubiquity Dollar, Curve Tri-Pool LP)
     * @return dollarPriceUsd USD price of Ubiquity Dollar
     */
    function getDollarPriceUsd()
        internal
        view
        returns (uint256 dollarPriceUsd)
    {
        // get Dollar price from Curve Metapool (18 decimals)
        uint256 dollarPriceUsdD18 = LibTWAPOracle.getTwapPrice();
        // convert to 6 decimals
        dollarPriceUsd = dollarPriceUsdD18
            .mul(UBIQUITY_POOL_PRICE_PRECISION)
            .div(1e18);
    }

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
    )
        internal
        collateralEnabled(collateralIndex)
        returns (uint256 totalDollarMint, uint256 collateralNeeded)
    {
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();

        require(
            poolStorage.mintPaused[collateralIndex] == false,
            "Minting is paused"
        );

        // prevent unnecessary mints
        require(
            getDollarPriceUsd() >= poolStorage.mintPriceThreshold,
            "Dollar price too low"
        );

        // get amount of collateral for incoming Dollars
        collateralNeeded = getDollarInCollateral(collateralIndex, dollarAmount);

        // subtract the minting fee
        totalDollarMint = dollarAmount
            .mul(
                UBIQUITY_POOL_PRICE_PRECISION.sub(
                    poolStorage.mintingFee[collateralIndex]
                )
            )
            .div(UBIQUITY_POOL_PRICE_PRECISION);

        // check slippages
        require((totalDollarMint >= dollarOutMin), "Dollar slippage");
        require((collateralNeeded <= maxCollateralIn), "Collateral slippage");

        // check the pool ceiling
        require(
            freeCollateralBalance(collateralIndex).add(collateralNeeded) <=
                poolStorage.poolCeilings[collateralIndex],
            "Pool ceiling"
        );

        // take collateral first
        IERC20(poolStorage.collateralAddresses[collateralIndex])
            .safeTransferFrom(msg.sender, address(this), collateralNeeded);

        // mint Dollars
        IERC20Ubiquity ubiquityDollarToken = IERC20Ubiquity(
            LibAppStorage.appStorage().dollarTokenAddress
        );
        ubiquityDollarToken.mint(msg.sender, totalDollarMint);
    }

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
    )
        internal
        collateralEnabled(collateralIndex)
        returns (uint256 collateralOut)
    {
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();

        require(
            poolStorage.redeemPaused[collateralIndex] == false,
            "Redeeming is paused"
        );

        // prevent unnecessary redemptions that could adversely affect the Dollar price
        require(
            getDollarPriceUsd() <= poolStorage.redeemPriceThreshold,
            "Dollar price too high"
        );

        uint256 dollarAfterFee = dollarAmount
            .mul(
                UBIQUITY_POOL_PRICE_PRECISION.sub(
                    poolStorage.redemptionFee[collateralIndex]
                )
            )
            .div(UBIQUITY_POOL_PRICE_PRECISION);
        collateralOut = getDollarInCollateral(collateralIndex, dollarAfterFee);

        // checks
        require(
            collateralOut <=
                (IERC20(poolStorage.collateralAddresses[collateralIndex]))
                    .balanceOf(address(this))
                    .sub(poolStorage.unclaimedPoolCollateral[collateralIndex]),
            "Insufficient pool collateral"
        );
        require(collateralOut >= collateralOutMin, "Collateral slippage");

        // account for the redeem delay
        poolStorage.redeemCollateralBalances[msg.sender][
            collateralIndex
        ] = poolStorage
        .redeemCollateralBalances[msg.sender][collateralIndex].add(
                collateralOut
            );
        poolStorage.unclaimedPoolCollateral[collateralIndex] = poolStorage
            .unclaimedPoolCollateral[collateralIndex]
            .add(collateralOut);

        poolStorage.lastRedeemed[msg.sender] = block.number;

        // burn Dollars
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
     * @param collateralIndex Collateral token index being collected
     * @return collateralAmount Amount of collateral tokens redeemed
     */
    function collectRedemption(
        uint256 collateralIndex
    ) internal returns (uint256 collateralAmount) {
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();

        require(
            poolStorage.redeemPaused[collateralIndex] == false,
            "Redeeming is paused"
        );
        require(
            (
                poolStorage.lastRedeemed[msg.sender].add(
                    poolStorage.redemptionDelay
                )
            ) <= block.number,
            "Too soon to collect redemption"
        );

        bool sendCollateral = false;

        if (
            poolStorage.redeemCollateralBalances[msg.sender][collateralIndex] >
            0
        ) {
            collateralAmount = poolStorage.redeemCollateralBalances[msg.sender][
                collateralIndex
            ];
            poolStorage.redeemCollateralBalances[msg.sender][
                collateralIndex
            ] = 0;
            poolStorage.unclaimedPoolCollateral[collateralIndex] = poolStorage
                .unclaimedPoolCollateral[collateralIndex]
                .sub(collateralAmount);
            sendCollateral = true;
        }

        // send out the tokens
        if (sendCollateral) {
            IERC20(poolStorage.collateralAddresses[collateralIndex])
                .safeTransfer(msg.sender, collateralAmount);
        }
    }

    //=========================
    // AMO minters functions
    //=========================

    /**
     * @notice Allows AMO minters to borrow collateral to make yield in external
     * protocols like Compound, Curve, erc...
     * @dev Bypasses the gassy mint->redeem cycle for AMOs to borrow collateral
     * @param collateralAmount Amount of collateral to borrow
     */
    function amoMinterBorrow(uint256 collateralAmount) internal onlyAmoMinters {
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();

        // checks the collateral index of the minter as an additional safety check
        uint256 minterCollateralIndex = IDollarAmoMinter(msg.sender)
            .collateralIndex();

        // checks to see if borrowing is paused
        require(
            poolStorage.borrowingPaused[minterCollateralIndex] == false,
            "Borrowing is paused"
        );

        // ensure collateral is enabled
        require(
            poolStorage.enabledCollaterals[
                poolStorage.collateralAddresses[minterCollateralIndex]
            ],
            "Collateral disabled"
        );

        // transfer
        IERC20(poolStorage.collateralAddresses[minterCollateralIndex])
            .safeTransfer(msg.sender, collateralAmount);
    }

    //========================
    // Restricted functions
    //========================

    /**
     * @notice Adds a new AMO minter
     * @param amoMinterAddress AMO minter address
     */
    function addAmoMinter(address amoMinterAddress) internal {
        require(amoMinterAddress != address(0), "Zero address detected");

        // make sure the AMO Minter has collateralDollarBalance()
        uint256 collatValE18 = IDollarAmoMinter(amoMinterAddress)
            .collateralDollarBalance();
        require(collatValE18 >= 0, "Invalid AMO");

        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();

        poolStorage.amoMinterAddresses[amoMinterAddress] = true;

        emit AmoMinterAdded(amoMinterAddress);
    }

    /**
     * @notice Adds a new collateral token
     * @param collateralAddress Collateral token address
     * @param poolCeiling Max amount of available tokens for collateral
     */
    function addCollateralToken(
        address collateralAddress,
        uint256 poolCeiling
    ) internal {
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();

        uint256 collateralIndex = poolStorage.collateralAddresses.length;

        // add collateral address to all collaterals
        poolStorage.collateralAddresses.push(collateralAddress);

        // for fast collateral address -> collateral idx lookups later
        poolStorage.collateralAddressToIndex[
            collateralAddress
        ] = collateralIndex;

        // set collateral initially to disabled
        poolStorage.enabledCollaterals[collateralAddress] = false;

        // add in the missing decimals
        poolStorage.missingDecimals.push(
            uint256(18).sub(ERC20(collateralAddress).decimals())
        );

        // add in the collateral symbols
        poolStorage.collateralSymbols.push(ERC20(collateralAddress).symbol());

        // initialize unclaimed pool collateral
        poolStorage.unclaimedPoolCollateral.push(0);

        // initialize paused prices to $1 as a backup
        poolStorage.collateralPrices.push(UBIQUITY_POOL_PRICE_PRECISION);

        // set fees to 0 by default
        poolStorage.mintingFee.push(0);
        poolStorage.redemptionFee.push(0);

        // handle the pauses
        poolStorage.mintPaused.push(false);
        poolStorage.redeemPaused.push(false);
        poolStorage.borrowingPaused.push(false);

        // pool ceiling
        poolStorage.poolCeilings.push(poolCeiling);
    }

    /**
     * @notice Removes AMO minter
     * @param amoMinterAddress AMO minter address to remove
     */
    function removeAmoMinter(address amoMinterAddress) internal {
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();

        poolStorage.amoMinterAddresses[amoMinterAddress] = false;

        emit AmoMinterRemoved(amoMinterAddress);
    }

    /**
     * @notice Sets collateral token price in USD
     * @param collateralIndex Collateral token index
     * @param newPrice New USD price (precision 1e6)
     */
    function setCollateralPrice(
        uint256 collateralIndex,
        uint256 newPrice
    ) internal {
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();

        // Notice from Frax: CONSIDER ORACLES EVENTUALLY!!!
        poolStorage.collateralPrices[collateralIndex] = newPrice;

        emit CollateralPriceSet(collateralIndex, newPrice);
    }

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
    ) internal {
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();

        poolStorage.mintingFee[collateralIndex] = newMintFee;
        poolStorage.redemptionFee[collateralIndex] = newRedeemFee;

        emit FeesSet(collateralIndex, newMintFee, newRedeemFee);
    }

    /**
     * @notice Sets max amount of collateral for a particular collateral token
     * @param collateralIndex Collateral token index
     * @param newCeiling Max amount of collateral
     */
    function setPoolCeiling(
        uint256 collateralIndex,
        uint256 newCeiling
    ) internal {
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();

        poolStorage.poolCeilings[collateralIndex] = newCeiling;

        emit PoolCeilingSet(collateralIndex, newCeiling);
    }

    /**
     * @notice Sets mint and redeem price thresholds, 1_000_000 = $1.00
     * @param newMintPriceThreshold New mint price threshold
     * @param newRedeemPriceThreshold New redeem price threshold
     */
    function setPriceThresholds(
        uint256 newMintPriceThreshold,
        uint256 newRedeemPriceThreshold
    ) internal {
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();

        poolStorage.mintPriceThreshold = newMintPriceThreshold;
        poolStorage.redeemPriceThreshold = newRedeemPriceThreshold;

        emit PriceThresholdsSet(newMintPriceThreshold, newRedeemPriceThreshold);
    }

    /**
     * @notice Sets a redemption delay in blocks
     * @dev Redeeming is split in 2 actions:
     * @dev 1. `redeemDollar()`
     * @dev 2. `collectRedemption()`
     * @dev `newRedemptionDelay` sets number of blocks that should be mined after which user can call `collectRedemption()`
     * @param newRedemptionDelay Redemption delay in blocks
     */
    function setRedemptionDelay(uint256 newRedemptionDelay) internal {
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();

        poolStorage.redemptionDelay = newRedemptionDelay;

        emit RedemptionDelaySet(newRedemptionDelay);
    }

    /**
     * @notice Toggles (i.e. enables/disables) a particular collateral token
     * @param collateralIndex Collateral token index
     */
    function toggleCollateral(uint256 collateralIndex) internal {
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();

        address collateralAddress = poolStorage.collateralAddresses[
            collateralIndex
        ];
        poolStorage.enabledCollaterals[collateralAddress] = !poolStorage
            .enabledCollaterals[collateralAddress];

        emit CollateralToggled(
            collateralIndex,
            poolStorage.enabledCollaterals[collateralAddress]
        );
    }

    /**
     * @notice Toggles pause for mint/redeem/borrow methods
     * @param collateralIndex Collateral token index
     * @param toggleIndex Method index. 0 - toggle mint pause, 1 - toggle redeem pause, 2 - toggle borrow by AMO pause
     */
    function toggleMRB(uint256 collateralIndex, uint8 toggleIndex) internal {
        UbiquityPoolStorage storage poolStorage = ubiquityPoolStorage();

        if (toggleIndex == 0)
            poolStorage.mintPaused[collateralIndex] = !poolStorage.mintPaused[
                collateralIndex
            ];
        else if (toggleIndex == 1)
            poolStorage.redeemPaused[collateralIndex] = !poolStorage
                .redeemPaused[collateralIndex];
        else if (toggleIndex == 2)
            poolStorage.borrowingPaused[collateralIndex] = !poolStorage
                .borrowingPaused[collateralIndex];

        emit MRBToggled(collateralIndex, toggleIndex);
    }
}
