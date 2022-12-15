// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "./LibDiamond.sol";
import "../access/AccessControl.sol";
import {AccessControlStorage} from "../libraries/AccessControlStorage.sol";

bytes32 constant GOVERNANCE_TOKEN_MINTER_ROLE =
    keccak256("GOVERNANCE_TOKEN_MINTER_ROLE");
bytes32 constant GOVERNANCE_TOKEN_BURNER_ROLE =
    keccak256("GOVERNANCE_TOKEN_BURNER_ROLE");
bytes32 constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
bytes32 constant CREDIT_NFT_MANAGER_ROLE = keccak256("CREDIT_NFT_MANAGER_ROLE");
bytes32 constant STAKING_MANAGER_ROLE = keccak256("STAKING_MANAGER_ROLE");
bytes32 constant INCENTIVE_MANAGER_ROLE = keccak256("INCENTIVE_MANAGER");
bytes32 constant GOVERNANCE_TOKEN_MANAGER_ROLE =
    keccak256("GOVERNANCE_TOKEN_MANAGER_ROLE");

struct AppStorage {
    address twapOracleAddress;
    address creditNFTAddress;
    address dollarTokenAddress;
    address creditNFTCalculatorAddress;
    address dollarMintCalculatorAddress;
    address stakingShareAddress;
    address stakingContractAddress;
    address stableSwapMetaPoolAddress;
    address curve3PoolTokenAddress; // 3CRV
    address treasuryAddress;
    address governanceTokenAddress;
    address sushiSwapPoolAddress; // sushi pool UbiquityDollar-GovernanceToken
    address masterChefAddress;
    address formulasAddress;
    address creditTokenAddress;
    address creditCalculatorAddress;
    mapping(address => address) _excessDollarDistributors;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers is AccessControl {
    AppStorage internal s;

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlyAdmin() {
        require(
            _hasRole(AccessControlStorage.DEFAULT_ADMIN_ROLE, msg.sender),
            "MGR: Caller is not admin"
        );
        _;
    }
}
