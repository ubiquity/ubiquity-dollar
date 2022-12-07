// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

interface IUBQManager {
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function GOVERNANCE_TOKEN_MINTER_ROLE() external view returns (bytes32);
}
