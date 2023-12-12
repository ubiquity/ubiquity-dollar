// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/console.sol";
import {DiamondTestSetup} from "../DiamondTestSetup.sol";
import {MockERC20} from "../../../src/dollar/mocks/MockERC20.sol";

contract DollarAmoMinterFacetTest is DiamondTestSetup {
    function setUp() public override {
        MockERC20 collateralToken;

        super.setUp();

        vm.startPrank(admin);
        // init collateral token
        collateralToken = new MockERC20("COLLATERAL", "CLT", 18);

        vm.stopPrank();
    }

    function testCollateralDollarBalance_ShouldReturnDollarBalance() public {
        uint256 collatBalance = dollarAmoMinterFacet.collateralDollarBalance();
        assertEq(collatBalance, 0);
    }

    function testCollateralIndex_ShouldReturnCollateralIndex() public {
        uint index = dollarAmoMinterFacet.collateralIndex();
        assertEq(index, 0);
    }

    function testDollarBalances_ShouldReturnDollarBalances() public {
        (uint256 dollar_val, uint256 col_bal) = dollarAmoMinterFacet
            .dollarBalances();
        assertEq(dollar_val, 0);
        assertEq(col_bal, 0);
    }

    function testAllAmoAddresses_ShouldReturnAllAmoAddresses() public {
        address[] memory amos = dollarAmoMinterFacet.allAmoAddresses();
        assertEq(amos.length, 0);
    }

    function testAllAmosLength_ShouldReturnAllAmosLength() public {
        uint256 length = dollarAmoMinterFacet.allAmosLength();
        assertEq(length, 0);
    }
}
