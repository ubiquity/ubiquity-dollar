// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LibDiamond} from "../libraries/lib-diamond.sol";
import {IDiamondLoupe} from "../interfaces/i-diamond-loupe.sol";
import {IDiamondCut} from "../interfaces/i-diamond-cut.sol";
import {IERC173} from "../interfaces/ierc-173.sol";
import "../libraries/lib-app-storage.sol";
import "../libraries/lib-access-control.sol";
import {UbiquityDollarToken} from "../core/ubiquity-dollar-token.sol";
import {UbiquityGovernanceToken} from "../core/ubiquity-governance-token.sol";
import "@openzeppelin/contracts/interfaces/ierc-165.sol";
import {LibTWAPOracle} from "../libraries/lib-twap-oracle.sol";
import {LibStaking} from "../libraries/lib-staking.sol";
import {LibChef} from "../libraries/lib-chef.sol";
import {LibCreditNftManager} from "../libraries/lib-credit-nft-manager.sol";
import {LibCreditRedemptionCalculator} from "../libraries/lib-credit-redemption-calculator.sol";
import {LibUbiquityPool} from "../libraries/lib-ubiquity-pool.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init function if you need to.

contract DiamondInit is Modifiers {
    struct Args {
        address admin;
        address[] tos;
        uint256[] amounts;
        uint256[] stakingShareIDs;
        uint256 governancePerBlock;
        uint256 creditNFTLengthBlocks;
    }

    // You can add parameters to this function in order to pass in
    // data to set your own state variables
    function init(Args memory _args) external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        LibAccessControl.grantRole(DEFAULT_ADMIN_ROLE, _args.admin);
        LibAccessControl.grantRole(GOVERNANCE_TOKEN_MINTER_ROLE, _args.admin);
        LibAccessControl.grantRole(GOVERNANCE_TOKEN_BURNER_ROLE, _args.admin);
        LibAccessControl.grantRole(CREDIT_TOKEN_MINTER_ROLE, _args.admin);
        LibAccessControl.grantRole(CREDIT_TOKEN_BURNER_ROLE, _args.admin);
        LibAccessControl.grantRole(DOLLAR_TOKEN_MINTER_ROLE, _args.admin);
        LibAccessControl.grantRole(DOLLAR_TOKEN_BURNER_ROLE, _args.admin);
        LibAccessControl.grantRole(PAUSER_ROLE, _args.admin);
        LibAccessControl.grantRole(CREDIT_NFT_MANAGER_ROLE, _args.admin);
        LibAccessControl.grantRole(STAKING_MANAGER_ROLE, _args.admin);
        LibAccessControl.grantRole(INCENTIVE_MANAGER_ROLE, _args.admin);
        LibAccessControl.grantRole(GOVERNANCE_TOKEN_MANAGER_ROLE, _args.admin);

        AppStorage storage appStore = LibAppStorage.appStorage();

        appStore.paused = false;
        appStore.treasuryAddress = _args.admin;
        // staking
        LibStaking.StakingData storage ls = LibStaking.stakingStorage();
        ls.stakingDiscountMultiplier = uint256(0.001 ether); // 0.001
        ls.blockCountInAWeek = 45361;

        // reentrancy guard
        _initReentrancyGuard();

        // ubiquity chef before doing that we should have a metapool address
        LibChef.initialize(
            _args.tos,
            _args.amounts,
            _args.stakingShareIDs,
            _args.governancePerBlock
        );
        // creditNFTManager
        /// @param _creditNFTLengthBlocks how many blocks Credit NFT last. can't be changed
        /// once set (unless migrated)
        LibCreditNftManager.creditNFTStorage().creditNFTLengthBlocks = _args
            .creditNFTLengthBlocks;
        LibCreditNftManager
            .creditNFTStorage()
            .expiredCreditNFTConversionRate = 2;

        LibCreditRedemptionCalculator
            .creditRedemptionCalculatorStorage()
            .coef = 1 ether;
        // add your own state variables
        // EIP-2535 specifies that the `diamondCut` function takes two optional
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface

        LibUbiquityPool.UbiquityPoolStorage storage poolStore = LibUbiquityPool
            .ubiquityPoolStorage();
        poolStore.mintingFee = 0;
        poolStore.redemptionFee = 0;
        poolStore.dollarFloor = 1000000000000000000;
    }
}
