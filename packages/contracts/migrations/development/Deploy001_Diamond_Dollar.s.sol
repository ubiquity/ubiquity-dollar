// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
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
import {DEFAULT_ADMIN_ROLE, DOLLAR_TOKEN_MINTER_ROLE, DOLLAR_TOKEN_BURNER_ROLE, PAUSER_ROLE} from "../../src/dollar/libraries/Constants.sol";
import {LibAccessControl} from "../../src/dollar/libraries/LibAccessControl.sol";
import {AppStorage, LibAppStorage, Modifiers} from "../../src/dollar/libraries/LibAppStorage.sol";
import {LibDiamond} from "../../src/dollar/libraries/LibDiamond.sol";
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

/// @notice Migration contract
contract Deploy001_Diamond_Dollar is Script, DiamondTestHelper {
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
        uint256 adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        uint256 ownerPrivateKey = vm.envUint("OWNER_PRIVATE_KEY");

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

        // add collateral LUSD token
        uint256 poolCeiling = 10_000e18; // max 10_000 of collateral tokens is allowed
        address lusdAddress = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;
        ubiquityPoolFacet.addCollateralToken(lusdAddress, poolCeiling);
        // enable collateral at index 0
        ubiquityPoolFacet.toggleCollateral(0);
        // set mint and redeem fees
        ubiquityPoolFacet.setFees(
            0, // collateral index
            0, // 0% mint fee
            0 // 0% redeem fee
        );
        // set redemption delay to 2 blocks
        ubiquityPoolFacet.setRedemptionDelay(2);
        // set mint price threshold to $1.01 and redeem price to $0.99
        ubiquityPoolFacet.setPriceThresholds(1010000, 990000);

        // stop sending admin transactions
        vm.stopBroadcast();

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
}
