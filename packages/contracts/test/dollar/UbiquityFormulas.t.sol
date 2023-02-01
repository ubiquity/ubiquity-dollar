// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Test.sol";

import "../../src/dollar/UbiquityFormulas.sol";

contract UbiquityFormulasTest is Test {
    UbiquityFormulas ubiquityFormulas;

    function setUp() public {
        ubiquityFormulas = new UbiquityFormulas();
    }

    function testDurationMultiply_ShouldReturnAmount() public {
        uint amount = ubiquityFormulas.durationMultiply(
            100 ether,
            1,
            1000000 gwei
        );
        assertEq(amount, 100100000000000000000);
    }

    function testStaking_ShouldReturnAmount() public {
        uint amount = ubiquityFormulas.staking(100 ether, 2 ether, 3 ether);
        assertEq(amount, 150000000000000000000);
    }

    function testRedeemShares_ShouldReturnAmount() public {
        uint amount = ubiquityFormulas.redeemShares(
            100 ether,
            2 ether,
            3 ether
        );
        assertEq(amount, 66666666666666666666);
    }

    function testSharePrice_ShouldReturnAmount() public {
        uint amount = ubiquityFormulas.sharePrice(
            100 ether,
            100 ether,
            1 ether
        );
        assertEq(amount, 1000000000000000000);
    }

    function testGovernanceMultiply_ShouldReturnAmount() public {
        uint amount = ubiquityFormulas.governanceMultiply(1e18, 1 ether);
        assertEq(amount, 1050000000000000000);
    }

    function testGovernanceMultiply_ShouldReturnAmount_IfNewMultiplierIsTooBig()
        public
    {
        uint amount = ubiquityFormulas.governanceMultiply(100e18, 1 ether);
        assertEq(amount, 100000000000000000000);
    }

    function testGovernanceMultiply_ShouldReturnAmount_IfNewMultiplierIsTooSmall()
        public
    {
        uint amount = ubiquityFormulas.governanceMultiply(1e6, 1 ether);
        assertEq(amount, 1000000);
    }
}
