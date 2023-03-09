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
    uint256 constant ACCURACY = 10e18;

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
            address(governanceToken)
        );
    }

    function testCannotDeployConnectorWeightZero() public {
        vm.expectRevert();
        BondingCurve broken = new BondingCurve(
            address(manager),
            address(0),
            address(governanceToken)
        );
    }


    uint256 connWeight = bound(uint256(connectorWeight), 1, 1000000);
    uint32 _connectorWeight = uint32(connWeight);
    uint256 _baseY = bound(baseY, 1, 1000000);

    function testSetParams() public {

        vm.prank(admin);
        bondingCurve.setParams(
            _connectorWeight,
            _baseY
        );

        assertEq(bondingCurve.connectorWeight(), _connectorWeight);
        assertEq(bondingCurve.baseY(), _baseY);
    }

    uint256 collateralDeposited;

    function testDeposit() public {
        // vm.expectEmit(true, false, false, true);
        // emit Deposit(secondAccount, collateralDeposited);
        vm.startPrank(admin);
        bondingCurve.setParams(
            _connectorWeight,
            _baseY
        ); 

        uint256 poolBalance = bondingCurve.poolBalance();

        bondingCurve.deposit(
            collateralDeposited, 
            secondAccount
        );

        assertEq(bondingCurve.poolBalance(), collateralDeposited);
        vm.stopPrank();
    }
}