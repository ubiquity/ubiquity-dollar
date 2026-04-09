// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {IDiamondCut} from "../../src/dollar/interfaces/IDiamondCut.sol";
import {StabilityPoolFacet} from "../../src/dollar/facets/StabilityPoolFacet.sol";

/// @title DeployStabilityPool
/// @notice Deploys the StabilityPoolFacet and adds it to the existing diamond
/// @dev Usage:
///   forge script scripts/task/DeployStabilityPool.s.sol:DeployStabilityPool \
///     --rpc-url $RPC_URL \
///     --broadcast \
///     --verify
contract DeployStabilityPool is Script {
    // Diamond address - set via env variable
    address constant DIAMOND = address(0); // Replace with actual diamond address

    // Liquity mainnet addresses
    address constant LIQUITY_STABILITY_POOL = 0x66017D22b0f8556afDd19FC67041899EB65a21bb;
    address constant LUSD_TOKEN = 0x5f98805A4E8be7aE3B79k84F1E22bF01d2E3c1E0;
    address constant LQTY_TOKEN = 0x6DEA81C8171D0bA574754EF6F8b412F0Ed80faFD;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy the new facet
        StabilityPoolFacet stabilityPoolFacet = new StabilityPoolFacet();
        console.log("StabilityPoolFacet deployed at:", address(stabilityPoolFacet));

        // 2. Prepare the diamond cut
        bytes4[] memory selectors = new bytes4[](13);
        selectors[0] = StabilityPoolFacet.stabilityPoolAddress.selector;
        selectors[1] = StabilityPoolFacet.lusdTokenAddress.selector;
        selectors[2] = StabilityPoolFacet.lqtyTokenAddress.selector;
        selectors[3] = StabilityPoolFacet.isAutoDepositEnabled.selector;
        selectors[4] = StabilityPoolFacet.totalDeposited.selector;
        selectors[5] = StabilityPoolFacet.accumulatedEthGains.selector;
        selectors[6] = StabilityPoolFacet.accumulatedLqtyRewards.selector;
        selectors[7] = StabilityPoolFacet.compoundedLusdDeposit.selector;
        selectors[8] = StabilityPoolFacet.pendingEthGain.selector;
        selectors[9] = StabilityPoolFacet.pendingLqtyGain.selector;
        selectors[10] = StabilityPoolFacet.depositToStabilityPool.selector;
        selectors[11] = StabilityPoolFacet.withdrawFromStabilityPool.selector;
        selectors[12] = StabilityPoolFacet.claimStabilityPoolRewards.selector;

        // Additional selectors
        bytes4[] memory selectorsExt = new bytes4[](5);
        selectorsExt[0] = StabilityPoolFacet.withdrawAllFromStabilityPool.selector;
        selectorsExt[1] = StabilityPoolFacet.depositAndClaim.selector;
        selectorsExt[2] = StabilityPoolFacet.setStabilityPoolAddresses.selector;
        selectorsExt[3] = StabilityPoolFacet.toggleAutoDeposit.selector;

        // Merge selectors
        bytes4[] memory allSelectors = new bytes4[](selectors.length + selectorsExt.length - 1);
        for (uint256 i = 0; i < selectors.length; i++) {
            allSelectors[i] = selectors[i];
        }
        for (uint256 i = 0; i < selectorsExt.length - 1; i++) {
            allSelectors[selectors.length + i] = selectorsExt[i];
        }

        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(stabilityPoolFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: allSelectors
        });

        // 3. Execute the diamond cut
        IDiamondCut(DIAMOND).diamondCut(cuts, address(0), "");

        console.log("StabilityPoolFacet added to diamond");

        vm.stopBroadcast();
    }
}
