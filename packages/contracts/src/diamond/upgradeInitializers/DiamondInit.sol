// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IERC173} from "../interfaces/IERC173.sol";
import "../libraries/LibAppStorage.sol";
import "../libraries/LibAccessControl.sol";
import {StakingShare} from "../../dollar/StakingShare.sol";
//import {UbiquityGovernanceToken} from "../../dollar/core/UbiquityGovernanceToken.sol";
import {UbiquityGovernanceTokenForDiamond} from "../token/UbiquityGovernanceTokenForDiamond.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import {LibTWAPOracle} from "../libraries/LibTWAPOracle.sol";
import {LibUbiquityDollar} from "../libraries/LibUbiquityDollar.sol";
import {LibStaking} from "../libraries/LibStaking.sol";
import {LibUbiquityChef} from "../libraries/LibUbiquityChef.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init function if you need to.

contract DiamondInit is Modifiers {
    struct Args {
        address admin;
        string dollarName;
        string dollarSymbol;
        uint8 dollarDecimals;
        address[] tos;
        uint256[] amounts;
        uint256[] stakingShareIDs;
        uint256 governancePerBlock;
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
        LibAccessControl.grantRole(PAUSER_ROLE, _args.admin);
        LibAccessControl.grantRole(CREDIT_NFT_MANAGER_ROLE, _args.admin);
        LibAccessControl.grantRole(STAKING_MANAGER_ROLE, _args.admin);
        LibAccessControl.grantRole(INCENTIVE_MANAGER_ROLE, _args.admin);
        LibAccessControl.grantRole(GOVERNANCE_TOKEN_MANAGER_ROLE, _args.admin);
        AppStorage storage appStore = LibAppStorage.appStorage();

        appStore.paused = false;
        appStore.treasuryAddress = _args.admin;
        // Dollar
        LibUbiquityDollar.initialize(
            _args.dollarName,
            _args.dollarSymbol,
            _args.dollarDecimals
        );
        // staking
        LibStaking.StakingData storage ls = LibStaking.stakingStorage();
        ls.stakingDiscountMultiplier = uint256(1000000 gwei); // 0.001
        ls.blockCountInAWeek = 45361;
        // add staking shares

        string
            memory uri = "https://bafybeifibz4fhk4yag5reupmgh5cdbm2oladke4zfd7ldyw7avgipocpmy.ipfs.infura-ipfs.io/";
        appStore.stakingShareAddress = address(
            new StakingShare(address(this), uri)
        );
        // adding governance token
        appStore.governanceTokenAddress = address(
            new UbiquityGovernanceTokenForDiamond(address(this))
        );

        // ubiquity chef before doing that we should have a metapool address

        LibUbiquityChef.initialize(
            _args.tos,
            _args.amounts,
            _args.stakingShareIDs,
            _args.governancePerBlock
        );

        // add your own state variables
        // EIP-2535 specifies that the `diamondCut` function takes two optional
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface
    }
}
