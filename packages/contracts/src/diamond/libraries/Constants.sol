// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
bytes32 constant GOVERNANCE_TOKEN_MINTER_ROLE = keccak256(
    "GOVERNANCE_TOKEN_MINTER_ROLE"
);
bytes32 constant GOVERNANCE_TOKEN_BURNER_ROLE = keccak256(
    "GOVERNANCE_TOKEN_BURNER_ROLE"
);
bytes32 constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
bytes32 constant CREDIT_NFT_MANAGER_ROLE = keccak256("CREDIT_NFT_MANAGER_ROLE");
bytes32 constant STAKING_MANAGER_ROLE = keccak256("STAKING_MANAGER_ROLE");
bytes32 constant INCENTIVE_MANAGER_ROLE = keccak256("INCENTIVE_MANAGER");
bytes32 constant GOVERNANCE_TOKEN_MANAGER_ROLE = keccak256(
    "GOVERNANCE_TOKEN_MANAGER_ROLE"
);

address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
uint256 constant ONE = uint256(1 ether); // 3Crv has 18 decimals

// keccak256("Permit(address owner,address spender,
//                   uint256 value,uint256 nonce,uint256 deadline)");
bytes32 constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
