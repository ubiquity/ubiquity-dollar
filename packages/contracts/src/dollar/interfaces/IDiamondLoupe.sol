// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @notice A loupe is a small magnifying glass used to look at diamonds.
 * These functions look at diamonds.
 * @dev These functions are expected to be called frequently by 3rd party tools.
 */
interface IDiamondLoupe {
    /// @notice Struct used as a mapping of facet to function selectors
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /**
     * @notice Returns all facet addresses and their four byte function selectors
     * @return facets_ Facets with function selectors
     */
    function facets() external view returns (Facet[] memory facets_);

    /**
     * @notice Returns all function selectors supported by a specific facet
     * @param _facet Facet address
     * @return facetFunctionSelectors_ Function selectors for a particular facet
     */
    function facetFunctionSelectors(
        address _facet
    ) external view returns (bytes4[] memory facetFunctionSelectors_);

    /**
     * @notice Returns all facet addresses used by a diamond
     * @return facetAddresses_ Facet addresses in a diamond
     */
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    /**
     * @notice Returns the facet that supports the given selector
     * @dev If facet is not found returns `address(0)`
     * @param _functionSelector Function selector
     * @return facetAddress_ Facet address
     */
    function facetAddress(
        bytes4 _functionSelector
    ) external view returns (address facetAddress_);
}
