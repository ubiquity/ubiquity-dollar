// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract MockUBQmanager is AccessControl {
    bytes32 public constant GOV_TOKEN_MINTER_ROLE = keccak256("GOV_TOKEN_MINTER_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setupMinterRole(address to) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Governance token: not minter"
        );
        _setupRole(GOV_TOKEN_MINTER_ROLE, to);
    }
}
