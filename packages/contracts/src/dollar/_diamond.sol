// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LibDiamond} from "././libraries/lib-diamond.sol";
import {IDiamondCut} from "./interfaces/i-diamond-cut.sol";
import {IDiamondLoupe} from "./interfaces/i-diamond-loupe.sol";
import "@openzeppelin/contracts/interfaces/ierc165.sol";
import {IERC173} from "./interfaces/ierc-173.sol";
import {DiamondCutFacet} from "./facets/diamond-cut-facet.sol";
import {DiamondLoupeFacet} from "./facets/diamond-loupe-facet.sol";
import {OwnershipFacet} from "./facets/ownership-facet.sol";

struct DiamondArgs {
    address owner;
    address init;
    bytes initCalldata;
}

contract Diamond {
    constructor(
        DiamondArgs memory _args,
        IDiamondCut.FacetCut[] memory _diamondCutFacets
    ) {
        LibDiamond.setContractOwner(_args.owner);
        LibDiamond.diamondCut(
            _diamondCutFacets,
            _args.init,
            _args.initCalldata
        );
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}
