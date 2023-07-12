// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "./interfaces/IDiamondLoupe.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IERC173} from "./interfaces/IERC173.sol";
import {DiamondCutFacet} from "./facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "./facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "./facets/OwnershipFacet.sol";

/// @notice Struct used for `Diamond` constructor args
struct DiamondArgs {
    address owner;
    address init;
    bytes initCalldata;
}

/**
 * @notice Contract that implements diamond proxy pattern
 * @dev Main protocol's entrypoint
 */
contract Diamond {
    /**
     * @notice Diamond constructor
     * @param _args Init args
     * @param _diamondCutFacets Facets with selectors to add
     */
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

    /**
     * @notice Finds facet for function that is called and executes the
     * function if a facet is found and returns any value
     */
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
}
