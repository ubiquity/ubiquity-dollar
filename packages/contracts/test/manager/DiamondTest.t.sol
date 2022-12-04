// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DiamondTestSetup.sol";

contract TestDiamond is DiamondSetup {

    function testShouldSupportInspectingFacetsAndFunctions() public {
        bool isSupported = IERC165(address(diamond))
            .supportsInterface(type(IDiamondLoupe).interfaceId);
        assertEq(isSupported, true);
    }

    function testHasFourFacets() public {
        assertEq(facetAddressList.length, 4);
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
        console.log('facetAddressList', facetAddressList.length);
        for (uint i = 0; i < facetAddressList.length; i++) {
            console.log('facetNames', i, facetNames[i]);
            if(compareStrings(facetNames[i], 'DiamondCutFacet')) {
                for (uint j = 0; j < selectorsOfDiamondCutFacet.length; j++) {
                    assertEq(facetAddressList[i], ILoupe.facetAddress(selectorsOfDiamondCutFacet[j]));
                }
            } else if (compareStrings(facetNames[i], 'DiamondLoupeFacet')) {
                for (uint j = 0; j < selectorsOfDiamondLoupeFacet.length; j++) {
                    assertEq(facetAddressList[i], ILoupe.facetAddress(selectorsOfDiamondLoupeFacet[j]));
                }
            } else if (compareStrings(facetNames[i], 'OwnershipFacet')) {
                for (uint j = 0; j < selectorsOfOwnershipFacet.length; j++) {
                    assertEq(facetAddressList[i], ILoupe.facetAddress(selectorsOfOwnershipFacet[j]));
                }
            } else if (compareStrings(facetNames[i], 'ManagerFacet')) {
                for (uint j = 0; j < selectorsOfManagerFacet.length; j++) {
                    assertEq(facetAddressList[i], ILoupe.facetAddress(selectorsOfManagerFacet[j]));
                }
            }
        }
    }

}