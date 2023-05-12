// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DiamondInit} from "../../src/dollar/upgradeInitializers/DiamondInit.sol";
import "forge-std/Test.sol";

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
            creditNFTLengthBlocks: 100
        });
        dInit.init(initArgs);
    }
}
