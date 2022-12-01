// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../src/manager/interfaces/IDiamondCut.sol";
import "../../src/manager/facets/DiamondCutFacet.sol";
import "../../src/manager/facets/DiamondLoupeFacet.sol";
import "../../src/manager/facets/OwnershipFacet.sol";
import "../../src/manager/facets/ManagerFacet.sol";
import "../../src/manager/Diamond.sol";
import "../../src/manager/upgradeInitializers/DiamondInit.sol";
import "../helpers/DiamondTestHelper.sol";

abstract contract DiamondSetup is DiamondTestHelper {

    // contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupeFacet;
    OwnershipFacet ownerFacet;

    // interfaces with Facet ABI connected to diamond address
    IDiamondLoupe ILoupe;
    IDiamondCut ICut;

    string[] facetNames;
    address[] facetAddressList;

    address owner;
    address admin;
    address user1;
    address contract1;
    address contract2;

    bytes4[] selectorsOfDiamondCutFacet;
    bytes4[] selectorsOfDiamondLoupeFacet;
    bytes4[] selectorsOfOwnershipFacet;
    bytes4[] selectorsOfManagerFacet;

    // deploys diamond and connects facets
    function setUp() public virtual {

        owner = generateAddress("Owner", false, 10 ether);
        admin = generateAddress("Admin", false, 10 ether);
        user1 = generateAddress("User1", false, 10 ether);
        contract1 = generateAddress("Contract1", true, 10 ether);
        contract2 = generateAddress("Contract2", true, 10 ether);

        // set all function selectors
        selectorsOfDiamondCutFacet.push(IDiamondCut.diamondCut.selector);

        selectorsOfDiamondLoupeFacet.push(IDiamondLoupe.facets.selector);
        selectorsOfDiamondLoupeFacet.push(IDiamondLoupe.facetFunctionSelectors.selector);
        selectorsOfDiamondLoupeFacet.push(IDiamondLoupe.facetAddresses.selector);
        selectorsOfDiamondLoupeFacet.push(IDiamondLoupe.facetAddress.selector);
        selectorsOfDiamondLoupeFacet.push(IERC165.supportsInterface.selector);

        selectorsOfOwnershipFacet.push(IERC173.transferOwnership.selector);
        selectorsOfOwnershipFacet.push(IERC173.owner.selector);

        //deploy facets
        dCutFacet = new DiamondCutFacet();
        dLoupeFacet = new DiamondLoupeFacet();
        ownerFacet = new OwnershipFacet();
        DiamondInit dInit = new DiamondInit();

        facetNames = ["DiamondCutFacet", "DiamondLoupeFacet", "OwnershipFacet"];

        // diamod arguments
        DiamondArgs memory _args = DiamondArgs({
            owner: owner,
            init: address(dInit),
            initCalldata: abi.encodeWithSelector(DiamondInit.init.selector)
        });

        FacetCut[] memory diamondCut = new FacetCut[](3);

        diamondCut[0] = FacetCut ({
            facetAddress: address(dCutFacet),
            action: FacetCutAction.Add,
            functionSelectors: selectorsOfDiamondCutFacet
        });

        diamondCut[1] = (
            FacetCut({
            facetAddress: address(dLoupeFacet),
            action: FacetCutAction.Add,
            functionSelectors: selectorsOfDiamondLoupeFacet
            })
        );

        diamondCut[2] = (
            FacetCut({
            facetAddress: address(ownerFacet),
            action: FacetCutAction.Add,
            functionSelectors: selectorsOfOwnershipFacet
            })
        );

        // deploy diamond
        vm.startPrank(owner);
        diamond = new Diamond(_args, diamondCut);
		vm.stopPrank();

        // initialise interfaces
        ILoupe = IDiamondLoupe(address(diamond));
        ICut = IDiamondCut(address(diamond));

        // get all addresses
        facetAddressList = ILoupe.facetAddresses();
    }
}

// tests proper upgrade of diamond when adding a facet
abstract contract AddManagerFacetSetup is DiamondSetup {

    ManagerFacet managerFacet;
    ManagerFacet IManagerFacet;
    
    function setUp() public virtual override {
        super.setUp();
        //deploy ManagerFacet
        managerFacet = new ManagerFacet();
        IManagerFacet = ManagerFacet(address(diamond));

        selectorsOfManagerFacet.push(managerFacet.setDollarTokenAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.setCreditTokenAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.setDebtCouponAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.setGovernanceTokenAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.setSushiSwapPoolAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.setUCRCalculatorAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.setCouponCalculatorAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.setDollarMintingCalculatorAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.setExcessDollarsDistributor.selector);
        selectorsOfManagerFacet.push(managerFacet.setMasterChefAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.setFormulasAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.setBondingShareAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.setStableSwapMetaPoolAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.setBondingContractAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.setTreasuryAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.setIncentiveToUAD.selector);
        selectorsOfManagerFacet.push(managerFacet.deployStableSwapPool.selector);
        selectorsOfManagerFacet.push(managerFacet.getTwapOracleAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.getDollarTokenAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.getCreditTokenAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.getDebtCouponAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.getGovernanceTokenAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.getSushiSwapPoolAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.getUCRCalculatorAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.getCouponCalculatorAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.getDollarMintingCalculatorAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.getExcessDollarsDistributor.selector);
        selectorsOfManagerFacet.push(managerFacet.getMasterChefAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.getFormulasAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.getBondingShareAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.getStableSwapMetaPoolAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.getBondingContractAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.getTreasuryAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.grantRole.selector);

        selectorsOfManagerFacet.push(managerFacet.initialize.selector);

        // array of functions to add
        FacetCut[] memory facetCut = new FacetCut[](1);
        facetCut[0] = FacetCut({
            facetAddress: address(managerFacet),
            action: FacetCutAction.Add,
            functionSelectors: selectorsOfManagerFacet
        });

        // add functions to diamond
        vm.startPrank(owner);
        ICut.diamondCut(facetCut, address(0x0), "");
        IManagerFacet.initialize(admin);
		vm.stopPrank();
    }
}

abstract contract CacheBugSetup is DiamondSetup {

    ManagerFacet managerFacet;

    bytes4 ownerSelector = hex'8da5cb5b';
    bytes4[] selectors;

    function setUp() public virtual override {
        super.setUp();
        managerFacet = new ManagerFacet();

        selectorsOfManagerFacet.push(managerFacet.setDollarTokenAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.setCreditTokenAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.getDollarTokenAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.getCreditTokenAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.getExcessDollarsDistributor.selector);
        selectorsOfManagerFacet.push(managerFacet.initialize.selector);

        // array of functions to add
        FacetCut[] memory facetCut = new FacetCut[](1);
        facetCut[0] = FacetCut({
            facetAddress: address(managerFacet),
            action: FacetCutAction.Add,
            functionSelectors: selectorsOfManagerFacet
        });

        // add functions to diamond
        vm.startPrank(owner);
        ICut.diamondCut(facetCut, address(0x0), "");
        ManagerFacet(address(diamond)).initialize(admin);
		vm.stopPrank();

        // Remove selectors from diamond
        bytes4[] memory newSelectors = new bytes4[](3);

        newSelectors[0] = ownerSelector;
        newSelectors[1] = managerFacet.setDollarTokenAddress.selector;
        newSelectors[2] = managerFacet.getCreditTokenAddress.selector;

        facetCut[0] = FacetCut({
            facetAddress: address(0x0),
            action: FacetCutAction.Remove,
            functionSelectors: newSelectors
        });

        vm.prank(owner);
        ICut.diamondCut(facetCut, address(0x0), "");
    }
}
