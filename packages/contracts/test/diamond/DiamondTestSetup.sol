// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IDiamondCut} from "../../src/dollar/interfaces/IDiamondCut.sol";
import {DiamondCutFacet} from "../../src/dollar/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../../src/dollar/facets/DiamondLoupeFacet.sol";
import {IERC173} from "../../src/dollar/interfaces/IERC173.sol";
import {IDiamondLoupe} from "../../src/dollar/interfaces/IDiamondLoupe.sol";
import {OwnershipFacet} from "../../src/dollar/facets/OwnershipFacet.sol";
import {ManagerFacet} from "../../src/dollar/facets/ManagerFacet.sol";
import {AccessControlFacet} from "../../src/dollar/facets/AccessControlFacet.sol";
import {UbiquityPoolFacet} from "../../src/dollar/facets/UbiquityPoolFacet.sol";
import {TWAPOracleDollar3poolFacet} from "../../src/dollar/facets/TWAPOracleDollar3poolFacet.sol";
import {CollectableDustFacet} from "../../src/dollar/facets/CollectableDustFacet.sol";
import {ChefFacet} from "../../src/dollar/facets/ChefFacet.sol";
import {StakingFacet} from "../../src/dollar/facets/StakingFacet.sol";
import {CurveDollarIncentiveFacet} from "../../src/dollar/facets/CurveDollarIncentiveFacet.sol";
import {StakingFormulasFacet} from "../../src/dollar/facets/StakingFormulasFacet.sol";
import {CreditNftManagerFacet} from "../../src/dollar/facets/CreditNftManagerFacet.sol";
import {CreditNftRedemptionCalculatorFacet} from "../../src/dollar/facets/CreditNftRedemptionCalculatorFacet.sol";
import {CreditRedemptionCalculatorFacet} from "../../src/dollar/facets/CreditRedemptionCalculatorFacet.sol";
import {DollarMintCalculatorFacet} from "../../src/dollar/facets/DollarMintCalculatorFacet.sol";
import {DollarMintExcessFacet} from "../../src/dollar/facets/DollarMintExcessFacet.sol";
import {Diamond, DiamondArgs} from "../../src/dollar/Diamond.sol";
import {DiamondInit} from "../../src/dollar/upgradeInitializers/DiamondInit.sol";
import {DiamondTestHelper} from "../helpers/DiamondTestHelper.sol";
import {ERC1155Ubiquity} from "../../src/dollar/core/ERC1155Ubiquity.sol";
import {BondingCurveFacet} from "../../src/dollar/facets/BondingCurveFacet.sol";
import "../../src/dollar/libraries/Constants.sol";

abstract contract DiamondSetup is DiamondTestHelper {
    // contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupeFacet;
    OwnershipFacet ownerFacet;
    ManagerFacet managerFacet;
    DiamondInit dInit;
    // actual implementation of facets
    AccessControlFacet accessControlFacet;
    TWAPOracleDollar3poolFacet twapOracleDollar3PoolFacet;
    CollectableDustFacet collectableDustFacet;
    ChefFacet chefFacet;
    StakingFacet stakingFacet;
    UbiquityPoolFacet ubiquityPoolFacet;
    StakingFormulasFacet stakingFormulasFacet;
    BondingCurveFacet bondingCurveFacet;
    CurveDollarIncentiveFacet curveDollarIncentiveFacet;

    CreditNftManagerFacet creditNftManagerFacet;
    CreditNftRedemptionCalculatorFacet creditNftRedemptionCalculatorFacet;
    CreditRedemptionCalculatorFacet creditRedemptionCalculatorFacet;

    DollarMintCalculatorFacet dollarMintCalculatorFacet;
    DollarMintExcessFacet dollarMintExcessFacet;

    // interfaces with Facet ABI connected to diamond address
    IDiamondLoupe ILoupe;
    IDiamondCut ICut;
    ManagerFacet IManager;
    TWAPOracleDollar3poolFacet ITWAPOracleDollar3pool;

    CollectableDustFacet ICollectableDustFacet;
    ChefFacet IChefFacet;
    StakingFacet IStakingFacet;
    UbiquityPoolFacet IUbiquityPoolFacet;
    StakingFormulasFacet IStakingFormulasFacet;
    CurveDollarIncentiveFacet ICurveDollarIncentiveFacet;
    OwnershipFacet IOwnershipFacet;

    AccessControlFacet IAccessControl;
    BondingCurveFacet IBondingCurveFacet;

    CreditNftManagerFacet ICreditNftManagerFacet;
    CreditNftRedemptionCalculatorFacet ICreditNftRedemptionCalculationFacet;
    CreditRedemptionCalculatorFacet ICreditRedemptionCalculationFacet;

    DollarMintCalculatorFacet IDollarMintCalcFacet;
    DollarMintExcessFacet IDollarMintExcessFacet;

    string[] facetNames;
    address[] facetAddressList;

    address owner;
    address admin;
    address tokenManager;
    address user1;
    address contract1;
    address contract2;

    bytes4[] selectorsOfAccessControlFacet;
    bytes4[] selectorsOfBondingCurveFacet;
    bytes4[] selectorsOfChefFacet;
    bytes4[] selectorsOfCollectableDustFacet;
    bytes4[] selectorsOfCreditNftManagerFacet;
    bytes4[] selectorsOfCreditNftRedemptionCalculatorFacet;
    bytes4[] selectorsOfCreditRedemptionCalculatorFacet;
    bytes4[] selectorsOfCurveDollarIncentiveFacet;
    bytes4[] selectorsOfDiamondCutFacet;
    bytes4[] selectorsOfDiamondLoupeFacet;
    bytes4[] selectorsOfDollarMintCalculatorFacet;
    bytes4[] selectorsOfDollarMintExcessFacet;
    bytes4[] selectorsOfManagerFacet;
    bytes4[] selectorsOfOwnershipFacet;
    bytes4[] selectorsOfStakingFacet;
    bytes4[] selectorsOfStakingFormulasFacet;
    bytes4[] selectorsOfTWAPOracleDollar3poolFacet;
    bytes4[] selectorsOfUbiquityPoolFacet;

    // deploys diamond and connects facets
    function setUp() public virtual {
        owner = generateAddress("Owner", false, 10 ether);
        admin = generateAddress("Admin", false, 10 ether);
        tokenManager = generateAddress("TokenManager", false, 10 ether);

        user1 = generateAddress("User1", false, 10 ether);
        contract1 = generateAddress("Contract1", true, 10 ether);
        contract2 = generateAddress("Contract2", true, 10 ether);

        // set all function selectors
        selectorsOfAccessControlFacet = getSelectorsFromAbi(
            "/out/AccessControlFacet.sol/AccessControlFacet.json"
        );
        selectorsOfBondingCurveFacet = getSelectorsFromAbi(
            "/out/BondingCurveFacet.sol/BondingCurveFacet.json"
        );
        selectorsOfChefFacet = getSelectorsFromAbi(
            "/out/ChefFacet.sol/ChefFacet.json"
        );
        selectorsOfCollectableDustFacet = getSelectorsFromAbi(
            "/out/CollectableDustFacet.sol/CollectableDustFacet.json"
        );
        selectorsOfCreditNftManagerFacet = getSelectorsFromAbi(
            "/out/CreditNftManagerFacet.sol/CreditNftManagerFacet.json"
        );
        selectorsOfCreditNftRedemptionCalculatorFacet = getSelectorsFromAbi(
            "/out/CreditNftRedemptionCalculatorFacet.sol/CreditNftRedemptionCalculatorFacet.json"
        );
        selectorsOfCreditRedemptionCalculatorFacet = getSelectorsFromAbi(
            "/out/CreditRedemptionCalculatorFacet.sol/CreditRedemptionCalculatorFacet.json"
        );
        selectorsOfCurveDollarIncentiveFacet = getSelectorsFromAbi(
            "/out/CurveDollarIncentiveFacet.sol/CurveDollarIncentiveFacet.json"
        );
        selectorsOfDiamondCutFacet = getSelectorsFromAbi(
            "/out/DiamondCutFacet.sol/DiamondCutFacet.json"
        );
        selectorsOfDiamondLoupeFacet = getSelectorsFromAbi(
            "/out/DiamondLoupeFacet.sol/DiamondLoupeFacet.json"
        );
        selectorsOfDollarMintCalculatorFacet = getSelectorsFromAbi(
            "/out/DollarMintCalculatorFacet.sol/DollarMintCalculatorFacet.json"
        );
        selectorsOfDollarMintExcessFacet = getSelectorsFromAbi(
            "/out/DollarMintExcessFacet.sol/DollarMintExcessFacet.json"
        );
        selectorsOfManagerFacet = getSelectorsFromAbi(
            "/out/ManagerFacet.sol/ManagerFacet.json"
        );
        selectorsOfOwnershipFacet = getSelectorsFromAbi(
            "/out/OwnershipFacet.sol/OwnershipFacet.json"
        );
        selectorsOfStakingFacet = getSelectorsFromAbi(
            "/out/StakingFacet.sol/StakingFacet.json"
        );
        selectorsOfStakingFormulasFacet = getSelectorsFromAbi(
            "/out/StakingFormulasFacet.sol/StakingFormulasFacet.json"
        );
        selectorsOfTWAPOracleDollar3poolFacet = getSelectorsFromAbi(
            "/out/TWAPOracleDollar3poolFacet.sol/TWAPOracleDollar3poolFacet.json"
        );
        selectorsOfUbiquityPoolFacet = getSelectorsFromAbi(
            "/out/UbiquityPoolFacet.sol/UbiquityPoolFacet.json"
        );

        //deploy facets
        dCutFacet = new DiamondCutFacet();
        dLoupeFacet = new DiamondLoupeFacet();
        ownerFacet = new OwnershipFacet();
        managerFacet = new ManagerFacet();
        accessControlFacet = new AccessControlFacet();
        twapOracleDollar3PoolFacet = new TWAPOracleDollar3poolFacet();
        collectableDustFacet = new CollectableDustFacet();
        chefFacet = new ChefFacet();
        stakingFacet = new StakingFacet();
        ubiquityPoolFacet = new UbiquityPoolFacet();
        stakingFormulasFacet = new StakingFormulasFacet();
        bondingCurveFacet = new BondingCurveFacet();
        curveDollarIncentiveFacet = new CurveDollarIncentiveFacet();

        creditNftManagerFacet = new CreditNftManagerFacet();
        creditNftRedemptionCalculatorFacet = new CreditNftRedemptionCalculatorFacet();
        creditRedemptionCalculatorFacet = new CreditRedemptionCalculatorFacet();

        dollarMintCalculatorFacet = new DollarMintCalculatorFacet();
        dollarMintExcessFacet = new DollarMintExcessFacet();

        dInit = new DiamondInit();
        facetNames = [
            "DiamondCutFacet",
            "DiamondLoupeFacet",
            "OwnershipFacet",
            "ManagerFacet",
            "AccessControlFacet",
            "TWAPOracleDollar3poolFacet",
            "CollectableDustFacet",
            "ChefFacet",
            "StakingFacet",
            "UbiquityPoolFacet",
            "StakingFormulasFacet",
            "CurveDollarIncentiveFacet",
            "CreditNftManagerFacet",
            "CreditNftRedemptionCalculatorFacet",
            "CreditRedemptionCalculatorFacet",
            "DollarMintCalculatorFacet",
            "DollarMintExcessFacet",
            "BondingCurveFacet"
        ];

        DiamondInit.Args memory initArgs = DiamondInit.Args({
            admin: admin,
            tos: new address[](0),
            amounts: new uint256[](0),
            stakingShareIDs: new uint256[](0),
            governancePerBlock: 10e18,
            creditNftLengthBlocks: 100
        });
        // diamond arguments
        DiamondArgs memory _args = DiamondArgs({
            owner: owner,
            init: address(dInit),
            initCalldata: abi.encodeWithSelector(
                DiamondInit.init.selector,
                initArgs
            )
        });

        FacetCut[] memory cuts = new FacetCut[](18);

        cuts[0] = (
            FacetCut({
                facetAddress: address(dCutFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfDiamondCutFacet
            })
        );

        cuts[1] = (
            FacetCut({
                facetAddress: address(dLoupeFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfDiamondLoupeFacet
            })
        );

        cuts[2] = (
            FacetCut({
                facetAddress: address(ownerFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfOwnershipFacet
            })
        );

        cuts[3] = (
            FacetCut({
                facetAddress: address(managerFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfManagerFacet
            })
        );

        cuts[4] = (
            FacetCut({
                facetAddress: address(accessControlFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfAccessControlFacet
            })
        );
        cuts[5] = (
            FacetCut({
                facetAddress: address(twapOracleDollar3PoolFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfTWAPOracleDollar3poolFacet
            })
        );

        cuts[6] = (
            FacetCut({
                facetAddress: address(collectableDustFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfCollectableDustFacet
            })
        );
        cuts[7] = (
            FacetCut({
                facetAddress: address(chefFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfChefFacet
            })
        );
        cuts[8] = (
            FacetCut({
                facetAddress: address(stakingFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfStakingFacet
            })
        );
        cuts[9] = (
            FacetCut({
                facetAddress: address(stakingFormulasFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfStakingFormulasFacet
            })
        );
        cuts[10] = (
            FacetCut({
                facetAddress: address(creditNftManagerFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfCreditNftManagerFacet
            })
        );
        cuts[11] = (
            FacetCut({
                facetAddress: address(creditNftRedemptionCalculatorFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfCreditNftRedemptionCalculatorFacet
            })
        );
        cuts[12] = (
            FacetCut({
                facetAddress: address(creditRedemptionCalculatorFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfCreditRedemptionCalculatorFacet
            })
        );
        cuts[13] = (
            FacetCut({
                facetAddress: address(dollarMintCalculatorFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfDollarMintCalculatorFacet
            })
        );
        cuts[14] = (
            FacetCut({
                facetAddress: address(dollarMintExcessFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfDollarMintExcessFacet
            })
        );
        cuts[15] = (
            FacetCut({
                facetAddress: address(bondingCurveFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfBondingCurveFacet
            })
        );
        cuts[16] = (
            FacetCut({
                facetAddress: address(curveDollarIncentiveFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfCurveDollarIncentiveFacet
            })
        );
        cuts[17] = (
            FacetCut({
                facetAddress: address(ubiquityPoolFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfUbiquityPoolFacet
            })
        );
        // deploy diamond
        vm.prank(owner);
        diamond = new Diamond(_args, cuts);
        // initialize interfaces
        ILoupe = IDiamondLoupe(address(diamond));
        ICut = IDiamondCut(address(diamond));
        IManager = ManagerFacet(address(diamond));
        IAccessControl = AccessControlFacet(address(diamond));
        ITWAPOracleDollar3pool = TWAPOracleDollar3poolFacet(address(diamond));

        ICollectableDustFacet = CollectableDustFacet(address(diamond));
        IChefFacet = ChefFacet(address(diamond));
        IStakingFacet = StakingFacet(address(diamond));
        IUbiquityPoolFacet = UbiquityPoolFacet(address(diamond));
        IStakingFormulasFacet = StakingFormulasFacet(address(diamond));
        IBondingCurveFacet = BondingCurveFacet(address(diamond));
        ICurveDollarIncentiveFacet = CurveDollarIncentiveFacet(
            address(diamond)
        );
        IOwnershipFacet = OwnershipFacet(address(diamond));

        ICreditNftManagerFacet = CreditNftManagerFacet(address(diamond));
        ICreditNftRedemptionCalculationFacet = CreditNftRedemptionCalculatorFacet(
            address(diamond)
        );
        ICreditRedemptionCalculationFacet = CreditRedemptionCalculatorFacet(
            address(diamond)
        );

        IDollarMintCalcFacet = DollarMintCalculatorFacet(address(diamond));
        IDollarMintExcessFacet = DollarMintExcessFacet(address(diamond));

        // get all addresses
        facetAddressList = ILoupe.facetAddresses();
        vm.startPrank(admin);
        // grant diamond dollar minting and burning rights
        IAccessControl.grantRole(CURVE_DOLLAR_MANAGER_ROLE, address(diamond));
        // grant diamond dollar minting and burning rights
        IAccessControl.grantRole(DOLLAR_TOKEN_MINTER_ROLE, address(diamond));
        IAccessControl.grantRole(DOLLAR_TOKEN_BURNER_ROLE, address(diamond));
        // grand diamond Credit token minting and burning rights
        IAccessControl.grantRole(CREDIT_TOKEN_MINTER_ROLE, address(diamond));
        IAccessControl.grantRole(CREDIT_TOKEN_BURNER_ROLE, address(diamond));
        // grant diamond token admin rights
        IAccessControl.grantRole(
            GOVERNANCE_TOKEN_MANAGER_ROLE,
            address(diamond)
        );
        // grant diamond token minter rights
        IAccessControl.grantRole(STAKING_SHARE_MINTER_ROLE, address(diamond));
        // init UUPS core contracts
        __setupUUPS(address(diamond));
        vm.stopPrank();
    }
}
