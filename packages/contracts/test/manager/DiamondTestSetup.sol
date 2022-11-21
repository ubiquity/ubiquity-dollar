// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../src/manager/interfaces/IDiamondCut.sol";
import "../../src/manager/facets/DiamondCutFacet.sol";
import "../../src/manager/facets/DiamondLoupeFacet.sol";
import "../../src/manager/facets/OwnershipFacet.sol";
import "../../src/manager/facets/ManagerFacet.sol";
import "../../src/manager/Diamond.sol";
import "../helpers/DiamondTestHelper.sol";

abstract contract DiamondSetup is DiamondTestHelper {

    // contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;

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

    // deploys diamond and connects facets
    function setUp() public virtual {

        owner = generateAddress("Owner", false, 10 ether);
        admin = generateAddress("Admin", false, 10 ether);
        user1 = generateAddress("User1", false, 10 ether);
        contract1 = generateAddress("Contract1", true, 10 ether);
        contract2 = generateAddress("Contract2", true, 10 ether);

        //deploy facets
        dCutFacet = new DiamondCutFacet();
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        facetNames = ["DiamondCutFacet", "DiamondLoupeFacet", "OwnershipFacet"];

        // deploy diamond
        vm.startPrank(owner);
        diamond = new Diamond(owner);
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

    function setUp() public virtual override {
        super.setUp();
        //deploy ManagerFacet
        managerFacet = new ManagerFacet();

        bytes4[] memory fromGenSelectors  = removeElement(managerFacet.supportsInterface.selector, generateSelectors("ManagerFacet"));

        // array of functions to add
        FacetCut[] memory facetCut = new FacetCut[](1);
        facetCut[0] = FacetCut({
            facetAddress: address(managerFacet),
            action: FacetCutAction.Add,
            functionSelectors: fromGenSelectors
        });

        // add functions to diamond
        vm.startPrank(owner);
        ICut.diamondCut(facetCut, address(0x0), "");
        ManagerFacet(address(diamond)).initialize(admin);
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

       bytes4[] memory fromGenSelectors  = removeElement(managerFacet.supportsInterface.selector, generateSelectors("ManagerFacet"));

        // array of functions to add
        FacetCut[] memory facetCut = new FacetCut[](1);
        facetCut[0] = FacetCut({
            facetAddress: address(managerFacet),
            action: FacetCutAction.Add,
            functionSelectors: fromGenSelectors
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
