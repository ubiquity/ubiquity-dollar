// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AggregatorV3Interface} from "@chainlink/interfaces/AggregatorV3Interface.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Script} from "forge-std/Script.sol";
import {Diamond, DiamondArgs} from "../../src/dollar/Diamond.sol";
import {UbiquityDollarToken} from "../../src/dollar/core/UbiquityDollarToken.sol";
import {AccessControlFacet} from "../../src/dollar/facets/AccessControlFacet.sol";
import {DiamondCutFacet} from "../../src/dollar/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../../src/dollar/facets/DiamondLoupeFacet.sol";
import {ManagerFacet} from "../../src/dollar/facets/ManagerFacet.sol";
import {OwnershipFacet} from "../../src/dollar/facets/OwnershipFacet.sol";
import {TWAPOracleDollar3poolFacet} from "../../src/dollar/facets/TWAPOracleDollar3poolFacet.sol";
import {UbiquityPoolFacet} from "../../src/dollar/facets/UbiquityPoolFacet.sol";
import {IDiamondCut} from "../../src/dollar/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../../src/dollar/interfaces/IDiamondLoupe.sol";
import {IERC173} from "../../src/dollar/interfaces/IERC173.sol";
import {IMetaPool} from "../../src/dollar/interfaces/IMetaPool.sol";
import {DEFAULT_ADMIN_ROLE, DOLLAR_TOKEN_MINTER_ROLE, DOLLAR_TOKEN_BURNER_ROLE, PAUSER_ROLE} from "../../src/dollar/libraries/Constants.sol";
import {LibAccessControl} from "../../src/dollar/libraries/LibAccessControl.sol";
import {AppStorage, LibAppStorage, Modifiers} from "../../src/dollar/libraries/LibAppStorage.sol";
import {LibDiamond} from "../../src/dollar/libraries/LibDiamond.sol";
import {MockChainLinkFeed} from "../../src/dollar/mocks/MockChainLinkFeed.sol";
import {MockERC20} from "../../src/dollar/mocks/MockERC20.sol";
import {MockMetaPool} from "../../src/dollar/mocks/MockMetaPool.sol";
import {DiamondTestHelper} from "../../test/helpers/DiamondTestHelper.sol";

/**
 * @notice It is expected that this contract is customized if you want to deploy your diamond
 * with data from a deployment script. Use the init function to initialize state variables
 * of your diamond. Add parameters to the init function if you need to.
 *
 * @notice How it works:
 * 1. New `Diamond` contract is created
 * 2. Inside the diamond's constructor there is a `delegatecall()` to `DiamondInit` with the provided args
 * 3. `DiamondInit` updates diamond storage
 */
contract DiamondInit is Modifiers {
    /// @notice Struct used for diamond initialization
    struct Args {
        address admin;
    }

    /**
     * @notice Initializes a diamond with state variables
     * @dev You can add parameters to this function in order to pass in data to set your own state variables
     * @param _args Init args
     */
    function init(Args memory _args) external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        LibAccessControl.grantRole(DEFAULT_ADMIN_ROLE, _args.admin);
        LibAccessControl.grantRole(DOLLAR_TOKEN_MINTER_ROLE, _args.admin);
        LibAccessControl.grantRole(DOLLAR_TOKEN_BURNER_ROLE, _args.admin);
        LibAccessControl.grantRole(PAUSER_ROLE, _args.admin);

        AppStorage storage appStore = LibAppStorage.appStorage();
        appStore.paused = false;
        appStore.treasuryAddress = _args.admin;

        // reentrancy guard
        _initReentrancyGuard();
    }
}

/**
 * @notice Migration contract
 * @dev Initial production migration includes the following contracts:
 * - Dollar token
 * - Governance token (already deployed https://etherscan.io/address/0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0)
 * - UbiquityPool (which is a facet of the Diamond contract)
 *
 * So we're deploying only contracts and facets necessary for features
 * connected with the contracts above. Hence we omit the following facets
 * from deployment:
 * - BondingCurveFacet (used for UbiquiStick NFT, "on hold" now)
 * - ChefFacet (staking is not a part of the initial deployment)
 * - CollectableDustFacet (could be useful but not a must now)
 * - CreditClockFacet (used for CreditNft which is not a part of the initial deployment)
 * - CreditNftManagerFacet (used for CreditNft which is not a part of the initial deployment)
 * - CreditNftRedemptionCalculatorFacet (used for CreditNft which is not a part of the initial deployment)
 * - CreditRedemptionCalculatorFacet (used for Credit token which is not a part of the initial deployment)
 * - CurveDollarIncentiveFacet (deprecated)
 * - DollarMintCalculatorFacet (used for Dollar/Credit mint/burn mechanism which is not a part of the initial deployment)
 * - DollarMintExcessFacet (used for Dollar/Credit mint/burn mechanism which is not a part of the initial deployment)
 * - StakingFacet (staking is not a part of the initial deployment)
 * - StakingFormulasFacet (staking is not a part of the initial deployment)
 */
contract Deploy001_Diamond_Dollar is Script, DiamondTestHelper {
    // env variables
    uint256 adminPrivateKey;
    uint256 ownerPrivateKey;
    address collateralTokenAddress;

    // threshold in seconds when price feed response should be considered stale
    uint256 CHAINLINK_PRICE_FEED_THRESHOLD;

    // Dollar related contracts
    UbiquityDollarToken public dollarToken;
    ERC1967Proxy public proxyDollarToken;

    // diamond related contracts
    Diamond diamond;
    DiamondInit diamondInit;

    // diamond facet implementation instances (should not be used directly)
    AccessControlFacet accessControlFacetImplementation;
    DiamondCutFacet diamondCutFacetImplementation;
    DiamondLoupeFacet diamondLoupeFacetImplementation;
    ManagerFacet managerFacetImplementation;
    OwnershipFacet ownershipFacetImplementation;
    TWAPOracleDollar3poolFacet twapOracleDollar3PoolFacetImplementation;
    UbiquityPoolFacet ubiquityPoolFacetImplementation;

    // oracle related contracts
    AggregatorV3Interface chainLinkPriceFeedLusd; // chainlink LUSD/USD price feed
    IERC20 curveTriPoolLpToken; // Curve's 3CRV-LP token
    IMetaPool curveDollarMetaPool; // Curve's Dollar-3CRVLP metapool

    // selectors for all of the facets
    bytes4[] selectorsOfAccessControlFacet;
    bytes4[] selectorsOfDiamondCutFacet;
    bytes4[] selectorsOfDiamondLoupeFacet;
    bytes4[] selectorsOfManagerFacet;
    bytes4[] selectorsOfOwnershipFacet;
    bytes4[] selectorsOfTWAPOracleDollar3poolFacet;
    bytes4[] selectorsOfUbiquityPoolFacet;

    function run() public virtual {
        // read env variables
        adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        ownerPrivateKey = vm.envUint("OWNER_PRIVATE_KEY");
        collateralTokenAddress = vm.envAddress("COLLATERAL_TOKEN_ADDRESS");

        address adminAddress = vm.addr(adminPrivateKey);
        address ownerAddress = vm.addr(ownerPrivateKey);

        //===================
        // Deploy Diamond
        //===================

        // start sending owner transactions
        vm.startBroadcast(ownerPrivateKey);

        // set all function selectors
        selectorsOfAccessControlFacet = getSelectorsFromAbi(
            "/out/AccessControlFacet.sol/AccessControlFacet.json"
        );
        selectorsOfDiamondCutFacet = getSelectorsFromAbi(
            "/out/DiamondCutFacet.sol/DiamondCutFacet.json"
        );
        selectorsOfDiamondLoupeFacet = getSelectorsFromAbi(
            "/out/DiamondLoupeFacet.sol/DiamondLoupeFacet.json"
        );
        selectorsOfManagerFacet = getSelectorsFromAbi(
            "/out/ManagerFacet.sol/ManagerFacet.json"
        );
        selectorsOfOwnershipFacet = getSelectorsFromAbi(
            "/out/OwnershipFacet.sol/OwnershipFacet.json"
        );
        selectorsOfTWAPOracleDollar3poolFacet = getSelectorsFromAbi(
            "/out/TWAPOracleDollar3poolFacet.sol/TWAPOracleDollar3poolFacet.json"
        );
        selectorsOfUbiquityPoolFacet = getSelectorsFromAbi(
            "/out/UbiquityPoolFacet.sol/UbiquityPoolFacet.json"
        );

        // deploy facet implementation instances
        accessControlFacetImplementation = new AccessControlFacet();
        diamondCutFacetImplementation = new DiamondCutFacet();
        diamondLoupeFacetImplementation = new DiamondLoupeFacet();
        managerFacetImplementation = new ManagerFacet();
        ownershipFacetImplementation = new OwnershipFacet();
        twapOracleDollar3PoolFacetImplementation = new TWAPOracleDollar3poolFacet();
        ubiquityPoolFacetImplementation = new UbiquityPoolFacet();

        // prepare DiamondInit args
        diamondInit = new DiamondInit();
        DiamondInit.Args memory diamondInitArgs = DiamondInit.Args({
            admin: adminAddress
        });
        // prepare Diamond arguments
        DiamondArgs memory diamondArgs = DiamondArgs({
            owner: ownerAddress,
            init: address(diamondInit),
            initCalldata: abi.encodeWithSelector(
                DiamondInit.init.selector,
                diamondInitArgs
            )
        });

        // prepare facet cuts
        FacetCut[] memory cuts = new FacetCut[](7);
        cuts[0] = (
            FacetCut({
                facetAddress: address(accessControlFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfAccessControlFacet
            })
        );
        cuts[1] = (
            FacetCut({
                facetAddress: address(diamondCutFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfDiamondCutFacet
            })
        );
        cuts[2] = (
            FacetCut({
                facetAddress: address(diamondLoupeFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfDiamondLoupeFacet
            })
        );
        cuts[3] = (
            FacetCut({
                facetAddress: address(managerFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfManagerFacet
            })
        );
        cuts[4] = (
            FacetCut({
                facetAddress: address(ownershipFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfOwnershipFacet
            })
        );
        cuts[5] = (
            FacetCut({
                facetAddress: address(twapOracleDollar3PoolFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfTWAPOracleDollar3poolFacet
            })
        );
        cuts[6] = (
            FacetCut({
                facetAddress: address(ubiquityPoolFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfUbiquityPoolFacet
            })
        );

        // deploy diamond
        diamond = new Diamond(diamondArgs, cuts);

        // stop sending owner transactions
        vm.stopBroadcast();

        //=======================
        // Diamond permissions
        //=======================

        // start sending admin transactions
        vm.startBroadcast(adminPrivateKey);

        AccessControlFacet accessControlFacet = AccessControlFacet(
            address(diamond)
        );

        // grant diamond dollar minting and burning rights
        accessControlFacet.grantRole(
            DOLLAR_TOKEN_MINTER_ROLE,
            address(diamond)
        );
        accessControlFacet.grantRole(
            DOLLAR_TOKEN_BURNER_ROLE,
            address(diamond)
        );

        // stop sending admin transactions
        vm.stopBroadcast();

        //=========================
        // UbiquiPoolFacet setup
        //=========================

        // start sending admin transactions
        vm.startBroadcast(adminPrivateKey);

        UbiquityPoolFacet ubiquityPoolFacet = UbiquityPoolFacet(
            address(diamond)
        );

        // add collateral token (users can mint/redeem Dollars in exchange for collateral)
        uint256 poolCeiling = 10_000e18; // max 10_000 of collateral tokens is allowed
        ubiquityPoolFacet.addCollateralToken(
            collateralTokenAddress, // collateral token address
            address(chainLinkPriceFeedLusd), // chainlink LUSD/USD price feed address
            poolCeiling // pool ceiling amount
        );
        // enable collateral at index 0
        ubiquityPoolFacet.toggleCollateral(0);
        // set mint and redeem fees
        ubiquityPoolFacet.setFees(
            0, // collateral index
            0, // 0% mint fee
            0 // 0% redeem fee
        );
        // set redemption delay to 2 blocks
        ubiquityPoolFacet.setRedemptionDelayBlocks(2);
        // set mint price threshold to $1.01 and redeem price to $0.99
        ubiquityPoolFacet.setPriceThresholds(1010000, 990000);

        // stop sending admin transactions
        vm.stopBroadcast();

        //================================================================================
        // Oracles (Curve Dollar-3CRVLP metapool + LUSD/USD chainlink price feed) setup
        //================================================================================

        initOracles();

        //==================
        // Dollar deploy
        //==================

        // start sending owner transactions
        vm.startBroadcast(ownerPrivateKey);

        // deploy proxy
        bytes memory initDollarPayload = abi.encodeWithSignature(
            "initialize(address)",
            address(diamond)
        );
        proxyDollarToken = new ERC1967Proxy(
            address(new UbiquityDollarToken()),
            initDollarPayload
        );

        // get Dollar contract which should be used in the frontend
        dollarToken = UbiquityDollarToken(address(proxyDollarToken));

        // stop sending owner transactions
        vm.stopBroadcast();

        //================
        // Dollar setup
        //================

        // start sending admin transactions
        vm.startBroadcast(adminPrivateKey);

        // set Dollar token address in the Diamond
        ManagerFacet managerFacet = ManagerFacet(address(diamond));
        managerFacet.setDollarTokenAddress(address(dollarToken));

        // stop sending admin transactions
        vm.stopBroadcast();
    }

    /**
     * @notice Initializes oracle related contracts
     *
     * @dev Ubiquity protocol supports 2 oracles:
     * 1. Curve's Dollar-3CRVLP metapool to fetch Dollar prices
     * 2. Chainlink's price feed (used in UbiquityPool) to fetch collateral token prices in USD
     *
     * There are 2 migrations (deployment scripts):
     * 1. Development (for usage in testnet and local anvil instance forked from mainnet)
     * 2. Mainnet (for production usage in mainnet)
     *
     * Development migration deploys (for ease of debugging) mocks of:
     * - Chainlink price feed contract
     * - 3CRVLP ERC20 token
     * - Curve's Dollar-3CRVLP metapool contract
     */
    function initOracles() public virtual {
        //========================================
        // Chainlink LUSD/USD price feed deploy
        //========================================

        // start sending owner transactions
        vm.startBroadcast(ownerPrivateKey);

        // deploy LUSD/USD chainlink mock price feed
        chainLinkPriceFeedLusd = new MockChainLinkFeed();

        // stop sending owner transactions
        vm.stopBroadcast();

        //=======================================
        // Chainlink LUSD/USD price feed setup
        //=======================================

        // start sending admin transactions
        vm.startBroadcast(adminPrivateKey);

        // set threshold to 10 years (3650 days) for ease of debugging
        CHAINLINK_PRICE_FEED_THRESHOLD = 3650 days;

        // set params for LUSD/USD chainlink price feed mock
        MockChainLinkFeed(address(chainLinkPriceFeedLusd)).updateMockParams(
            1, // round id
            100_000_000, // answer, 100_000_000 = $1.00 (chainlink 8 decimals answer is converted to 6 decimals used in UbiquityPool)
            block.timestamp, // started at
            block.timestamp, // updated at
            1 // answered in round
        );

        UbiquityPoolFacet ubiquityPoolFacet = UbiquityPoolFacet(
            address(diamond)
        );

        // set price feed address and threshold in seconds
        ubiquityPoolFacet.setCollateralChainLinkPriceFeed(
            collateralTokenAddress, // collateral token address
            address(chainLinkPriceFeedLusd), // price feed address
            CHAINLINK_PRICE_FEED_THRESHOLD // price feed staleness threshold in seconds
        );

        // fetch latest prices from chainlink for collateral with index 0
        ubiquityPoolFacet.updateChainLinkCollateralPrice(0);

        // stop sending admin transactions
        vm.stopBroadcast();

        //=========================================
        // Curve's Dollar-3CRVLP metapool deploy
        //=========================================

        // start sending owner transactions
        vm.startBroadcast(ownerPrivateKey);

        // deploy mock 3CRV-LP token
        curveTriPoolLpToken = new MockERC20(
            "Curve.fi DAI/USDC/USDT",
            "3Crv",
            18
        );

        // deploy mock Curve's Dollar-3CRVLP metapool
        curveDollarMetaPool = new MockMetaPool(
            address(dollarToken),
            address(curveTriPoolLpToken)
        );

        // stop sending owner transactions
        vm.stopBroadcast();

        //========================================
        // Curve's Dollar-3CRVLP metapool setup
        //========================================

        // start sending owner transactions
        vm.startBroadcast(ownerPrivateKey);

        TWAPOracleDollar3poolFacet twapOracleDollar3PoolFacet = TWAPOracleDollar3poolFacet(
                address(diamond)
            );

        // set Curve Dollar-3CRVLP pool in the diamond storage
        twapOracleDollar3PoolFacet.setPool(
            address(curveDollarMetaPool),
            address(curveTriPoolLpToken)
        );

        // fetch latest Dollar price from Curve's Dollar-3CRVLP metapool
        twapOracleDollar3PoolFacet.update();

        // stop sending owner transactions
        vm.stopBroadcast();
    }
}
