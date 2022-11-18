// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "./LibDiamond.sol";
import "solidstate/contracts/access/access_control/AccessControl.sol";
import { AccessControlStorage } from "solidstate/contracts/access/access_control/AccessControlStorage.sol";

bytes32 constant UBQ_MINTER_ROLE = keccak256("UBQ_MINTER_ROLE");
bytes32 constant UBQ_BURNER_ROLE = keccak256("UBQ_BURNER_ROLE");
bytes32 constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
bytes32 constant COUPON_MANAGER_ROLE = keccak256("COUPON_MANAGER");
bytes32 constant BONDING_MANAGER_ROLE = keccak256("BONDING_MANAGER");
bytes32 constant INCENTIVE_MANAGER_ROLE = keccak256("INCENTIVE_MANAGER");
bytes32 constant UBQ_TOKEN_MANAGER_ROLE = keccak256("UBQ_TOKEN_MANAGER_ROLE");

struct AppStorage {
    address twapOracleAddress;
    address debtCouponAddress;
    address dollarTokenAddress; // uAD
    address couponCalculatorAddress;
    address dollarMintingCalculatorAddress;
    address bondingShareAddress;
    address bondingContractAddress;
    address stableSwapMetaPoolAddress;
    address curve3PoolTokenAddress; // 3CRV
    address treasuryAddress;
    address governanceTokenAddress; // uGOV
    address sushiSwapPoolAddress; // sushi pool uAD-uGOV
    address masterChefAddress;
    address formulasAddress;
    address creditTokenAddress; // uCR
    address ucrCalculatorAddress; // uCR calculator
    // couponmanager => excessdollardistributor
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
            "uADMGR: Caller is not admin"
        );
        _;
    }
}
