// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AggregatorV3Interface} from "@chainlink/interfaces/AggregatorV3Interface.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Deploy001_Diamond_Dollar as Deploy001_Diamond_Dollar_Development} from "../development/Deploy001_Diamond_Dollar.s.sol";
import {ManagerFacet} from "../../src/dollar/facets/ManagerFacet.sol";
import {UbiquityPoolFacet} from "../../src/dollar/facets/UbiquityPoolFacet.sol";
import {ICurveStableSwapMetaNG} from "../../src/dollar/interfaces/ICurveStableSwapMetaNG.sol";

/// @notice Migration contract
contract Deploy001_Diamond_Dollar is Deploy001_Diamond_Dollar_Development {
    function run() public override {
        // Run migration for testnet because "Deploy001_Diamond_Dollar" migration
        // is identical both for testnet/development and mainnet
        super.run();
    }

    /**
     * @notice Runs before the main `run()` method
     *
     * @dev Initializes collateral token
     * @dev Collateral token is different for mainnet and development:
     * - mainnet: uses LUSD address from `COLLATERAL_TOKEN_ADDRESS` env variables
     * - development: deploys mocked ERC20 token from scratch
     */
    function beforeRun() public override {
        // read env variables
        address collateralTokenAddress = vm.envAddress(
            "COLLATERAL_TOKEN_ADDRESS"
        );

        //=================================
        // Collateral ERC20 token setup
        //=================================

        // use existing LUSD contract for mainnet
        collateralToken = IERC20(collateralTokenAddress);
    }

    /**
     * @notice Runs after the main `run()` method
     *
     * @dev Initializes oracle related contracts
     *
     * @dev We override `afterRun()` from `Deploy001_Diamond_Dollar_Development` because
     * we need to use already deployed contracts while `Deploy001_Diamond_Dollar_Development`
     * deploys all oracle related contracts from scratch for ease of debugging.
     *
     * @dev Ubiquity protocol supports 2 oracles:
     * 1. Curve's Dollar-3CRVLP metapool to fetch Dollar prices
     * 2. Chainlink's price feed (used in UbiquityPool) to fetch collateral token prices in USD
     *
     * There are 2 migrations (deployment scripts):
     * 1. Development (for usage in testnet and local anvil instance forked from mainnet)
     * 2. Mainnet (for production usage in mainnet)
     *
     * Mainnet (i.e. production) migration uses already deployed contracts for:
     * - Chainlink price feed contract
     * - 3CRVLP ERC20 token
     */
    function afterRun() public override {
        // read env variables
        address chainlinkPriceFeedAddress = vm.envAddress(
            "COLLATERAL_TOKEN_CHAINLINK_PRICE_FEED_ADDRESS"
        );
        address token3CrvAddress = vm.envAddress("TOKEN_3CRV_ADDRESS");
        address curveDollarMetapoolAddress = vm.envAddress(
            "CURVE_DOLLAR_METAPOOL_ADDRESS"
        );

        //=======================================
        // Chainlink LUSD/USD price feed setup
        //=======================================

        // start sending admin transactions
        vm.startBroadcast(adminPrivateKey);

        // set threshold to 1 day
        CHAINLINK_PRICE_FEED_THRESHOLD = 1 days;

        // init LUSD/USD chainlink price feed
        chainLinkPriceFeedLusd = AggregatorV3Interface(
            chainlinkPriceFeedAddress
        );

        UbiquityPoolFacet ubiquityPoolFacet = UbiquityPoolFacet(
            address(diamond)
        );

        // set price feed
        ubiquityPoolFacet.setCollateralChainLinkPriceFeed(
            address(collateralToken), // collateral token address
            address(chainLinkPriceFeedLusd), // price feed address
            CHAINLINK_PRICE_FEED_THRESHOLD // price feed staleness threshold in seconds
        );

        // fetch latest prices from chainlink for collateral with index 0
        ubiquityPoolFacet.updateChainLinkCollateralPrice(0);

        // stop sending admin transactions
        vm.stopBroadcast();

        //========================================
        // Curve's Dollar-3CRVLP metapool setup
        //========================================

        // start sending admin transactions
        vm.startBroadcast(adminPrivateKey);

        // init 3CRV token
        curveTriPoolLpToken = IERC20(token3CrvAddress);

        // init Dollar-3CRVLP Curve metapool
        curveDollarMetaPool = ICurveStableSwapMetaNG(
            curveDollarMetapoolAddress
        );

        // set curve's metapool in manager facet
        ManagerFacet managerFacet = ManagerFacet(address(diamond));
        managerFacet.setStableSwapMetaPoolAddress(address(curveDollarMetaPool));

        // stop sending admin transactions
        vm.stopBroadcast();
    }
}
