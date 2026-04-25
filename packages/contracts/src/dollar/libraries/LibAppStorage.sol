// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LibDiamond} from "./LibDiamond.sol";
import {LibAccessControl} from "./LibAccessControl.sol";
import "./Constants.sol";

/// @notice Shared struct used as a storage in the `LibAppStorage` library
struct AppStorage {
    // reentrancy guard
    uint256 reentrancyStatus;
    // others
    address dollarTokenAddress;
    address creditNftAddress;
    address creditNftCalculatorAddress;
    address dollarMintCalculatorAddress;
    address stakingShareAddress;
    address stakingContractAddress;
    address stableSwapMetaPoolAddress;
    address stableSwapPlainPoolAddress;
    address curve3PoolTokenAddress; // 3CRV
    address treasuryAddress;
    address governanceTokenAddress;
    address sushiSwapPoolAddress; // sushi pool UbiquityDollar-GovernanceToken
    address masterChefAddress;
    address formulasAddress;
    address creditTokenAddress;
    address creditCalculatorAddress;
    address ubiquiStickAddress;
    address bondingCurveAddress;
    address bancorFormulaAddress;
    address curveDollarIncentiveAddress;
    mapping(address => address) _excessDollarDistributors;
    // pausable
    bool paused;
    // Liquity V1 Stability Pool integration (#997)
    uint256 totalPrincipalInPool;
    address liquidityStabilityPool;
    address liquidityTreasury;
    uint256 liquidityHarvestThreshold;
    bool liquidityPaused;
    address lusdToken;
    address lqtyToken;
}

/// @notice Library used as a shared storage among all protocol libraries
library LibAppStorage {
    function appStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

/// @notice Contract includes modifiers shared across all protocol's contracts
contract Modifiers {
    AppStorage internal store;

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }
    function _nonReentrantBefore() internal {
        require(store.reentrancyStatus != _ENTERED, "ReentrancyGuard: reentrant call");
        store.reentrancyStatus = _ENTERED;
    }
    function _nonReentrantAfter() internal {
        store.reentrancyStatus = _NOT_ENTERED;
    }

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlyCreditNftManager() {
        require(LibAccessControl.hasRole(CREDIT_NFT_MANAGER_ROLE, msg.sender), "not manager");
        _;
    }

    modifier onlyAdmin() {
        require(LibAccessControl.hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "not admin");
        _;
    }

    modifier onlyMinter() {
        require(LibAccessControl.hasRole(GOVERNANCE_TOKEN_MINTER_ROLE, msg.sender), "not minter");
        _;
    }

    modifier onlyBurner() {
        require(LibAccessControl.hasRole(GOVERNANCE_TOKEN_BURNER_ROLE, msg.sender), "not burner");
        _;
    }

    modifier whenNotPaused() {
        require(!LibAccessControl.paused(), "paused");
        _;
    }

    modifier whenPaused() {
        require(LibAccessControl.paused(), "not paused");
        _;
    }

    modifier onlyStakingManager() {
        require(LibAccessControl.hasRole(STAKING_MANAGER_ROLE, msg.sender), "not manager");
        _;
    }

    modifier onlyPauser() {
        require(LibAccessControl.hasRole(PAUSER_ROLE, msg.sender), "not pauser");
        _;
    }

    modifier onlyTokenManager() {
        require(LibAccessControl.hasRole(GOVERNANCE_TOKEN_MANAGER_ROLE, msg.sender), "not token manager");
        _;
    }

    modifier onlyIncentiveAdmin() {
        require(LibAccessControl.hasRole(INCENTIVE_MANAGER_ROLE, msg.sender), "not incentive admin");
        _;
    }

    modifier onlyDollarManager() {
        require(LibAccessControl.hasRole(CURVE_DOLLAR_MANAGER_ROLE, msg.sender), "not dollar manager");
        _;
    }

    function _initReentrancyGuard() internal {
        store.reentrancyStatus = _NOT_ENTERED;
    }
}
