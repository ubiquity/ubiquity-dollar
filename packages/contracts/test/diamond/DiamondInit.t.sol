// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {DiamondInit} from "../../src/dollar/upgradeInitializers/DiamondInit.sol";
import {LibAppStorage} from "../../src/dollar/libraries/LibAppStorage.sol";
import "forge-std/Test.sol";

contract MockDiamondInit is DiamondInit {
    function toCheckNonReentrant() external nonReentrant {
        require(store.reentrancyStatus == 2, "reentrancyStatus: _NOT_ENTERED");

        DiamondInitTest(msg.sender).ping();
    }
}

contract DiamondInitTest is Test {
    DiamondInit dInit;

    function setUp() public {
        dInit = new DiamondInit();
    }

    function test_Init() public {
        DiamondInit.Args memory initArgs = DiamondInit.Args({
            admin: address(0x123),
            tos: new address[](0),
            amounts: new uint256[](0),
            stakingShareIDs: new uint256[](0),
            governancePerBlock: 10e18,
            creditNftLengthBlocks: 100
        });
        dInit.init(initArgs);

        uint256 reentrancyStatus = uint256(vm.load(address(dInit), 0));
        assertEq(reentrancyStatus, 1);
    }

    function test_NonReentrant() public {
        MockDiamondInit mockDInit = new MockDiamondInit();

        vm.expectRevert("ReentrancyGuard: reentrant call");
        mockDInit.toCheckNonReentrant();
    }

    function ping() external {
        MockDiamondInit(msg.sender).toCheckNonReentrant();
    }
}
