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
        balances.push(1);
        balances.push(1);
        lockup.push(1);
        lockup.push(1);

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

    function testDeposit(uint256 lpAmount, uint256 lockup) public {
        lpAmount = bound(lpAmount, 1, 100e18);
        lockup = bound(lockup, 1, 208);
        uint256 preBalance = metapool.balanceOf(bondingMinAccount);
        vm.expectEmit(true, false, false, true);
        emit Deposit(
            bondingMinAccount, 
            bondingShareV2.totalSupply(), 
            lpAmount, 
            IUbiquityFormulas(manager.formulasAddress()).durationMultiply(
                lpAmount, 
                lockup, 
                bondingV2.bondingDiscountMultiplier()), 
            lockup, 
            (block.number + lockup * bondingV2.blockCountInAWeek()));
        vm.startPrank(bondingMinAccount);
        metapool.approve(address(bondingV2), 2**256-1);
        bondingV2.deposit(lpAmount, lockup);
        assertEq(metapool.balanceOf(bondingMinAccount), preBalance - lpAmount);
    }

    function testLockupMultiplier() public {
        uint256 minLP = metapool.balanceOf(bondingMinAccount);
        uint256 maxLP = metapool.balanceOf(bondingMaxAccount);
        /*minAmount = bound(minAmount, 1e9, minLP);
        maxAmount = bound(maxAmount, minAmount, maxLP);*/

        

        vm.startPrank(bondingMaxAccount);
        metapool.approve(address(bondingV2), 2**256-1);
        bondingV2.deposit(maxLP, 208);
        //uint256 bsMaxAmount = bondingShareV2.balanceOf(bondingMaxAccount, 1);
        vm.stopPrank();

        vm.startPrank(bondingMinAccount);
        metapool.approve(address(bondingV2), 2**256-1);
        bondingV2.deposit(minLP, 1);
        //uint256 bsMinAmount = bondingShareV2.balanceOf(bondingMinAccount, 2);
        vm.stopPrank();

        uint256[2] memory bsMaxAmount = chefV2.getBondingShareInfo(1);
        uint256[2] memory bsMinAmount = chefV2.getBondingShareInfo(2);


        assertLt(bsMinAmount[0], bsMaxAmount[0]);
    }

    function testCannotBondMoreThan4Years(uint256 _weeks) public {
        _weeks = bound(_weeks, 209, 2**256-1);
        vm.expectRevert("Bonding: duration must be between 1 and 208 weeks");
        vm.prank(fourthAccount);
        bondingV2.deposit(1, _weeks);
    }

    function testCannotDepositZeroWeeks() public {
        vm.expectRevert("Bonding: duration must be between 1 and 208 weeks");
        vm.prank(fourthAccount);
        bondingV2.deposit(1, 0);
    }
}

contract DepositState is ZeroState {
    
    function setUp() public virtual override {
        super.setUp();
        address[3] memory depositingAccounts = [bondingMinAccount, fourthAccount, bondingMaxAccount];
        uint256[3] memory depositAmounts = [metapool.balanceOf(bondingMinAccount), metapool.balanceOf(fourthAccount), metapool.balanceOf(bondingMaxAccount)];
        uint256[3] memory lockupWeeks = [uint256(1), uint256(52), uint256(208)];

        for(uint i; i < depositingAccounts.length; ++i){
            vm.startPrank(depositingAccounts[i]);
            metapool.approve(address(bondingV2), 2**256-1);
            bondingV2.deposit(depositAmounts[i], lockupWeeks[i]);
            vm.stopPrank();
        }
        twapOracle.update();
    }

}

contract DepositStateTest is DepositState {

    address[] path1;
    address[] path2;

    function testUADPriceReset(uint256 amount) public {
        amount = bound(amount, 1000e18, uAD.balanceOf(address(metapool))/10);

        uint256 uADPreBalance = uAD.balanceOf(address(metapool));

        vm.expectEmit(true, false, false, false, address(bondingV2));
        emit PriceReset(address(uAD), 1000e18, 1000e18);
        vm.prank(admin);
        bondingV2.uADPriceReset(amount);

        
        uint256 uADPostBalance = uAD.balanceOf(address(metapool));

        assertLt(uADPostBalance, uADPreBalance);
    }

    function testCRVPriceReset(uint256 amount) public {
        amount = bound(amount, 1000e18, crvToken.balanceOf(address(metapool))/10);
        uint256 crvPreBalance = crvToken.balanceOf(address(metapool));

        vm.expectEmit(true, false, false, false, address(bondingV2));
        emit PriceReset(address(crvToken), amount, amount);
        vm.prank(admin);
        bondingV2.crvPriceReset(amount);

        
        uint256 crvPostBalance = crvToken.balanceOf(address(metapool));
        assertLt(crvPostBalance, crvPreBalance);
    }

    function testAddLiquidity(uint256 amount, uint256 weeksLockup) public {
        
        weeksLockup = bound(weeksLockup, 1, 208);
        amount = bound(amount, 1e18, 2**128-1);
        BondingShareV2.Bond memory bond = bondingShareV2.getBond(1);
        uint256[2] memory preShares = chefV2.getBondingShareInfo(1);
        deal(address(metapool), bondingMinAccount, uint256(amount));
        vm.roll(20000000);
        vm.expectEmit(true, true, false, false, address(bondingV2));
        emit AddLiquidityFromBond(bondingMinAccount, 1, amount, uFormulas.durationMultiply(bond.lpAmount + amount, weeksLockup, bondingV2.bondingDiscountMultiplier()));
        vm.prank(bondingMinAccount);
        bondingV2.addLiquidity(uint256(amount), 1, weeksLockup);
        uint256[2] memory postShares = chefV2.getBondingShareInfo(1);
        assertGt(postShares[0], preShares[0]);
    }

    function testRemoveLiquidity(uint256 amount) public {
        vm.roll(20000000);
        BondingShareV2.Bond memory bond = bondingShareV2.getBond(1);
        amount = bound(amount, 1, bond.lpAmount);

        uint256 preBal = metapool.balanceOf(bondingMinAccount);
        vm.expectEmit(true, false, false, false, address(bondingV2));
        emit RemoveLiquidityFromBond(bondingMinAccount, 1, amount, amount, amount, amount);
        vm.prank(bondingMinAccount);
        bondingV2.removeLiquidity(amount, 1);
        uint256 postBal = metapool.balanceOf(bondingMinAccount);

        assertEq(preBal+amount, postBal);
    }

    function testPendingLPRewards() public {
        
        
        uint256 prePending = bondingV2.pendingLpRewards(3);

        deal(address(metapool), address(bondingV2), 1000000e18);
        
        uint256 postPending = bondingV2.pendingLpRewards(3);
        assertGt(postPending, prePending);
    }

    function testCannotRemoveMoreLiquidityThanBalance(uint256 amount) public {
        vm.roll(20000000);
        BondingShareV2.Bond memory bond = bondingShareV2.getBond(2);
        amount = bound(amount, bond.lpAmount+1, 2**256-1);
        vm.expectRevert("Bonding: amount too big");
        vm.prank(fourthAccount);
        bondingV2.removeLiquidity(amount, 2);
    }

    function testCannotCallOthersBond() public {
        vm.roll(20000000);
        vm.expectRevert("Bonding: caller is not owner");
        vm.prank(bondingMinAccount);
        bondingV2.removeLiquidity(1, 2);
    }

    function testCannotWithdrawBeforeBondExpires() public {
        vm.expectRevert("Bonding: Redeem not allowed before bonding time");
        vm.prank(bondingMaxAccount);
        bondingV2.removeLiquidity(1,3);
    }
}