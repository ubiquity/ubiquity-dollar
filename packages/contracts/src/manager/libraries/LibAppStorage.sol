// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "./LibDiamond.sol";
import {LibAccessControl} from "./LibAccessControl.sol";

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

struct AppStorage {
    // reentrancy guard
    uint256 NOT_ENTERED;
    uint256 ENTERED;
    uint256 reentrancyStatus;
    // others
    address twapOracleAddress;
    address creditNftAddress;
    address dollarTokenAddress;
    address creditNftCalculatorAddress;
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

contract Modifiers {
    AppStorage internal s;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.

     * @dev Works identically to OZ's nonReentrant.
     * @dev Used to avoid state storage collision within diamond.
     */

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(
            s.reentrancyStatus != s.ENTERED,
            "ReentrancyGuard: reentrant call"
        );

        // Any calls to nonReentrant after this point will fail
        s.reentrancyStatus = s.ENTERED;
        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        s.reentrancyStatus = s.NOT_ENTERED;
    }

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlyAdmin() {
        require(
            LibAccessControl._hasRole(
                LibAccessControl.DEFAULT_ADMIN_ROLE,
                msg.sender
            ),
            "MGR: Caller is not admin"
        );
        _;
    }
}
