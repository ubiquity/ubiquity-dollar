// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/console.sol";
import {DiamondTestSetup} from "../DiamondTestSetup.sol";
import {MockERC20} from "../../../src/dollar/mocks/MockERC20.sol";

contract FuseRariAmoStrategyTest is DiamondTestSetup {
    function setUp() public override {
        MockERC20 collateralToken;

        super.setUp();
        vm.startPrank(admin);
        // init collateral token
        collateralToken = new MockERC20("COLLATERAL", "CLT", 18);
        vm.stopPrank();
    }

    function testAllPoolAddresses_ShouldReturnEmptyArray() public {
        address[] memory poolAddresses = fuseRariAmoStrategyFacet
            .allPoolAddresses();
        assertEq(poolAddresses.length, 0);
    }

    function testAllPoolAddresses_ShouldReturnCorrectArray() public {
        address newPool = address(0x401);
        fuseRariAmoStrategyFacet.addFusePool(newPool);

        assertTrue(fuseRariAmoStrategyFacet.allPoolAddresses().length > 0);
    }

    function testAllPoolsLength_ShouldReturnZero() public {
        assertEq(fuseRariAmoStrategyFacet.allPoolsLength(), 0);
    }

    function testAllPoolsLength_ShouldReturnCorrectLength() public {
        address alphaPool = address(0x401);
        address betaPool = address(0x402);
        address gammaPool = address(0x403);

        fuseRariAmoStrategyFacet.addFusePool(alphaPool);
        fuseRariAmoStrategyFacet.addFusePool(betaPool);
        fuseRariAmoStrategyFacet.addFusePool(gammaPool);

        assertEq(fuseRariAmoStrategyFacet.allPoolsLength(), 3);
    }

    function poolAddrToId_ShouldRevertIfPoolDoesNotExist() public {
        fuseRariAmoStrategyFacet.poolAddrToId(address(0x401));

        vm.expectRevert("Pool not found");
    }

    function testPoolAddrToId_ShouldReturnCorrectId() public {
        address alphaPool = address(0x401);
        address betaPool = address(0x402);
        address gammaPool = address(0x403);

        fuseRariAmoStrategyFacet.addFusePool(alphaPool);
        fuseRariAmoStrategyFacet.addFusePool(betaPool);
        fuseRariAmoStrategyFacet.addFusePool(gammaPool);

        assertEq(fuseRariAmoStrategyFacet.poolAddrToId(alphaPool), 0);
        assertEq(fuseRariAmoStrategyFacet.poolAddrToId(betaPool), 1);
        assertEq(fuseRariAmoStrategyFacet.poolAddrToId(gammaPool), 2);
    }
}
