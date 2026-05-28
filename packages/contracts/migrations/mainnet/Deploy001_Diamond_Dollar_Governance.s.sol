// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AggregatorV3Interface} from "@chainlink/interfaces/AggregatorV3Interface.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Deploy001_Diamond_Dollar_Governance as Deploy001_Diamond_Dollar_Governance_Development} from "../development/Deploy001_Diamond_Dollar_Governance.s.sol";
import {UbiquityAlgorithmicDollarManager} from "../../src/deprecated/UbiquityAlgorithmicDollarManager.sol";
import {UbiquityGovernance} from "../../src/deprecated/UbiquityGovernance.sol";
import {ManagerFacet} from "../../src/dollar/facets/ManagerFacet.sol";
import {UbiquityPoolFacet} from "../../src/dollar/facets/UbiquityPoolFacet.sol";
import {ICurveStableSwapFactoryNG} from "../../src/dollar/interfaces/ICurveStableSwapFactoryNG.sol";
import {ICurveStableSwapMetaNG} from "../../src/dollar/interfaces/ICurveStableSwapMetaNG.sol";
import {ICurveTwocryptoOptimized} from "../../src/dollar/interfaces/ICurveTwocryptoOptimized.sol";

/// @notice Migration contract
contract Deploy001_Diamond_Dollar_Governance is
    Deploy001_Diamond_Dollar_Governance_Development
{
    function run() public override {
        // Run migration for testnet because "Deploy001_Diamond_Dollar_Governance" migration
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
     * @dev Initializes:
     * - oracle related contracts
     * - Governance token related contracts
     *
     * @dev We override `afterRun()` from `Deploy001_Diamond_Dollar_Governance_Development` because
     * we need to use already deployed contracts while `Deploy001_Diamond_Dollar_Governance_Development`
     * deploys all oracle and Governance token related contracts from scratch for ease of debugging.
     *
     * @dev Ubiquity protocol supports 5 oracles:
     * 1. Curve's LUSD-Dollar plain pool to fetch Dollar prices
     * 2. Chainlink's price feed (used in UbiquityPool) to fetch LUSD/USD price (for getting Dollar price in USD)
     * 3. Chainlink's price feed (used in UbiquityPool) to fetch collateral token prices in USD (for getting collateral price in USD)
     * 4. Chainlink's price feed (used in UbiquityPool) to fetch ETH/USD price
     * 5. Curve's Governance-WETH crypto pool to fetch Governance/ETH price
     *
     * There are 2 migrations (deployment scripts):
     * 1. Development (for usage in testnet and local anvil instance)
     * 2. Mainnet (for production usage in mainnet)
     *
     * Mainnet (i.e. production) migration uses already deployed contracts for:
     * - Chainlink collateral price feed contract
     * - Chainlink Stable/USD price feed contract (here "Stable" refers to the LUSD token from Curve's LUSD-Dollar plain pool)
     * - UbiquityAlgorithmicDollarManager contract
     * - UbiquityGovernance token contract
     * - Chainlink ETH/USD price feed
     * - Curve's Governance-WETH crypto pool
     */
    function afterRun() public override {
        // read env variables
        address chainlinkPriceFeedAddressEth = vm.envAddress(
            "ETH_USD_CHAINLINK_PRICE_FEED_ADDRESS"
        );
        address chainlinkPriceFeedAddressLusd = vm.envAddress(
            "COLLATERAL_TOKEN_CHAINLINK_PRICE_FEED_ADDRESS"
        );
        address curveGovernanceEthPoolAddress = vm.envAddress(
            "CURVE_GOVERNANCE_WETH_POOL_ADDRESS"
        );

        // set threshold to 1 hour (default value for ETH/USD and LUSD/USD price feeds)
        CHAINLINK_PRICE_FEED_THRESHOLD = 1 hours;

        ManagerFacet managerFacet = ManagerFacet(address(diamond));
        UbiquityPoolFacet ubiquityPoolFacet = UbiquityPoolFacet(
            address(diamond)
        );

        //=======================================
        // Chainlink LUSD/USD price feed setup
        //=======================================

        // start sending admin transactions
        vm.startBroadcast(adminPrivateKey);

        // init LUSD/USD chainlink price feed
        chainLinkPriceFeedLusd = AggregatorV3Interface(
            chainlinkPriceFeedAddressLusd
        );

        // set collateral price feed
        ubiquityPoolFacet.setCollateralChainLinkPriceFeed(
            address(collateralToken), // collateral token address
            address(chainLinkPriceFeedLusd), // price feed address
            CHAINLINK_PRICE_FEED_THRESHOLD // price feed staleness threshold in seconds
        );

        // fetch latest prices from chainlink for collateral with index 0
        ubiquityPoolFacet.updateChainLinkCollateralPrice(0);

        // set Stable/Dollar price feed
        ubiquityPoolFacet.setStableUsdChainLinkPriceFeed(
            address(chainLinkPriceFeedLusd), // price feed address
            CHAINLINK_PRICE_FEED_THRESHOLD // price feed staleness threshold in seconds
        );

        // stop sending admin transactions
        vm.stopBroadcast();

        //=========================================
        // Curve's LUSD-Dollar plain pool deploy
        //=========================================

        // start sending owner transactions
        vm.startBroadcast(ownerPrivateKey);

        // prepare parameters
        address[] memory plainPoolCoins = new address[](2);
        plainPoolCoins[0] = address(collateralToken);
        plainPoolCoins[1] = address(dollarToken);

        uint8[] memory plainPoolAssetTypes = new uint8[](2);
        plainPoolAssetTypes[0] = 0;
        plainPoolAssetTypes[1] = 0;

        bytes4[] memory plainPoolMethodIds = new bytes4[](2);
        plainPoolMethodIds[0] = bytes4("");
        plainPoolMethodIds[1] = bytes4("");

        address[] memory plainPoolTokenOracleAddresses = new address[](2);
        plainPoolTokenOracleAddresses[0] = address(0);
        plainPoolTokenOracleAddresses[1] = address(0);

        // deploy Curve LUSD-Dollar plain pool
        address curveDollarPlainPoolAddress = ICurveStableSwapFactoryNG(
            0x6A8cbed756804B16E05E741eDaBd5cB544AE21bf
        ).deploy_plain_pool(
                "LUSD/Dollar", // pool name
                "LUSDDollar", // LP token symbol
                plainPoolCoins, // coins used in the pool
                100, // amplification coefficient
                4000000, // trade fee, 0.04%
                20000000000, // off-peg fee multiplier
                2597, // moving average time value, 2597 = 1800 seconds
                0, // plain pool implementation index
                plainPoolAssetTypes, // asset types
                plainPoolMethodIds, // method ids for oracle asset type (not applicable for Dollar)
                plainPoolTokenOracleAddresses // token oracle addresses (not applicable for Dollar)
            );

        // stop sending owner transactions
        vm.stopBroadcast();

        //========================================
        // Curve's LUSD-Dollar plain pool setup
        //========================================

        // start sending admin transactions
        vm.startBroadcast(adminPrivateKey);

        // set curve's plain pool in manager facet
        managerFacet.setStableSwapPlainPoolAddress(curveDollarPlainPoolAddress);

        // stop sending admin transactions
        vm.stopBroadcast();

        //==========================================
        // UbiquityAlgorithmicDollarManager setup
        //==========================================

        // using already deployed (on mainnet) UbiquityAlgorithmicDollarManager
        ubiquityAlgorithmicDollarManager = UbiquityAlgorithmicDollarManager(
            0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98
        );

        //============================
        // UbiquityGovernance setup
        //============================

        // NOTICE: If owner address is `ubq.eth` (i.e. ubiquity deployer) it means that we want to perform
        // a real deployment to mainnet so we start sending transactions via `startBroadcast()`. Otherwise
        // we're in the forked mainnet anvil instance and the owner is not `ubq.eth` so we can't add "UBQ_MINTER_ROLE"
        // and "UBQ_BURNER_ROLE" roles to the diamond contract (because only `ubq.eth` address has this permission).
        // Also we can't use "vm.prank()" since it doesn't update the storage but only simulates a call. That is why
        // if you're testing on an anvil instance forked from mainnet make sure to add "UBQ_MINTER_ROLE" and "UBQ_BURNER_ROLE"
        // roles to the diamond contract manually. Take this command for inspiration:
        // ```
        // DIAMOND_ADDRESS=0x9Bb65b12162a51413272d10399282E730822Df44; \
        // UBQ_ETH_ADDRESS=0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd; \
        // UBIQUITY_ALGORITHMIC_DOLLAR_MANAGER=0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98; \
        // cast rpc anvil_impersonateAccount $UBQ_ETH_ADDRESS; \
        // cast send --unlocked --from $UBQ_ETH_ADDRESS $UBIQUITY_ALGORITHMIC_DOLLAR_MANAGER "grantRole(bytes32,address)" $(cast keccak "UBQ_BURNER_ROLE") $DIAMOND_ADDRESS --rpc-url http://localhost:8545; \
        // cast send --unlocked --from $UBQ_ETH_ADDRESS $UBIQUITY_ALGORITHMIC_DOLLAR_MANAGER "grantRole(bytes32,address)" $(cast keccak "UBQ_MINTER_ROLE") $DIAMOND_ADDRESS --rpc-url http://localhost:8545; \
        // cast rpc anvil_stopImpersonatingAccount $UBQ_ETH_ADDRESS;
        // ```
        address ubiquityDeployerAddress = 0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd;

        if (ownerAddress == ubiquityDeployerAddress) {
            // Start sending owner transactions
            vm.startBroadcast(ownerPrivateKey);

            // Owner (i.e. `ubq.eth` who is admin for UbiquityAlgorithmicDollarManager) grants diamond
            // Governance token mint and burn rights
            ubiquityAlgorithmicDollarManager.grantRole(
                keccak256("UBQ_MINTER_ROLE"),
                address(diamond)
            );
            ubiquityAlgorithmicDollarManager.grantRole(
                keccak256("UBQ_BURNER_ROLE"),
                address(diamond)
            );

            // stop sending owner transactions
            vm.stopBroadcast();
        }

        // using already deployed (on mainnet) Governance token
        ubiquityGovernance = UbiquityGovernance(
            0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0
        );

        // start sending admin transactions
        vm.startBroadcast(adminPrivateKey);

        // admin sets Governance token address in manager facet
        managerFacet.setGovernanceTokenAddress(address(ubiquityGovernance));

        // stop sending admin transactions
        vm.stopBroadcast();

        //======================================
        // Chainlink ETH/USD price feed setup
        //======================================

        // start sending admin transactions
        vm.startBroadcast(adminPrivateKey);

        // init ETH/USD chainlink price feed
        chainLinkPriceFeedEth = AggregatorV3Interface(
            chainlinkPriceFeedAddressEth
        );

        // set price feed for ETH/USD pair
        ubiquityPoolFacet.setEthUsdChainLinkPriceFeed(
            address(chainLinkPriceFeedEth), // price feed address
            CHAINLINK_PRICE_FEED_THRESHOLD // price feed staleness threshold in seconds
        );

        // stop sending admin transactions
        vm.stopBroadcast();

        //=============================================
        // Curve's Governance-WETH crypto pool setup
        //=============================================

        // start sending admin transactions
        vm.startBroadcast(adminPrivateKey);

        // init Curve Governance-WETH crypto pool
        curveGovernanceEthPool = ICurveTwocryptoOptimized(
            curveGovernanceEthPoolAddress
        );

        // set Governance-ETH pool
        ubiquityPoolFacet.setGovernanceEthPoolAddress(
            address(curveGovernanceEthPool)
        );

        // stop sending admin transactions
        vm.stopBroadcast();
    }
}
