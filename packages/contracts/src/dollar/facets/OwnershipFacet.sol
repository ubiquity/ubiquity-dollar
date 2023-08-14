// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IERC173} from "../interfaces/IERC173.sol";

/// @notice Used for managing contract's owner
contract OwnershipFacet is IERC173 {
    /// @inheritdoc IERC173
    function transferOwnership(address _newOwner) external override {
        require(
            (_newOwner != address(0)),
            "OwnershipFacet: New owner cannot be the zero address"
        );
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    /// @inheritdoc IERC173
    function owner() external view override returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}
