// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IDiamondCut} from "../../../../src/dollar/interfaces/IDiamondCut.sol";
import {DiamondCutFacet} from "../../../../src/dollar/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../../../../src/dollar/facets/DiamondLoupeFacet.sol";
import {IERC173} from "../../../../src/dollar/interfaces/IERC173.sol";
import {IDiamondLoupe} from "../../../../src/dollar/interfaces/IDiamondLoupe.sol";
import {OwnershipFacet} from "../../../../src/dollar/facets/OwnershipFacet.sol";
import {ManagerFacet} from "../../../../src/dollar/facets/ManagerFacet.sol";
import {AccessControlFacet} from "../../../../src/dollar/facets/AccessControlFacet.sol";
import {TWAPOracleDollar3poolFacet} from "../../../../src/dollar/facets/TWAPOracleDollar3poolFacet.sol";
import {CollectableDustFacet} from "../../../../src/dollar/facets/CollectableDustFacet.sol";
import {ChefFacet} from "../../../../src/dollar/facets/ChefFacet.sol";
import {StakingFacet} from "../../../../src/dollar/facets/StakingFacet.sol";
import {StakingFormulasFacet} from "../../../../src/dollar/facets/StakingFormulasFacet.sol";
import {CreditClockFacet} from "../../../../src/dollar/facets/CreditClockFacet.sol";
import {CreditNftManagerFacet} from "../../../../src/dollar/facets/CreditNftManagerFacet.sol";
import {CreditNftRedemptionCalculatorFacet} from "../../../../src/dollar/facets/CreditNftRedemptionCalculatorFacet.sol";
import {CreditRedemptionCalculatorFacet} from "../../../../src/dollar/facets/CreditRedemptionCalculatorFacet.sol";
import {DollarMintCalculatorFacet} from "../../../../src/dollar/facets/DollarMintCalculatorFacet.sol";
import {DollarMintExcessFacet} from "../../../../src/dollar/facets/DollarMintExcessFacet.sol";
import {Diamond, DiamondArgs} from "../../../../src/dollar/Diamond.sol";
import {DiamondInit} from "../../../../src/dollar/upgradeInitializers/DiamondInit.sol";
import {UbiquityDollarToken} from "../../../../src/dollar/core/UbiquityDollarToken.sol";
import {StakingShare} from "../../../../src/dollar/core/StakingShare.sol";
import {UbiquityGovernanceToken} from "../../../../src/dollar/core/UbiquityGovernanceToken.sol";
import {IDiamondCut} from "../../../../src/dollar/interfaces/IDiamondCut.sol";

import "./00_Constants.s.sol";

contract DiamondScript is Constants {
    // selectors of the facets
    bytes4[] selectorsOfAccessControlFacet;
    bytes4[] selectorsOfChefFacet;
    bytes4[] selectorsOfCollectableDustFacet;
    bytes4[] selectorsOfCreditClockFacet;
    bytes4[] selectorsOfCreditNftManagerFacet;
    bytes4[] selectorsOfCreditNftRedemptionCalculatorFacet;
    bytes4[] selectorsOfCreditRedemptionCalculatorFacet;
    bytes4[] selectorsOfDiamondCutFacet;
    bytes4[] selectorsOfDiamondLoupeFacet;
    bytes4[] selectorsOfDollarMintCalculatorFacet;
    bytes4[] selectorsOfDollarMintExcessFacet;
    bytes4[] selectorsOfManagerFacet;
    bytes4[] selectorsOfOwnershipFacet;
    bytes4[] selectorsOfStakingFacet;
    bytes4[] selectorsOfStakingFormulasFacet;
    bytes4[] selectorsOfTWAPOracleDollar3poolFacet;

    // contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupeFacet;
    OwnershipFacet ownerFacet;
    ManagerFacet managerFacet;
    // facet through diamond address
    ManagerFacet IManager;
    AccessControlFacet IAccessControl;
    DiamondInit dInit;
    // actual implementation of facets
    AccessControlFacet accessControlFacet;
    TWAPOracleDollar3poolFacet twapOracleDollar3PoolFacet;
    CollectableDustFacet collectableDustFacet;
    ChefFacet chefFacet;
    StakingFacet stakingFacet;
    StakingFormulasFacet stakingFormulasFacet;

    CreditNftManagerFacet creditNftManagerFacet;
    CreditNftRedemptionCalculatorFacet creditNftRedemptionCalculatorFacet;
    CreditRedemptionCalculatorFacet creditRedemptionCalculatorFacet;

    DollarMintCalculatorFacet dollarMintCalculatorFacet;
    DollarMintExcessFacet dollarMintExcessFacet;
    CreditClockFacet creditClockFacet;

    string[] facetNames;

    function run() public virtual {
        vm.startBroadcast(deployerPrivateKey);
        getSelectors();
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
        stakingFormulasFacet = new StakingFormulasFacet();

        creditNftManagerFacet = new CreditNftManagerFacet();
        creditNftRedemptionCalculatorFacet = new CreditNftRedemptionCalculatorFacet();
        creditRedemptionCalculatorFacet = new CreditRedemptionCalculatorFacet();

        dollarMintCalculatorFacet = new DollarMintCalculatorFacet();
        dollarMintExcessFacet = new DollarMintExcessFacet();
        creditClockFacet = new CreditClockFacet();

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
            "StakingFormulasFacet",
            "CreditNftManagerFacet",
            "CreditNftRedemptionCalculatorFacet",
            "CreditRedemptionCalculatorFacet",
            "DollarMintCalculatorFacet",
            "DollarMintExcessFacet",
            "CreditClockFacet"
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
            owner: admin,
            init: address(dInit),
            initCalldata: abi.encodeWithSelector(
                DiamondInit.init.selector,
                initArgs
            )
        });
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](16);
        setFacet(cuts);
        // deploy diamond

        diamond = new Diamond(_args, cuts);
        IManager = ManagerFacet(address(diamond));
        IAccessControl = AccessControlFacet(address(diamond));
        StakingFacet IStakingFacet = StakingFacet(address(diamond));
        IStakingFacet.setBlockCountInAWeek(420);
        vm.stopBroadcast();
    }

    function setFacet(IDiamondCut.FacetCut[] memory cuts) internal view {
        cuts[0] = (
            IDiamondCut.FacetCut({
                facetAddress: address(dCutFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfDiamondCutFacet
            })
        );

        cuts[1] = (
            IDiamondCut.FacetCut({
                facetAddress: address(dLoupeFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfDiamondLoupeFacet
            })
        );

        cuts[2] = (
            IDiamondCut.FacetCut({
                facetAddress: address(ownerFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfOwnershipFacet
            })
        );

        cuts[3] = (
            IDiamondCut.FacetCut({
                facetAddress: address(managerFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfManagerFacet
            })
        );

        cuts[4] = (
            IDiamondCut.FacetCut({
                facetAddress: address(accessControlFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfAccessControlFacet
            })
        );
        cuts[5] = (
            IDiamondCut.FacetCut({
                facetAddress: address(twapOracleDollar3PoolFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfTWAPOracleDollar3poolFacet
            })
        );

        cuts[6] = (
            IDiamondCut.FacetCut({
                facetAddress: address(collectableDustFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfCollectableDustFacet
            })
        );
        cuts[7] = (
            IDiamondCut.FacetCut({
                facetAddress: address(chefFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfChefFacet
            })
        );
        cuts[8] = (
            IDiamondCut.FacetCut({
                facetAddress: address(stakingFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfStakingFacet
            })
        );
        cuts[9] = (
            IDiamondCut.FacetCut({
                facetAddress: address(stakingFormulasFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfStakingFormulasFacet
            })
        );
        cuts[10] = (
            IDiamondCut.FacetCut({
                facetAddress: address(creditNftManagerFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfCreditNftManagerFacet
            })
        );
        cuts[11] = (
            IDiamondCut.FacetCut({
                facetAddress: address(creditNftRedemptionCalculatorFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfCreditNftRedemptionCalculatorFacet
            })
        );
        cuts[12] = (
            IDiamondCut.FacetCut({
                facetAddress: address(creditRedemptionCalculatorFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfCreditRedemptionCalculatorFacet
            })
        );
        cuts[13] = (
            IDiamondCut.FacetCut({
                facetAddress: address(dollarMintCalculatorFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfDollarMintCalculatorFacet
            })
        );
        cuts[14] = (
            IDiamondCut.FacetCut({
                facetAddress: address(dollarMintExcessFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfDollarMintExcessFacet
            })
        );
        cuts[15] = (
            IDiamondCut.FacetCut({
                facetAddress: address(creditClockFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfCreditClockFacet
            })
        );
    }

    function getSelectors() internal {
        // set all function selectors
        selectorsOfAccessControlFacet = getSelectorsFromAbi(
            "/out/AccessControlFacet.sol/AccessControlFacet.json"
        );
        selectorsOfChefFacet = getSelectorsFromAbi(
            "/out/ChefFacet.sol/ChefFacet.json"
        );
        selectorsOfCollectableDustFacet = getSelectorsFromAbi(
            "/out/CollectableDustFacet.sol/CollectableDustFacet.json"
        );
        selectorsOfCreditClockFacet = getSelectorsFromAbi(
            "/out/CreditClockFacet.sol/CreditClockFacet.json"
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
    }
}
