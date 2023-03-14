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
        uint256 amount
    );

    uint32 connectorWeight;
    uint256 baseY;
    uint256 constant ACCURACY = 10e18;


    mapping (address => uint256) public share;

    function setUp() public virtual override {
        super.setUp();
    }
}

contract RemoteZeroStateTest is ZeroState {

    function testCannotDeployEmptyUbiquistickAddr() public {
        vm.expectRevert("NFT address empty");
        BondingCurve broken = new BondingCurve(
            address(manager),
            address(0)
        );
    }

    function testCannotDeployConnectorWeightZero() public {
        vm.expectRevert();
        BondingCurve broken = new BondingCurve(
            address(manager),
            address(0)
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
        vm.expectEmit(true, false, false, true);
        emit Deposit(secondAccount, collateralDeposited);

        vm.startPrank(admin);
        bondingCurve.setParams(
            _connectorWeight,
            _baseY
        ); 

        bondingCurve.setCollateralToken(
            address(dollarToken)
        );

        vm.stopPrank();

        uint256 tokenIds = 0;
        uint256 poolBalance = bondingCurve.poolBalance();

        bondingCurve.deposit(
            collateralDeposited, 
            secondAccount
        );

        // assertEq(bondingCurve.share[secondAccount], )
        assertEq(bondingCurve.poolBalance(), collateralDeposited);
        assertEq(dollarToken.balanceOf(secondAccount), collateralDeposited);
    }

    function testWithdraw() public {
        vm.expectEmit(true, false, false, true);
        emit Withdraw(collateralDeposited);

        vm.startPrank(admin);
        bondingCurve.setParams(
            _connectorWeight,
            _baseY
        ); 

        bondingCurve.setCollateralToken(
            address(dollarToken)
        );

        bondingCurve.setTreasuryAddress(
            address(thirdAccount)
        );

        vm.stopPrank();

        uint256 tokenIds = 0;
        uint256 poolBalance = bondingCurve.poolBalance();

        bondingCurve.deposit(
            collateralDeposited, 
            secondAccount
        );

        vm.prank(admin);
        bondingCurve.withdraw(
            collateralDeposited
        );

        assertEq(bondingCurve.poolBalance(), 0);
        assertEq(dollarToken.balanceOf(thirdAccount), collateralDeposited);
    }
}