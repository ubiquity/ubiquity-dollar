// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../src/diamond/interfaces/IDiamondCut.sol";
import "../../src/diamond/facets/DiamondCutFacet.sol";
import "../../src/diamond/facets/DiamondLoupeFacet.sol";
import "../../src/diamond/facets/OwnershipFacet.sol";
import "../../src/diamond/facets/ManagerFacet.sol";
import "../../src/diamond/Diamond.sol";
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
    address user1;
    address contract1;

    // deploys diamond and connects facets
    function setUp() public virtual {

        owner = generateAddress("Owner", false, 10 ether);
        user1 = generateAddress("User1", false, 10 ether);
        contract1 = generateAddress("Contract1", true, 10 ether);

        //deploy facets
        dCutFacet = new DiamondCutFacet();
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        facetNames = ["DiamondCutFacet", "DiamondLoupeFacet", "OwnershipFacet"];

        // deploy diamond
        diamond = new Diamond(owner, address(dCutFacet));

        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](2);

        cut[0] = FacetCut({
            facetAddress: address(dLoupe),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("DiamondLoupeFacet")
        });

        cut[1] = FacetCut({
            facetAddress: address(ownerF),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("OwnershipFacet")
        });


        // initialise interfaces
        ILoupe = IDiamondLoupe(address(diamond));
        ICut = IDiamondCut(address(diamond));

        //upgrade diamond
        vm.startPrank(owner);
        ICut.diamondCut(cut, address(0x0), "");
		vm.stopPrank();

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
        managerFacet = new ManagerFacet(owner);

        // bytes4[] memory fromGenSelectors  = generateSelectors("ManagerFacet"); // all length is 51
        bytes4[] memory selectorsInManagerFacet = new bytes4[](5);
        selectorsInManagerFacet[0] = getSelector(
            "setTwapOracleAddress(address)"
        );
        selectorsInManagerFacet[1] = getSelector(
            "setuARTokenAddress(address)"
        );
        selectorsInManagerFacet[2] = getSelector(
            "setDebtCouponAddress(address)"
        );
        selectorsInManagerFacet[3] = getSelector(
            "setIncentiveToUAD(address)"
        );
        selectorsInManagerFacet[4] = getSelector(
            "getExcessDollarsDistributor(address)"
        );

        bytes4[] memory fromGenSelectors = selectorsInManagerFacet;

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
		vm.stopPrank();
    }
}

abstract contract CacheBugSetup is DiamondSetup {

    ManagerFacet managerFacet;

    bytes4 ownerSel = hex'8da5cb5b';
    bytes4[] selectors;

    function setUp() public virtual override {
        super.setUp();
        managerFacet = new ManagerFacet(owner);

        selectors.push(hex'19e3b533');
        selectors.push(hex'0716c2ae');
        selectors.push(hex'11046047');
        selectors.push(hex'cf3bbe18');
        selectors.push(hex'24c1d5a7');
        selectors.push(hex'cbb835f6');
        selectors.push(hex'cbb835f7');
        selectors.push(hex'cbb835f8');
        selectors.push(hex'cbb835f9');
        selectors.push(hex'cbb835fa');
        selectors.push(hex'cbb835fb');

        FacetCut[] memory cut = new FacetCut[](1);
        bytes4[] memory selectorsAdd = new bytes4[](11);

        for(uint i = 0; i < selectorsAdd.length; i++){
            selectorsAdd[i] = selectors[i];
        }

        cut[0] = FacetCut({
            facetAddress: address(managerFacet),
            action: FacetCutAction.Add,
            functionSelectors: selectorsAdd
        });

        // add managerFacet to diamond
        vm.startPrank(owner);
        ICut.diamondCut(cut, address(0x0), "");
		vm.stopPrank();

        // Remove selectors from diamond
        bytes4[] memory newSelectors = new bytes4[](3);
        newSelectors[0] = ownerSel;
        newSelectors[1] = selectors[5];
        newSelectors[2] = selectors[10];

        cut[0] = FacetCut({
            facetAddress: address(0x0),
            action: FacetCutAction.Remove,
            functionSelectors: newSelectors
        });

        vm.startPrank(owner);
        ICut.diamondCut(cut, address(0x0), "");
		vm.stopPrank();
    }
}
