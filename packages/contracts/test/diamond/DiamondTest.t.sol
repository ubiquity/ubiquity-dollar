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
            bytes4[] memory fromGenSelectors =  generateSelectors(facetNames[i]);
            assertTrue(sameMembers(fromLoupeFacet, fromGenSelectors));
        }
    }

    function testSelectorsAssociatedWithCorrectFacet() public {
        for (uint i = 0; i < facetAddressList.length; i++) {
            bytes4[] memory fromGenSelectors =  generateSelectors(facetNames[i]);
            for (uint j = 0; i < fromGenSelectors.length; i++) {
                assertEq(facetAddressList[i], ILoupe.facetAddress(fromGenSelectors[j]));
            }
        }
    }
}

contract TestAddManagerFacet is AddManagerFacetSetup {

    function testAddManagerFacetFunctions() public {
        // check if functions added to diamond
        bytes4[] memory fromLoupeFacet = ILoupe.facetFunctionSelectors(address(managerFacet));
        bytes4[] memory selectorsInManagerFacet = new bytes4[](6);
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
        selectorsInManagerFacet[5] = getSelector(
            "initialize(address)"
        );
        assertTrue(sameMembers(fromLoupeFacet, selectorsInManagerFacet));
    }

    function testCanCallManagerFacetFunction() public {
         // try to call function on new Facet
        ManagerFacet(address(diamond)).getExcessDollarsDistributor(contract1);
    }

    function testCanCallManagerFacetAdminFunction_OnlyWith_Admin() public prankAs(owner) {
         // try to call function with access control on new Facet 
        ManagerFacet(address(diamond)).setuARTokenAddress(contract1);
    }

    // Replace supportsInterface function in DiamondLoupeFacet with one in ManagerFacet(imported from Openzepplin contract)
    function test6ReplaceSupportsInterfaceFunction() public prankAs(owner) {

        // get supportsInterface selector
        bytes4[] memory functionSelectors =  new bytes4[](1);
        bytes4 selectorSupportsInterface = getSelector(
            "supportsInterface(bytes4)"
        );
        functionSelectors[0] = selectorSupportsInterface;

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

        assertTrue(containsElement(fromLoupeSelectors, selectors[0]));
        assertTrue(containsElement(fromLoupeSelectors, selectors[1]));
        assertTrue(containsElement(fromLoupeSelectors, selectors[2]));
        assertTrue(containsElement(fromLoupeSelectors, selectors[3]));
        assertTrue(containsElement(fromLoupeSelectors, selectors[4]));
        assertTrue(containsElement(fromLoupeSelectors, selectors[6]));
        assertTrue(containsElement(fromLoupeSelectors, selectors[7]));
        assertTrue(containsElement(fromLoupeSelectors, selectors[8]));
        assertTrue(containsElement(fromLoupeSelectors, selectors[9]));

        assertFalse(containsElement(fromLoupeSelectors, ownerSel));
        assertFalse(containsElement(fromLoupeSelectors, selectors[10]));
        assertFalse(containsElement(fromLoupeSelectors, selectors[5]));
    }
}
