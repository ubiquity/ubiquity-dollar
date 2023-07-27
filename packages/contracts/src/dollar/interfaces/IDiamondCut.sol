// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @notice Interface that allows modifications to diamond function selector mapping
interface IDiamondCut {
    /**
     * @notice Available diamond operations
     * @dev Add=0, Replace=1, Remove=2
     */
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    /// @notice Struct used as a mapping of facet to function selectors
    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /**
     * @notice Add/replace/remove any number of functions and optionally execute a function with delegatecall
     * @param _diamondCut Contains the facet addresses and function selectors
     * @param _init The address of the contract or facet to execute _calldata
     * @param _calldata A function call, including function selector and arguments
     * @dev `_calldata` is executed with delegatecall on `_init`
     */
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    /// @notice Emitted when facet selectors are modified
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}
