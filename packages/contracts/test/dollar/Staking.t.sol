// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../helpers/LiveTestHelper.sol";

contract ZeroState is LiveTestHelper {
    event PriceReset(
        address _tokenWithdrawn,
        uint256 _amountWithdrawn,
        uint256 _amountTransferred
    );

    event Deposit(
        address indexed _user,
        uint256 indexed _id,
        uint256 _lpAmount,
        uint256 _stakingShareAmount,
        uint256 _weeks,
        uint256 _endBlock
    );
    event RemoveLiquidityFromStake(
        address indexed _user,
        uint256 indexed _id,
        uint256 _lpAmount,
        uint256 _lpAmountTransferred,
        uint256 _lpRewards,
        uint256 _stakingShareAmount
    );

    event AddLiquidityFromStake(
        address indexed _user,
        uint256 indexed _id,
        uint256 _lpAmount,
        uint256 _stakingShareAmount
    );

    event StakingDiscountMultiplierUpdated(uint256 _stakingDiscountMultiplier);
    event BlockCountInAWeekUpdated(uint256 _blockCountInAWeek);

    event Migrated(
        address indexed _user,
        uint256 indexed _id,
        uint256 _lpsAmount,
        uint256 _sharesAmount,
        uint256 _weeks
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

contract RemoteZeroStateTest is ZeroState {
    using stdStorage for StdStorage;

    function testAddUserToMigrate(uint256 x, uint256 y) public {
        x = bound(x, 1, 2 ** 128 - 1);
        y = bound(y, 1, 208);
        console.logUint(x);
        console.logUint(y);

        vm.prank(admin);
        vm.record();
        staking.addUserToMigrate(fourthAccount, x, y);

        (bytes32[] memory reads, bytes32[] memory writes) = vm.accesses(
            address(staking)
        );

        address checkAddress = address(
            bytes20(vm.load(address(staking), writes[1]) << 96)
        );
        uint256 checkLP = uint256(vm.load(address(staking), writes[3]));
        uint256 checkWeeks = uint256(vm.load(address(staking), writes[6]));

        assertEq(fourthAccount, checkAddress);
        assertEq(x, checkLP);
        assertEq(y, checkWeeks);
    }

    function testCannotDeployEmptyAddress() public {
        vm.expectRevert("address array empty");
        // Staking broken =
        new Staking(
            address(manager),
            address(stakingFormulas),
            ogsEmpty,
            balances,
            lockup
        );
    }

    function testCannotDeployDifferentLength1() public {
        balances.push(1);
        vm.expectRevert("balances array not same length");
        // Staking broken =
        new Staking(
            address(manager),
            address(stakingFormulas),
            ogs,
            balances,
            lockup
        );
    }

    function testCannotDeployDifferentLength2() public {
        lockup.push(1);
        vm.expectRevert("weeks array not same length");
        // Staking broken =
        new Staking(
            address(manager),
            address(stakingFormulas),
            ogs,
            balances,
            lockup
        );
    }

    function testSetMigrator() public {
        vm.prank(admin);
        staking.setMigrator(secondAccount);
        assertEq(secondAccount, staking.migrator());
    }

    function testSetMigrating() public {
        assertEq(true, staking.migrating());
        vm.prank(admin);
        staking.setMigrating(false);
        assertEq(false, staking.migrating());
    }

    function testSetStakingFormula() public {
        assertEq(
            bytes20(address(stakingFormulas)),
            bytes20(staking.stakingFormulasAddress())
        );
        vm.prank(admin);
        staking.setStakingFormulasAddress(secondAccount);

        assertEq(
            bytes20(secondAccount),
            bytes20(staking.stakingFormulasAddress())
        );
    }

    function testAddProtocolToken() public {
        vm.expectEmit(true, false, false, true);
        emit ProtocolTokenAdded(address(DAI));
        vm.prank(admin);
        staking.addProtocolToken(address(DAI));
    }

    function testSetStakingDiscountMultiplier(uint256 x) public {
        vm.expectEmit(true, false, false, true);
        emit StakingDiscountMultiplierUpdated(x);
        vm.prank(admin);
        staking.setStakingDiscountMultiplier(x);
        assertEq(x, staking.stakingDiscountMultiplier());
    }

    function testSetBlockCountInAWeek(uint256 x) public {
        vm.expectEmit(true, false, false, true);
        emit BlockCountInAWeekUpdated(x);
        vm.prank(admin);
        staking.setBlockCountInAWeek(x);
        assertEq(x, staking.blockCountInAWeek());
    }

    function testDeposit(uint256 lpAmount, uint256 lockup) public {
        lpAmount = bound(lpAmount, 1, 100e18);
        lockup = bound(lockup, 1, 208);
        uint256 preBalance = metapool.balanceOf(stakingMinAccount);
        vm.expectEmit(true, false, false, true);
        emit Deposit(
            stakingMinAccount,
            stakingShare.totalSupply(),
            lpAmount,
            IUbiquityFormulas(manager.formulasAddress()).durationMultiply(
                lpAmount,
                lockup,
                staking.stakingDiscountMultiplier()
            ),
            lockup,
            (block.number + lockup * staking.blockCountInAWeek())
        );
        vm.startPrank(stakingMinAccount);
        metapool.approve(address(staking), 2 ** 256 - 1);
        staking.deposit(lpAmount, lockup);
        assertEq(metapool.balanceOf(stakingMinAccount), preBalance - lpAmount);
    }

    function testLockupMultiplier() public {
        uint256 minLP = metapool.balanceOf(stakingMinAccount);
        uint256 maxLP = metapool.balanceOf(stakingMaxAccount);
        /*minAmount = bound(minAmount, 1e9, minLP);
        maxAmount = bound(maxAmount, minAmount, maxLP);*/

        vm.startPrank(stakingMaxAccount);
        metapool.approve(address(staking), 2 ** 256 - 1);
        staking.deposit(maxLP, 208);
        //uint256 bsMaxAmount = bondingShareV2.balanceOf(stakingMaxAccount, 1);
        vm.stopPrank();

        vm.startPrank(stakingMinAccount);
        metapool.approve(address(staking), 2 ** 256 - 1);
        staking.deposit(minLP, 1);
        //uint256 bsMinAmount = bondingShareV2.balanceOf(stakingMinAccount, 2);
        vm.stopPrank();

        uint256[2] memory bsMaxAmount = ubiquityChef.getStakingShareInfo(1);
        uint256[2] memory bsMinAmount = ubiquityChef.getStakingShareInfo(2);

        assertLt(bsMinAmount[0], bsMaxAmount[0]);
    }

    function testCannotStakeMoreThan4Years(uint256 _weeks) public {
        _weeks = bound(_weeks, 209, 2 ** 256 - 1);
        vm.expectRevert("Staking: duration must be between 1 and 208 weeks");
        vm.prank(fourthAccount);
        staking.deposit(1, _weeks);
    }

    function testCannotDepositZeroWeeks() public {
        vm.expectRevert("Staking: duration must be between 1 and 208 weeks");
        vm.prank(fourthAccount);
        staking.deposit(1, 0);
    }
}

contract DepositState is ZeroState {
    function setUp() public virtual override {
        super.setUp();
        address[3] memory depositingAccounts = [
            stakingMinAccount,
            fourthAccount,
            stakingMaxAccount
        ];
        uint256[3] memory depositAmounts = [
            metapool.balanceOf(stakingMinAccount),
            metapool.balanceOf(fourthAccount),
            metapool.balanceOf(stakingMaxAccount)
        ];
        uint256[3] memory lockupWeeks = [uint256(1), uint256(52), uint256(208)];

        for (uint256 i; i < depositingAccounts.length; ++i) {
            vm.startPrank(depositingAccounts[i]);
            metapool.approve(address(staking), 2 ** 256 - 1);
            staking.deposit(depositAmounts[i], lockupWeeks[i]);
            vm.stopPrank();
        }
        twapOracle.update();
    }
}

contract RemoteDepositStateTest is DepositState {
    address[] path1;
    address[] path2;

    function testDollarPriceReset(uint256 amount) public {
        amount = bound(
            amount,
            1000e18,
            dollarToken.balanceOf(address(metapool)) / 10
        );

        uint256 dollarPreBalance = dollarToken.balanceOf(address(metapool));

        vm.expectEmit(true, false, false, false, address(staking));
        emit PriceReset(address(dollarToken), 1000e18, 1000e18);
        vm.prank(admin);
        staking.dollarPriceReset(amount);

        uint256 dollarPostBalance = dollarToken.balanceOf(address(metapool));

        assertLt(dollarPostBalance, dollarPreBalance);
    }

    function testCRVPriceReset(uint256 amount) public {
        amount = bound(
            amount,
            1000e18,
            crvToken.balanceOf(address(metapool)) / 10
        );
        uint256 crvPreBalance = crvToken.balanceOf(address(metapool));

        vm.expectEmit(true, false, false, false, address(staking));
        emit PriceReset(address(crvToken), amount, amount);
        vm.prank(admin);
        staking.crvPriceReset(amount);

        uint256 crvPostBalance = crvToken.balanceOf(address(metapool));
        assertLt(crvPostBalance, crvPreBalance);
    }

    function testAddLiquidity(uint256 amount, uint256 weeksLockup) public {
        weeksLockup = bound(weeksLockup, 1, 208);
        amount = bound(amount, 1e18, 2 ** 128 - 1);
        StakingShare.Stake memory stake = stakingShare.getStake(1);
        uint256[2] memory preShares = ubiquityChef.getStakingShareInfo(1);
        deal(address(metapool), stakingMinAccount, uint256(amount));
        vm.roll(20000000);
        vm.expectEmit(true, true, false, false, address(staking));
        emit AddLiquidityFromStake(
            stakingMinAccount,
            1,
            amount,
            ubiquityFormulas.durationMultiply(
                stake.lpAmount + amount,
                weeksLockup,
                staking.stakingDiscountMultiplier()
            )
        );
        vm.prank(stakingMinAccount);
        staking.addLiquidity(uint256(amount), 1, weeksLockup);
        uint256[2] memory postShares = ubiquityChef.getStakingShareInfo(1);
        assertGt(postShares[0], preShares[0]);
    }

    function testRemoveLiquidity(uint256 amount) public {
        vm.roll(20000000);
        StakingShare.Stake memory stake = stakingShare.getStake(1);
        amount = bound(amount, 1, stake.lpAmount);

        uint256 preBal = metapool.balanceOf(stakingMinAccount);
        vm.expectEmit(true, false, false, false, address(staking));
        emit RemoveLiquidityFromStake(
            stakingMinAccount,
            1,
            amount,
            amount,
            amount,
            amount
        );
        vm.prank(stakingMinAccount);
        staking.removeLiquidity(amount, 1);
        uint256 postBal = metapool.balanceOf(stakingMinAccount);

        assertEq(preBal + amount, postBal);
    }

    function testPendingLPRewards() public {
        uint256 prePending = staking.pendingLpRewards(3);

        deal(address(metapool), address(staking), 1000000e18);

        uint256 postPending = staking.pendingLpRewards(3);
        assertGt(postPending, prePending);
    }

    function testCannotRemoveMoreLiquidityThanBalance(uint256 amount) public {
        vm.roll(20000000);
        StakingShare.Stake memory stake = stakingShare.getStake(2);
        amount = bound(amount, stake.lpAmount + 1, 2 ** 256 - 1);
        vm.expectRevert("Staking: amount too big");
        vm.prank(fourthAccount);
        staking.removeLiquidity(amount, 2);
    }

    function testCannotCallOthersStake() public {
        vm.roll(20000000);
        vm.expectRevert("Staking: caller is not owner");
        vm.prank(stakingMinAccount);
        staking.removeLiquidity(1, 2);
    }

    function testCannotWithdrawBeforeStakeExpires() public {
        vm.expectRevert("Staking: Redeem not allowed before staking time");
        vm.prank(stakingMaxAccount);
        staking.removeLiquidity(1, 3);
    }
}
