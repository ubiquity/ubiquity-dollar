// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DiamondTestSetup.sol";

contract TestDiamond is DiamondSetup {

    function testHasThreeFacets() public {
        assertEq(facetAddressList.length, 3);
    }

    function testFacetsHaveCorrectSelectors() public {
        for (uint i = 0; i < facetAddressList.length; i++) {
            bytes4[] memory fromLoupeFacet = ILoupe.facetFunctionSelectors(facetAddressList[i]);
            if(compareStrings(facetNames[i], 'DiamondCutFacet')) {
                assertTrue(sameMembers(fromLoupeFacet, selectorsOfDiamondCutFacet));
            } else if (compareStrings(facetNames[i], 'DiamondLoupeFacet')) {
                assertTrue(sameMembers(fromLoupeFacet, selectorsOfDiamondLoupeFacet));
            } else if (compareStrings(facetNames[i], 'OwnershipFacet')) {
                assertTrue(sameMembers(fromLoupeFacet, selectorsOfOwnershipFacet));
            } else if (compareStrings(facetNames[i], 'ManagerFacet')) {
                assertTrue(sameMembers(fromLoupeFacet, selectorsOfManagerFacet));
            }
        }
    }

    function testSelectorsAssociatedWithCorrectFacet() public {
        for (uint i = 0; i < facetAddressList.length; i++) {
            if(compareStrings(facetNames[i], 'DiamondCutFacet')) {
                for (uint j = 0; i < selectorsOfDiamondCutFacet.length; i++) {
                    assertEq(facetAddressList[i], ILoupe.facetAddress(selectorsOfDiamondCutFacet[j]));
                }
            } else if (compareStrings(facetNames[i], 'DiamondLoupeFacet')) {
                for (uint j = 0; i < selectorsOfDiamondLoupeFacet.length; i++) {
                    assertEq(facetAddressList[i], ILoupe.facetAddress(selectorsOfDiamondLoupeFacet[j]));
                }
            } else if (compareStrings(facetNames[i], 'OwnershipFacet')) {
                for (uint j = 0; i < selectorsOfOwnershipFacet.length; i++) {
                    assertEq(facetAddressList[i], ILoupe.facetAddress(selectorsOfOwnershipFacet[j]));
                }
            } else if (compareStrings(facetNames[i], 'ManagerFacet')) {
                for (uint j = 0; i < selectorsOfManagerFacet.length; i++) {
                    assertEq(facetAddressList[i], ILoupe.facetAddress(selectorsOfManagerFacet[j]));
                }
            }
        }
    }
}

contract TestAddManagerFacet is AddManagerFacetSetup {

    function testAddManagerFacetFunctions() public {
        // check if functions added to diamond
        bytes4[] memory fromLoupeFacet = ILoupe.facetFunctionSelectors(address(managerFacet));
        assertTrue(sameMembers(fromLoupeFacet, selectorsOfManagerFacet));
    }

    // Replace supportsInterface function in DiamondLoupeFacet with one in ManagerFacet
    function testReplaceSupportsInterfaceFunction() public prankAs(owner) {
        // get supportsInterface selector
        bytes4[] memory functionSelectors =  new bytes4[](1);
        functionSelectors[0] = managerFacet.supportsInterface.selector;

        // struct to replace function
        FacetCut[] memory cutTest1 = new FacetCut[](1);
        cutTest1[0] =
            FacetCut({
            facetAddress: address(managerFacet),
            action: FacetCutAction.Replace,
            functionSelectors: functionSelectors
        });

        // replace function by function on Manager facet
        ICut.diamondCut(cutTest1, address(0x0), "");

        // check supportsInterface method connected to managerFacet
        assertEq(address(managerFacet), ILoupe.facetAddress(functionSelectors[0]));
    }
}

contract TestCacheBug is CacheBugSetup {

    function testNoCacheBug() public {
        bytes4[] memory fromLoupeSelectors = ILoupe.facetFunctionSelectors(address(managerFacet));

        assertTrue(containsElement(fromLoupeSelectors, managerFacet.getDollarTokenAddress.selector));
        assertTrue(containsElement(fromLoupeSelectors, managerFacet.setCreditTokenAddress.selector));
        assertTrue(containsElement(fromLoupeSelectors, managerFacet.getExcessDollarsDistributor.selector));
        assertTrue(containsElement(fromLoupeSelectors, managerFacet.initialize.selector));

        assertFalse(containsElement(fromLoupeSelectors, ownerSelector));
        assertFalse(containsElement(fromLoupeSelectors, managerFacet.setDollarTokenAddress.selector));
        assertFalse(containsElement(fromLoupeSelectors, managerFacet.getCreditTokenAddress.selector));
    }
}
