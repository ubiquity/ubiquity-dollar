// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract MockUBQmanager is AccessControl {
    bytes32 public constant GOVERNANCE_TOKEN_MINTER_ROLE =
        keccak256("GOVERNANCE_TOKEN_MINTER_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setupMinterRole(address to) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Governance token: not minter"
        );
        _setupRole(GOVERNANCE_TOKEN_MINTER_ROLE, to);
    }
}
