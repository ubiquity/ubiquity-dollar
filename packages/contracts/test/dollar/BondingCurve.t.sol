// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../helpers/LiveTestHelper.sol";

contract ZeroState is LiveTestHelper {

    event Deposit(
        address indexed user, 
        uint256 amount
    );

    event Withdraw(
        address indexed recipient, 
        uint256 amount
    );

    address[] ogs;
    address[] ogsEmpty;
    uint256[] balances;
    uint256[] lockup;

    uint32 connectorWeight;
    uint256 baseY;

    function setUp() public virtual override {
        super.setUp();
    }
}

contract ZeroStateTest is ZeroState {

    function testCannotDeployEmptyUbiquistickAddr() public {
        vm.expectRevert("NFT address empty");
        BondingCurve broken = new BondingCurve(
            address(manager),
            address(0),
            address(governanceToken),
            1,
            1000
        );
    }

    function testCannotDeployConnectorWeightZero() public {
        vm.expectRevert();
        BondingCurve broken = new BondingCurve(
            address(manager),
            address(0),
            address(governanceToken),
            0,
            1000
        );
    }
    // function testCannotDeployEmptyUbiquistickAddr() public {
    //     vm.expectRevert("NFT address empty");
    //     BondingCurve broken = new BondingCurve(
    //         address(manager),
    //         address(0),
    //         address(governanceToken),
    //         1,
    //         1000
    //     );
    // }

    uint256 collateralDeposited;

    function testDeposit() public {
        // vm.expectEmit(true, false, false, true);
        // emit Deposit(secondAccount, collateralDeposited);

        vm.prank(admin);
        bondingCurve.deposit(
            collateralDeposited, 
            secondAccount
        );

        assertEq(bondingCurve.poolBalance(), collateralDeposited);
    }
}