// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {DiamondCutFacet} from "../../src/dollar/facets/DiamondCutFacet.sol";
import {StabilityPoolFacet} from "../../src/dollar/facets/StabilityPoolFacet.sol";
import {DiamondTestHelper} from "../../test/helpers/DiamondTestHelper.sol";

/**
 * @notice Migration contract
 * @dev Deploys `StabilityPoolFacet` and adds it to the diamond.
 *      Configures Liquity V1 Stability Pool integration for LUSD yield generation.
 *
 *      Mainnet addresses:
 *      - Liquity Stability Pool: 0x66017D22b0f8556afDd19e1e5b5f1cbD89a6C337
 *      - LUSD Token:             0x5f98805A4E8be255a32880FDeC7F6728C6568bA0
 *      - LQTY Token:             0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D
 */
contract Deploy003_StabilityPool is Script, DiamondTestHelper {
    // Liquity V1 mainnet addresses
    address constant LIQUITY_STABILITY_POOL =
        0x66017D22b0f8556afDd19e1e5b5f1cbD89a6C337;
    address constant LUSD_TOKEN =
        0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;
    address constant LQTY_TOKEN =
        0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D;

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
        // Deploy `StabilityPoolFacet` and add it to the diamond
        //================================================================

        // start sending owner transactions
        vm.startBroadcast(ownerPrivateKey);

        // prepare facet selectors
        bytes4[] memory selectorsOfStabilityPoolFacet = getSelectorsFromAbi(
            "/out/StabilityPoolFacet.sol/StabilityPoolFacet.json"
        );

        // deploy implementation
        StabilityPoolFacet stabilityPoolFacetImplementation = new StabilityPoolFacet();

        // prepare diamond cut
        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut({
            facetAddress: address(stabilityPoolFacetImplementation),
            action: FacetCutAction.Add,
            functionSelectors: selectorsOfStabilityPoolFacet
        });

        // add facet to diamond
        DiamondCutFacet diamondCutFacet = DiamondCutFacet(diamond);
        diamondCutFacet.diamondCut(cuts, address(0), "");

        // stop sending owner transactions
        vm.stopBroadcast();

        //================================================================
        // Configure the Stability Pool integration
        //================================================================

        // start sending admin transactions
        vm.startBroadcast(adminPrivateKey);

        StabilityPoolFacet stabilityPoolFacet = StabilityPoolFacet(
            payable(diamond)
        );

        // set Liquity Stability Pool address
        stabilityPoolFacet.setStabilityPoolAddress(LIQUITY_STABILITY_POOL);

        // set token addresses
        stabilityPoolFacet.setLusdTokenAddress(LUSD_TOKEN);
        stabilityPoolFacet.setLqtyTokenAddress(LQTY_TOKEN);

        // set protocol treasury (read from env or use a default)
        address protocolTreasury = vm.envAddress("PROTOCOL_TREASURY");
        stabilityPoolFacet.setProtocolTreasury(protocolTreasury);

        // stop sending admin transactions
        vm.stopBroadcast();
    }
}
