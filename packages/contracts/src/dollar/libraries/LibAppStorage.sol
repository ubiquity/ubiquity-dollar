// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibDiamond} from "./LibDiamond.sol";
import {LibAccessControl} from "./LibAccessControl.sol";
import "./Constants.sol";

struct AppStorage {
    // reentrancy guard
    uint256 NOT_ENTERED;
    uint256 ENTERED;
    uint256 reentrancyStatus;
    // others
    address dollarTokenAddress;
    address creditNftAddress;
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
    address ubiquiStickAddress;
    address bondingCurveAddress;
    address bancorFormulaAddress;
    address curveDollarIncentiveAddress;
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
    AppStorage internal store;

    // Getters and setters for each variable in AppStorage

    function getDollarTokenAddress() internal view returns (address) {
        return LibAppStorage.appStorage().dollarTokenAddress;
    }

    function setDollarTokenAddress(address newValue) internal {
        LibAppStorage.appStorage().dollarTokenAddress = newValue;
    }

    function getCreditNftAddress() internal view returns (address) {
        return LibAppStorage.appStorage().creditNftAddress;
    }

    function setCreditNftAddress(address newValue) internal {
        LibAppStorage.appStorage().creditNftAddress = newValue;
    }

    // Implement getters and setters for other variables in AppStorage

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(
            store.reentrancyStatus != store.ENTERED,
            "ReentrancyGuard: reentrant call"
        );

        // Any calls to nonReentrant after this point will fail
        store.reentrancyStatus = store.ENTERED;
        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        store.reentrancyStatus = store.NOT_ENTERED;
    }
            
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlyCreditNFTManager() {
        require(
            LibAccessControl.hasRole(CREDIT_NFT_MANAGER_ROLE, msg.sender),
            "Caller is not a Credit NFT manager"
        );
        _;
    }

    modifier whenNotPaused() {
        require(!LibAppStorage.appStorage().paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(LibAppStorage.appStorage().paused, "Pausable: not paused");
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

    modifier onlyIncentiveAdmin() {
        require(
            LibAccessControl.hasRole(INCENTIVE_MANAGER_ROLE, msg.sender),
            "CreditCalc: not admin"
        );
        _;
    }

    modifier onlyDollarManager() {
        require(
            LibAccessControl.hasRole(CURVE_DOLLAR_MANAGER_ROLE, msg.sender),
            "CurveIncentive: Caller is not Ubiquity Dollar"
        );
        _;
    }
}

