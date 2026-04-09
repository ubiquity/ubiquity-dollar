// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
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
    // Diamond address - set via env variable DIAMOND_ADDRESS
    address diamond;
    address deployer;

    function run() external {
        diamond = vm.envAddress("DIAMOND_ADDRESS");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy the new facet
        StabilityPoolFacet stabilityPoolFacet = new StabilityPoolFacet();
        console.log("StabilityPoolFacet deployed at:", address(stabilityPoolFacet));

        // 2. Prepare selectors
        bytes4[] memory selectors = new bytes4[](17);
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
        selectors[12] = StabilityPoolFacet.withdrawAllFromStabilityPool.selector;
        selectors[13] = StabilityPoolFacet.claimStabilityPoolRewards.selector;
        selectors[14] = StabilityPoolFacet.depositAndClaim.selector;
        selectors[15] = StabilityPoolFacet.setStabilityPoolAddresses.selector;
        selectors[16] = StabilityPoolFacet.toggleAutoDeposit.selector;

        // 3. Prepare diamond cut
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(stabilityPoolFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        // 4. Execute the diamond cut
        IDiamondCut(diamond).diamondCut(cuts, address(0), "");

        console.log("StabilityPoolFacet added to diamond at:", diamond);

        vm.stopBroadcast();
    }
}
