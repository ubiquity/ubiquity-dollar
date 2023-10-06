// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../DiamondTestSetup.sol";
import "../../../src/dollar/libraries/Constants.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {MockERC20} from "../../../src/dollar/mocks/MockERC20.sol";
import {ERC1155Ubiquity} from "../../../src/dollar/core/ERC1155Ubiquity.sol";
import {UbiquiStick} from "../../../src/ubiquistick/UbiquiStick.sol";
import "forge-std/Test.sol";

contract BondingCurveFacetTest is DiamondTestSetup {
    address treasury = address(0x3);
    address secondAccount = address(0x4);
    address thirdAccount = address(0x5);
    address fourthAccount = address(0x6);
    address fifthAccount = address(0x7);

    uint256 constant _ACCURACY = 10e18;
    uint32 constant _MAX_WEIGHT = 1e6;
    bytes32 constant _ONE = keccak256(abi.encodePacked(uint256(1)));

    mapping(address => uint256) public share;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(uint256 amount);
    event ParamsSet(uint32 connectorWeight, uint256 baseY);

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(admin);

        accessControlFacet.grantRole(
            GOVERNANCE_TOKEN_MINTER_ROLE,
            address(diamond)
        );

        // deploy UbiquiStick
        UbiquiStick ubiquiStick = new UbiquiStick();
        ubiquiStick.setMinter(address(diamond));
        managerFacet.setUbiquistickAddress(address(ubiquiStick));

        vm.stopPrank();
    }
}

contract ZeroStateBonding is BondingCurveFacetTest {
    using SafeMath for uint256;
    using stdStorage for StdStorage;

    function testSetParams(uint32 connectorWeight, uint256 baseY) public {
        uint256 connWeight;
        connectorWeight = uint32(bound(connWeight, 1, 1000000));
        baseY = bound(baseY, 1, 1000000);

        vm.expectEmit(true, false, false, true);
        emit ParamsSet(connectorWeight, baseY);

        vm.prank(admin);
        bondingCurveFacet.setParams(connectorWeight, baseY);

        assertEq(connectorWeight, bondingCurveFacet.connectorWeight());
        assertEq(baseY, bondingCurveFacet.baseY());
    }

    function testSetParamsShouldRevertNotAdmin() public {
        uint32 connWeight;
        uint256 base;
        uint32 connectorWeight = uint32(bound(connWeight, 1, 1000000));
        uint256 baseY = bound(base, 1, 1000000);

        vm.expectRevert("Manager: Caller is not admin");
        vm.prank(secondAccount);
        bondingCurveFacet.setParams(connectorWeight, baseY);
    }

    function testDeposit(uint32 connectorWeight, uint256 baseY) public {
        uint256 collateralDeposited;
        uint256 connWeight;
        connectorWeight = uint32(bound(connWeight, 1, 1000000));
        baseY = bound(baseY, 1, 1000000);

        vm.prank(admin);
        bondingCurveFacet.setParams(connectorWeight, baseY);

        uint256 initBal = dollarToken.balanceOf(secondAccount);

        vm.expectEmit(true, false, false, true);
        emit Deposit(secondAccount, collateralDeposited);
        bondingCurveFacet.deposit(collateralDeposited, secondAccount);

        uint256 finBal = dollarToken.balanceOf(secondAccount);

        uint256 tokReturned = bondingCurveFacet.purchaseTargetAmountFromZero(
            collateralDeposited,
            connectorWeight,
            ACCURACY,
            baseY
        );

        // Logic Test
        uint256 baseN = collateralDeposited.add(baseY);
        uint256 power = (baseN.mul(10 ** 18)).div(baseY);
        uint256 result = ACCURACY
            .mul(SafeMath.sub((power ** (connectorWeight)), 10 ** 18))
            .div(10 ** 18);

        assertEq(collateralDeposited, bondingCurveFacet.poolBalance());
        assertEq(collateralDeposited, finBal - initBal);
        assertEq(tokReturned, result);
        assertEq(tokReturned, bondingCurveFacet.getShare(secondAccount));
        assertEq(tokReturned, creditNft.balanceOf(secondAccount, 1));
    }

    function testWithdraw(uint32 connectorWeight, uint256 baseY) public {
        uint256 collateralDeposited;
        uint256 connWeight;
        connectorWeight = uint32(bound(connWeight, 1, 1000000));
        baseY = bound(baseY, 1, 1000000);

        vm.startPrank(admin);
        bondingCurveFacet.setParams(connectorWeight, baseY);

        bondingCurveFacet.deposit(collateralDeposited, secondAccount);

        uint256 _amount = bound(baseY, 0, collateralDeposited);

        vm.expectEmit(true, false, false, true);
        emit Withdraw(collateralDeposited);

        bondingCurveFacet.withdraw(_amount);
        vm.stopPrank();

        uint256 poolBalance = bondingCurveFacet.poolBalance();
        uint256 balance = poolBalance - _amount;

        assertEq(bondingCurveFacet.poolBalance(), balance);
        assertEq(
            dollarToken.balanceOf(managerFacet.treasuryAddress()),
            _amount
        );
    }

    function testPurchaseTargetAmountShouldRevertIfSupplyZero() public {
        uint256 collateralDeposited;
        uint256 connWeight;
        uint32 connectorWeight = uint32(bound(connWeight, 1, MAX_WEIGHT));

        vm.expectRevert("ERR_INVALID_SUPPLY");
        bondingCurveFacet.purchaseTargetAmount(
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

        vm.expectRevert("ERR_INVALID_WEIGHT");
        bondingCurveFacet.purchaseTargetAmount(
            collateralDeposited,
            0,
            1,
            poolBalance
        );
    }

    function testPurchaseTargetAmount(uint32 connWeight, uint256 bal) public {
        // Calculate expected result
        uint256 tokensDeposited;
        uint256 tokenIds;
        uint32 connectorWeight = uint32(bound(connWeight, 1, MAX_WEIGHT));
        uint256 poolBalance = bound(bal, 1, 1000000);

        uint256 expected = (tokenIds * tokensDeposited) / poolBalance;

        // 1. Should do nothing if tokens deposited is zero
        vm.prank(secondAccount);
        bondingCurveFacet.purchaseTargetAmount(
            0,
            connectorWeight,
            1,
            poolBalance
        );

        // 2. Special case if max weight is 100%
        vm.prank(thirdAccount);
        uint256 result = bondingCurveFacet.purchaseTargetAmount(
            tokensDeposited,
            MAX_WEIGHT,
            tokenIds,
            poolBalance
        );
        assertEq(result, expected);
    }
}
