// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../helpers/LiveTestHelper.sol";

contract ZeroState is LiveTestHelper {
    event Deposit(
        address indexed user,
        uint256 amount,
        uint256 indexed stakingShareId
    );

    event Withdraw(
        address indexed user,
        uint256 amount,
        uint256 indexed stakingShareId
    );

    event GovernancePerBlockModified(uint256 indexed governancePerBlock);

    event MinPriceDiffToUpdateMultiplierModified(
        uint256 indexed minPriceDiffToUpdateMultiplier
    );

    function setUp() public virtual override {
        super.setUp();
        vm.prank(admin);
        manager.setStakingContractAddress(admin);
    }
}

contract RemoteZeroStateTest is ZeroState {
    function testSetGovernancePerBlock(uint256 governancePerBlock) public {
        vm.expectEmit(true, false, false, true, address(ubiquityChef));
        emit GovernancePerBlockModified(governancePerBlock);
        vm.prank(admin);
        ubiquityChef.setGovernancePerBlock(governancePerBlock);
        assertEq(ubiquityChef.governancePerBlock(), governancePerBlock);
    }

    function testSetGovernanceDiv(uint256 div) public {
        vm.prank(admin);
        ubiquityChef.setGovernanceShareForTreasury(div);
        assertEq(ubiquityChef.governanceDivider(), div);
    }

    function testSetMinPriceDiff(uint256 minPriceDiff) public {
        vm.expectEmit(true, false, false, true, address(ubiquityChef));
        emit MinPriceDiffToUpdateMultiplierModified(minPriceDiff);
        vm.prank(admin);
        ubiquityChef.setMinPriceDiffToUpdateMultiplier(minPriceDiff);
        assertEq(ubiquityChef.minPriceDiffToUpdateMultiplier(), minPriceDiff);
    }

    function testDeposit(uint256 lpAmount) public {
        lpAmount = bound(lpAmount, 1, metapool.balanceOf(fourthAccount));
        uint256 shares = ubiquityFormulas.durationMultiply(
            lpAmount,
            10,
            staking.stakingDiscountMultiplier()
        );
        vm.startPrank(admin);
        uint256 id = stakingShare.mint(
            fourthAccount,
            lpAmount,
            shares,
            block.number + 100
        );
        vm.expectEmit(true, false, true, true, address(ubiquityChef));
        emit Deposit(fourthAccount, shares, id);
        ubiquityChef.deposit(fourthAccount, shares, id);
        vm.stopPrank();
        (, uint256 accGovernance) = ubiquityChef.pool();
        uint256[2] memory info1 = [shares, (shares * accGovernance) / 1e12];
        uint256[2] memory info2 = ubiquityChef.getStakingShareInfo(id);
        assertEq(info1[0], info2[0]);
        assertEq(info1[1], info2[1]);
    }
}

contract DepositState is ZeroState {
    uint256 fourthBal;
    uint256 fourthID;
    uint256 shares;

    function setUp() public virtual override {
        super.setUp();
        fourthBal = metapool.balanceOf(fourthAccount);
        shares = ubiquityFormulas.durationMultiply(
            fourthBal,
            10,
            staking.stakingDiscountMultiplier()
        );
        vm.startPrank(admin);
        fourthID = stakingShare.mint(
            fourthAccount,
            fourthBal,
            shares,
            block.number + 100
        );
        ubiquityChef.deposit(fourthAccount, shares, fourthID);
        vm.stopPrank();
    }
}

contract RemoteDepositStateTest is DepositState {
    function testTotalShares() public {
        assertEq(ubiquityChef.totalShares(), shares);
    }

    function testWithdraw(uint256 amount, uint256 blocks) public {
        blocks = bound(blocks, 1, 2 ** 64 - 1);
        amount = bound(amount, 1, shares);
        uint256 preBal = governanceToken.balanceOf(fourthAccount);
        uint256 preBal_ = metapool.balanceOf(fourthAccount);
        vm.roll(block.number + blocks);
        vm.expectEmit(true, false, false, true, address(ubiquityChef));
        emit Withdraw(fourthAccount, amount, fourthID);
        vm.prank(admin);
        ubiquityChef.withdraw(fourthAccount, amount, fourthID);
        assertLt(preBal, governanceToken.balanceOf(fourthAccount));
    }

    function testGetRewards(uint256 blocks) public {
        blocks = bound(blocks, 1, 2 ** 64 - 1);
        uint256 preBal = governanceToken.balanceOf(fourthAccount);
        vm.roll(block.number + blocks);

        vm.prank(fourthAccount);
        uint256 rewardSent = ubiquityChef.getRewards(1);
        assertLt(preBal, preBal + rewardSent);
    }

    function testCannotGetRewardsOtherAccount() public {
        vm.expectRevert("MS: caller is not owner");
        vm.prank(stakingMinAccount);
        ubiquityChef.getRewards(1);
    }

    function testPendingGovernance(uint256 blocks) public {
        blocks = bound(blocks, 1, 2 ** 128 - 1);

        (uint256 lastRewardBlock, ) = ubiquityChef.pool();
        uint256 currentBlock = block.number;
        vm.roll(currentBlock + blocks);
        uint256 multiplier = (block.number - lastRewardBlock) * 1e18;
        uint256 reward = ((multiplier * 10e18) / 1e18);
        uint256 governancePerShare = (reward * 1e12) / shares;
        uint256 userPending = (shares * governancePerShare) / 1e12;

        uint256 pendingGovernance = ubiquityChef.pendingGovernance(1);
        assertEq(userPending, pendingGovernance);
    }
}
