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
    uint256 public constant BONDING_TOKEN_ID = 1;
    address public treasuryAddress;

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

    function testSetTreasuryAddress() public {
        vm.prank(admin);
        bondingCurve.setTreasuryAddress();

        assertEq(manager.treasuryAddress(), bondingCurve.treasuryAddress());
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

        bondingCurve.deposit(
            collateralDeposited, 
            secondAccount
        );

        assertEq(bondingCurve.share(secondAccount), ubiquiStick.balanceOf(secondAccount, BONDING_TOKEN_ID));
        assertEq(bondingCurve.poolBalance(), collateralDeposited);
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

        manager.setTreasuryAddress(address(thirdAccount));
        bondingCurve.setTreasuryAddress();

        vm.stopPrank();

        bondingCurve.deposit(
            collateralDeposited, 
            secondAccount
        );
        uint256 poolBalance = bondingCurve.poolBalance();

        uint256 _amount = bound(baseY, 0, collateralDeposited);

        vm.prank(admin);
        bondingCurve.withdraw(
            _amount
        );
        uint256 balance = poolBalance - _amount;

        assertEq(bondingCurve.poolBalance(), balance);
        assertEq(dollarToken.balanceOf(treasuryAddress), _amount);
    }
}