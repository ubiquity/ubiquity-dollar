// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "./LibDiamond.sol";
import {LibAccessControl} from "./LibAccessControl.sol";
import "./Constants.sol";

struct AppStorage {
    // reentrancy guard
    uint256 NOT_ENTERED;
    uint256 ENTERED;
    uint256 reentrancyStatus;
    // others
    address creditNFTAddress;
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
    // pausable
    bool paused;
}

library LibAppStorage {
    function appStorage() internal pure returns (AppStorage storage ds) {
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
            LibAccessControl.hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "MGR: Caller is not admin"
        );
        _;
    }
    modifier onlyMinter() {
        require(
            LibAccessControl.hasRole(GOVERNANCE_TOKEN_MINTER_ROLE, msg.sender),
            "Governance token: not minter"
        );
        _;
    }

    modifier onlyBurner() {
        require(
            LibAccessControl.hasRole(GOVERNANCE_TOKEN_BURNER_ROLE, msg.sender),
            "Governance token: not burner"
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!LibAccessControl.paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(LibAccessControl.paused(), "Pausable: not paused");
        _;
    }

    modifier onlyStakingManager() {
        require(
            LibAccessControl.hasRole(STAKING_MANAGER_ROLE, msg.sender),
            "not manager"
        );
        _;
    }

    modifier onlyPauser() {
        require(
            LibAccessControl.hasRole(PAUSER_ROLE, msg.sender),
            "not pauser"
        );
        _;
    }
    modifier onlyTokenManager() {
        require(
            LibAccessControl.hasRole(GOVERNANCE_TOKEN_MANAGER_ROLE, msg.sender),
            "MasterChef: not Governance Token manager"
        );
        _;
    }
}
