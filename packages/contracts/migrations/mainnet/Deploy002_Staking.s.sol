// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Script} from "forge-std/Script.sol";
import {DiamondCutFacet} from "../../src/dollar/facets/DiamondCutFacet.sol";
import {StakingFacet} from "../../src/dollar/facets/StakingFacet.sol";
import {DiamondTestHelper} from "../../test/helpers/DiamondTestHelper.sol";

/**
 * @notice Migration contract
 * @dev Deploys `StakingFacet`
 * NOTICE: in order to QA this migration locally use this shell script:
 * ```
 * #!/bin/bash
 *
 * # load env variables
 * source .env
 *
 * UBQ_ETH_ADDRESS=0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd;
 *
 * # pretend we're `ubq.eth` address
 * cast rpc anvil_impersonateAccount $UBQ_ETH_ADDRESS;
 *
 * # Deploy002_Staking (deploys `StakingFacet`)
 * forge script migrations/mainnet/Deploy002_Staking.s.sol:Deploy002_Staking --rpc-url $RPC_URL --broadcast -vvvv --unlocked
 * 
 * # stop pretending we're `ubq.eth` address
 * cast rpc anvil_stopImpersonatingAccount $UBQ_ETH_ADDRESS;
 * ```
 */
contract Deploy002_Staking is Script, DiamondTestHelper {
    // env variables
    uint256 ownerPrivateKey;

    // owner address derived from private key stored in `.env` file
    address ownerAddress;

    address diamond = 0xED3084c98148e2528DaDCB53C56352e549C488fA;
    address ubiquityDeployerAddress = 0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd;
    address ubqToken = 0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0;
    address lusdUusdLpToken = 0xcC68509F9cA0E1ed119EAC7c468EC1b1C42f384F;

    function run() public {
        // read env variables
        ownerPrivateKey = vm.envUint("OWNER_PRIVATE_KEY");
        ownerAddress = vm.addr(ownerPrivateKey);

        // Start sending owner transactions
        // If owner is `ubq.eth` then send real transactions, otherwise simulate calls from `ubq.eth`
        if (ownerAddress == ubiquityDeployerAddress) {
            vm.startBroadcast(ownerPrivateKey);
        } else {
            vm.startBroadcast(ubiquityDeployerAddress);
        }

        //===================================================
        // Deploy `StakingFacet` and add it to the diamond
        //===================================================

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

        //====================
        // Add staking pool
        //====================

        // NOTICE: adding a new staking pool requires `admin` role (not `owner`) but since `admin`
        // and `owner` are the same addresses (`ubq.eth`) then it's safe to use the `owner` role
        StakingFacet stakingFacet = StakingFacet(diamond);
        stakingFacet.setGovernancePerBlock(1 ether); // 1 reward token minted per block
        stakingFacet.setGovernanceTreasuryDivider(5); // `100 / 5 = 20%` extra reward tokens minted for treasury
        stakingFacet.setStakingRewardToken(ubqToken); // reward token address
        stakingFacet.setStakingStartBlock(block.number); // activate staking from current block
        stakingFacet.createStakingPool( // add a new staking pool
            100, // allocation points
            IERC20(lusdUusdLpToken), // staking token
            true // whether to update all pools
        );

        // Stop sending owner transactions
        vm.stopBroadcast();
    }
}
