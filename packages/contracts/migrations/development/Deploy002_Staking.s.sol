// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Script} from "forge-std/Script.sol";
import "forge-std/console2.sol";
import {UbiquityAlgorithmicDollarManager} from "../../src/deprecated/UbiquityAlgorithmicDollarManager.sol";
import {UbiquityGovernance} from "../../src/deprecated/UbiquityGovernance.sol";
import {DiamondCutFacet} from "../../src/dollar/facets/DiamondCutFacet.sol";
import {StakingFacet} from "../../src/dollar/facets/StakingFacet.sol";
import {MockERC20} from "../../src/dollar/mocks/MockERC20.sol";
import {DiamondTestHelper} from "../../test/helpers/DiamondTestHelper.sol";

/**
 * @notice Migration contract
 * @dev Deploys `StakingFacet`
 */
contract Deploy002_Staking is Script, DiamondTestHelper {
    UbiquityAlgorithmicDollarManager dollarManager;
    UbiquityGovernance rewardToken;
    MockERC20 stakeToken;

    // env variables
    uint256 adminPrivateKey;
    uint256 ownerPrivateKey;
    address diamond;

    // owner and admin addresses derived from private keys store in `.env` file
    address adminAddress;
    address ownerAddress;

    function run() public {
        // read env variables
        diamond = vm.envAddress("DIAMOND_ADDRESS"); // env variable set in `deploy.sh`
        adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        ownerPrivateKey = vm.envUint("OWNER_PRIVATE_KEY");

        adminAddress = vm.addr(adminPrivateKey);
        ownerAddress = vm.addr(ownerPrivateKey);

        //====================================
        // Deploy reward and staking tokens
        //====================================

        // start sending owner transactions
        vm.startBroadcast(ownerPrivateKey);

        dollarManager = new UbiquityAlgorithmicDollarManager(ownerAddress);
        rewardToken = new UbiquityGovernance(address(dollarManager));
        stakeToken = new MockERC20("STK", "STK", 18);

        // owner grants diamond the "UBQ_MINTER_ROLE" 
        // NOTICE: in production environment the diamond contract already has the "UBQ_MINTER_ROLE" role
        dollarManager.grantRole(keccak256("UBQ_MINTER_ROLE"), address(diamond));

        // stop sending owner transactions
        vm.stopBroadcast();

        //===================================================
        // Deploy `StakingFacet` and add it to the diamond
        //===================================================

        // start sending owner transactions
        vm.startBroadcast(ownerPrivateKey);

        // prepare staking facet selectors
        bytes4[] memory selectorsOfStakingFacet = getSelectorsFromAbi("/out/StakingFacet.sol/StakingFacet.json");

        // deploy `StakingFacet` implementation
        StakingFacet stakingFacetImplementation = new StakingFacet();

        // prepare staking diamond cut 
        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = (
            FacetCut({
                facetAddress: address(stakingFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfStakingFacet
            })
        );

        // add `StakingFacet` to the diamond
        DiamondCutFacet diamondCutFacet = DiamondCutFacet(diamond);
        diamondCutFacet.diamondCut(cuts, address(0), "");

        // stop sending owner transactions
        vm.stopBroadcast();

        //====================
        // Add staking pool
        //====================

        // start sending admin transactions
        vm.startBroadcast(adminPrivateKey);

        StakingFacet stakingFacet = StakingFacet(diamond);
        stakingFacet.setGovernancePerBlock(1 ether); // 1 reward token minted per block
        stakingFacet.setGovernanceTreasuryDivider(5); // `100 / 5 = 20%` extra reward tokens minted for treasury
        stakingFacet.setStakingRewardToken(address(rewardToken)); // reward token address
        stakingFacet.setStakingStartBlock(block.number); // activate staking from current block
        stakingFacet.createStakingPool( // add a new staking pool
            100, // allocation points
            IERC20(stakeToken), // staking token
            true // whether to update all pools
        );

        // stop sending admin transactions
        vm.stopBroadcast();
    }
}
