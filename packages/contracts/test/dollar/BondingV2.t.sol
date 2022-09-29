// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../helpers/EnvironmentSetUp.sol";


contract ZeroState is EnvironmentSetUp {


    event PriceReset(address _tokenWithdrawn, uint256 _amountWithdrawn, uint256 _amountTransfered);

    event Deposit(
        address indexed _user,
        uint256 indexed _id,
        uint256 _lpAmount,
        uint256 _bondingShareAmount,
        uint256 _weeks,
        uint256 _endBlock
    );
    event RemoveLiquidityFromBond(
        address indexed _user,
        uint256 indexed _id,
        uint256 _lpAmount,
        uint256 _lpAmountTransferred,
        uint256 _lprewards,
        uint256 _bondingShareAmount
    );

    event AddLiquidityFromBond(
        address indexed _user, uint256 indexed _id, uint256 _lpAmount, uint256 _bondingShareAmount
    );

    event BondingDiscountMultiplierUpdated(uint256 _bondingDiscountMultiplier);
    event BlockCountInAWeekUpdated(uint256 _blockCountInAWeek);

    event Migrated(
        address indexed _user, uint256 indexed _id, uint256 _lpsAmount, uint256 _sharesAmount, uint256 _weeks
    );
    event DustSent(address _to, address token, uint256 amount);
    event ProtocolTokenAdded(address _token);
    event ProtocolTokenRemoved(address _token);

    address[] ogs;
    address[] ogsEmpty;
    uint256[] balances;
    uint256[] lockup;

    function setUp() public virtual override {
        super.setUp();
        deal(address(metapool), fourthAccount, 1000e18);
        ogs.push(secondAccount);
        ogs.push(thirdAccount);
    }
}

contract ZeroStateTest is ZeroState {

    using stdStorage for StdStorage;

    function testAddUserToMigrate(uint256 x, uint256 y) public {
        x = bound(x, 1, 2**128-1);
        y = bound(y, 1, 208);
        console.logUint(x);
        console.logUint(y);

        vm.prank(admin);
        vm.record();
        bondingV2.addUserToMigrate(fourthAccount, x, y);

        (bytes32[] memory reads, bytes32[] memory writes) = vm.accesses(address(bondingV2));
        

        address checkAddress = address(bytes20(vm.load(address(bondingV2), writes[1])<<96) );
        uint256 checkLP = uint256(vm.load(address(bondingV2), writes[3]));
        uint256 checkWeeks = uint256(vm.load(address(bondingV2), writes[6]));

    

        assertEq(fourthAccount, checkAddress);
        assertEq(x, checkLP);
        assertEq(y, checkWeeks);
    }

    function testCannotDeployEmptyAddress() public {
        vm.expectRevert("address array empty");
        BondingV2 broken = new BondingV2(address(manager),
            address(bFormulas),
            ogsEmpty,
            balances,
            lockup
        );
    }

    function testCannotDeployDifferentLength1() public {
        balances.push(1);
        vm.expectRevert("balances array not same length");
        BondingV2 broken = new BondingV2(
            address(manager),
            address(bFormulas), 
            ogs, 
            balances, 
            lockup
        );
    }

    function testCannotDeployDifferentLength2() public {
        lockup.push(1);
        vm.expectRevert("weeks array not same length");
        BondingV2 broken = new BondingV2(
            address(manager),
            address(bFormulas), 
            ogs, 
            balances, 
            lockup
        );
    }

    function testSetMigrator() public {
        vm.prank(admin);
        bondingV2.setMigrator(secondAccount);
        assertEq(secondAccount, bondingV2.migrator());
    }

    function testSetMigrating() public {
        assertEq(true, bondingV2.migrating());
        vm.prank(admin);
        bondingV2.setMigrating(false);
        assertEq(false, bondingV2.migrating());
    }

    function testSetBondingFormula() public {
        assertEq(bytes20(address(bFormulas)), bytes20(bondingV2.bondingFormulasAddress()));
        vm.prank(admin);
        bondingV2.setBondingFormulasAddress(secondAccount);
        
        assertEq(bytes20(secondAccount), bytes20(bondingV2.bondingFormulasAddress()));
    }

    function testAddProtocolToken() public {
        vm.expectEmit(true, false, false, true);
        emit ProtocolTokenAdded(address(DAI));
        vm.prank(admin);
        bondingV2.addProtocolToken(address(DAI));
    }

    function testSetBondingDiscountMultiplier(uint256 x) public {
        vm.expectEmit(true, false, false, true);
        emit BondingDiscountMultiplierUpdated(x);
        vm.prank(admin);
        bondingV2.setBondingDiscountMultiplier(x);
        assertEq(x, bondingV2.bondingDiscountMultiplier());
    }

    function testSetBlockCountInAWeek(uint256 x) public {
        vm.expectEmit(true, false, false, true);
        emit BlockCountInAWeekUpdated(x);
        vm.prank(admin);
        bondingV2.setBlockCountInAWeek(x);
        assertEq(x, bondingV2.blockCountInAWeek());
    }

    /*function testDeposit(uint256 lpAmount, uint256 lockup) public {
        lpAmount = bound(lpAmount, 1, 100e18);
        lockup = bound(lockup, 1, 208);
        uint256 preBalance = metapool.balanceOf(new1);
        ///vm.expectEmit(true, false, false, true);
        //emit Deposit(new1, 1, lpAmount, IUbiquityFormulas(manager.formulasAddress()).durationMultiply(lpAmount, lockup, bonding.bondingDiscountMultiplier()), lockup, (block.number + lockup * bonding.blockCountInAWeek()));
        vm.startPrank(new1);
        metapool.approve(address(bondingV2), 2**256-1);
        bonding.deposit(lpAmount, lockup);
        assertEq(metapool.balanceOf(new1), preBalance - lpAmount);
    }*/
}