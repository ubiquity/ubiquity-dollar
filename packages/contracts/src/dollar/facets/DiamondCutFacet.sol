// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

/**
 * @notice Facet used for diamond selector modifications
 * @dev Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
 * The loupe functions are required by the EIP2535 Diamonds standard.
 */
contract DiamondCutFacet is IDiamondCut {
    /// @inheritdoc IDiamondCut
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }
}
