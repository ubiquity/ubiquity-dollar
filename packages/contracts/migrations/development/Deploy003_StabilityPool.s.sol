// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {DiamondCutFacet} from "../../src/dollar/facets/DiamondCutFacet.sol";
import {StabilityPoolFacet} from "../../src/dollar/facets/StabilityPoolFacet.sol";
import {MockERC20} from "../../src/dollar/mocks/MockERC20.sol";
import {MockLiquityStabilityPool} from "../../src/dollar/mocks/MockLiquityStabilityPool.sol";
import {DiamondTestHelper} from "../../test/helpers/DiamondTestHelper.sol";

/**
 * @notice Development migration contract
 * @dev Deploys `StabilityPoolFacet` with mock Liquity contracts for local testing
 */
contract Deploy003_StabilityPool is Script, DiamondTestHelper {
    // env variables
    uint256 adminPrivateKey;
    uint256 ownerPrivateKey;
    address diamond;

    // derived addresses
    address adminAddress;
    address ownerAddress;

    function run() public {
        // read env variables
        diamond = vm.envAddress("DIAMOND_ADDRESS");
        adminPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");
        ownerPrivateKey = vm.envUint("OWNER_PRIVATE_KEY");

        adminAddress = vm.addr(adminPrivateKey);
        ownerAddress = vm.addr(ownerPrivateKey);

        //================================================================
        // Deploy mock tokens and Stability Pool
        //================================================================

        vm.startBroadcast(ownerPrivateKey);

        MockERC20 lusdToken = new MockERC20("LUSD", "LUSD", 18);
        MockERC20 lqtyToken = new MockERC20("LQTY", "LQTY", 18);
        MockLiquityStabilityPool mockStabilityPool = new MockLiquityStabilityPool(
            address(lusdToken),
            address(lqtyToken)
        );

        vm.stopBroadcast();

        //================================================================
        // Deploy `StabilityPoolFacet` and add it to the diamond
        //================================================================

        vm.startBroadcast(ownerPrivateKey);

        bytes4[] memory selectorsOfStabilityPoolFacet = getSelectorsFromAbi(
            "/out/StabilityPoolFacet.sol/StabilityPoolFacet.json"
        );

        StabilityPoolFacet stabilityPoolFacetImplementation = new StabilityPoolFacet();

        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut({
            facetAddress: address(stabilityPoolFacetImplementation),
            action: FacetCutAction.Add,
            functionSelectors: selectorsOfStabilityPoolFacet
        });

        DiamondCutFacet diamondCutFacet = DiamondCutFacet(diamond);
        diamondCutFacet.diamondCut(cuts, address(0), "");

        vm.stopBroadcast();

        //================================================================
        // Configure the Stability Pool integration
        //================================================================

        vm.startBroadcast(adminPrivateKey);

        StabilityPoolFacet stabilityPoolFacet = StabilityPoolFacet(
            payable(diamond)
        );

        stabilityPoolFacet.setStabilityPoolAddress(
            address(mockStabilityPool)
        );
        stabilityPoolFacet.setLusdTokenAddress(address(lusdToken));
        stabilityPoolFacet.setLqtyTokenAddress(address(lqtyToken));
        stabilityPoolFacet.setProtocolTreasury(adminAddress);

        vm.stopBroadcast();
    }
}
