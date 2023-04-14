// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../DiamondTestSetup.sol";
import "../../../src/dollar/libraries/Constants.sol";
import {MockERC20} from "../../../src/dollar/mocks/MockERC20.sol";
import {MockCreditNft} from "../../../src/dollar/mocks/MockCreditNft.sol";
import "forge-std/Test.sol";

contract BondingCurveFacetTest is DiamondSetup {

    address treasury = address(0x3);
    address secondAccount = address(0x4);
    address thirdAccount = address(0x5);
    address fourthAccount = address(0x6);
    address fifthAccount = address(0x7);

    uint256 constant ACCURACY = 10e18;
    uint32  constant MAX_WEIGHT = 1e6;
    bytes32 constant ONE = keccak256(abi.encodePacked(uint256(1)));

    mapping (address => uint256) public share;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(uint256 amount);
    event ParamsSet(uint32 connectorWeight, uint256 baseY);

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(admin);
        IAccessCtrl.grantRole(GOVERNANCE_TOKEN_MINTER_ROLE, address(diamond));

        vm.stopPrank();
    }
}

contract ZeroStateBonding is BondingCurveFacetTest {
    using stdStorage for StdStorage;

    function testSetParams(uint32 connectorWeight, uint256 baseY) public {
        uint connWeight;
        connectorWeight = uint32(bound(connWeight, 1, 1000000));
        baseY = bound(baseY, 1, 1000000);
        
        vm.expectEmit(true, false, false, true);
        emit ParamsSet(connectorWeight, baseY);

        vm.prank(admin);
        IBondingCurveFacet.setParams(
            connectorWeight,
            baseY
        );

        assertEq(connectorWeight, IBondingCurveFacet.connectorWeight());
        assertEq(baseY, IBondingCurveFacet.baseY());
    }

    function testSetParamsShouldRevertNotAdmin() public {
        uint32 connWeight;
        uint256 base;
        uint32 connectorWeight = uint32(bound(connWeight, 1, 1000000));
        uint256 baseY = bound(base, 1, 1000000);
        
        vm.expectRevert("Manager: Caller is not admin");
        vm.prank(secondAccount);
        IBondingCurveFacet.setParams(
            connectorWeight,
            baseY
        ); 
    }

    function testDeposit(uint32 connectorWeight, uint256 baseY) public {
        uint256 collateralDeposited;
        uint connWeight;
        connectorWeight = uint32(bound(connWeight, 1, 1000000));
        baseY = bound(baseY, 1, 1000000);
        uint256 tokenIds;

        vm.expectEmit(true, false, false, true);
        emit Deposit(secondAccount, collateralDeposited);

        vm.prank(admin);
        IBondingCurveFacet.setParams(
            connectorWeight,
            baseY
        ); 

        uint256 initBal = IDollar.balanceOf(secondAccount);

        IBondingCurveFacet.deposit(
            collateralDeposited, 
            secondAccount
        );

        uint256 finBal = IDollar.balanceOf(secondAccount);

        uint256 tokReturned = IBondingCurveFacet.purchaseTargetAmountFromZero(
            collateralDeposited,
            connectorWeight,
            ACCURACY,
            baseY
        );

        assertEq(collateralDeposited, IBondingCurveFacet.poolBalance());
        assertEq(collateralDeposited, finBal - initBal);
        assertEq(tokReturned, IBondingCurveFacet.getShare(secondAccount));
        assertEq(tokReturned, IUbiquityNFT.balanceOf(secondAccount, 1));

        uint256 newDeposit;
    }

    function testWithdraw(uint32 connectorWeight, uint256 baseY) public {

        uint256 collateralDeposited;
        uint connWeight;
        connectorWeight = uint32(bound(connWeight, 1, 1000000));
        baseY = bound(baseY, 1, 1000000);


        vm.startPrank(admin);
        IBondingCurveFacet.setParams(
            connectorWeight,
            baseY
        ); 

        IBondingCurveFacet.deposit(
            collateralDeposited, 
            secondAccount
        );

        uint256 _amount = bound(baseY, 0, collateralDeposited);

        vm.expectEmit(true, false, false, true);
        emit Withdraw(collateralDeposited);

        IBondingCurveFacet.withdraw(
            _amount
        );
        vm.stopPrank();

        uint256 poolBalance = IBondingCurveFacet.poolBalance();
        uint256 balance = poolBalance - _amount;

        assertEq(IBondingCurveFacet.poolBalance(), balance);
        assertEq(IDollar.balanceOf(IManager.treasuryAddress()), _amount);
    }

    function testPurchaseTargetAmountShouldRevertIfSupplyZero() public {
        uint256 collateralDeposited;
        uint connWeight;
        uint256 poolBalance;
        uint32 connectorWeight = uint32(bound(connWeight, 1, MAX_WEIGHT));

        vm.expectRevert("ERR_INVALID_SUPPLY");
        IBondingCurveFacet.purchaseTargetAmount(
            collateralDeposited,
            connectorWeight,
            1,
            0 
        );
    }

    function testPurchaseTargetAmountShouldRevertIfParamsNotSet() public {
        uint256 collateralDeposited;
        uint256 bal;
        uint256 poolBalance = bound(bal, 1, 1000000);
        uint connWeight;
        uint32 connectorWeight = uint32(bound(connWeight, 1, MAX_WEIGHT));

        vm.expectRevert("ERR_INVALID_WEIGHT");
        IBondingCurveFacet.purchaseTargetAmount(
            collateralDeposited,
            0,
            1,
            poolBalance 
        );
    }

    function testPurchaseTargetAmount() public {
        // Calculate expected result
        uint256 tokensDeposited;
        uint connWeight;
        uint256 tokenIds;
        uint32 connectorWeight = uint32(bound(connWeight, 1, MAX_WEIGHT));
        uint256 bal;
        uint256 poolBalance = bound(bal, 1, 1000000);

        uint256 expected = (tokenIds * tokensDeposited) / poolBalance;

        // 1. Should do nothing if tokens deposited is zero
        vm.prank(secondAccount);
        IBondingCurveFacet.purchaseTargetAmount(
            0,
            connectorWeight,
            1,
            poolBalance 
        );

        // 2. Special case if max weight is 100%
        vm.prank(thirdAccount); 
        uint256 result = IBondingCurveFacet.purchaseTargetAmount(
            tokensDeposited,
            MAX_WEIGHT,
            tokenIds,
            poolBalance 
        );
        assertEq(result, expected);
    }
}
