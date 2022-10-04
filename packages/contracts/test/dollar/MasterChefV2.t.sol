// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../helpers/EnvironmentSetUp.sol";

contract ZeroState is EnvironmentSetUp {

    event Deposit(address indexed user, uint256 amount, uint256 indexed bondingShareId);

    event Withdraw(address indexed user, uint256 amount, uint256 indexed bondingShareId);

    event UGOVPerBlockModified(uint256 indexed uGOVPerBlock);

    event MinPriceDiffToUpdateMultiplierModified(uint256 indexed minPriceDiffToUpdateMultiplier);

    function setUp() public virtual override {
        super.setUp();
        vm.prank(admin);
        manager.setBondingContractAddress(admin);
    }
}

contract ZeroStateTest is ZeroState{

    function testSetUGOVPerBlock(uint256 uGOVPerBlock) public {
        vm.expectEmit(true, false, false, true, address(chefV2));
        emit UGOVPerBlockModified(uGOVPerBlock);
        vm.prank(admin);
        chefV2.setUGOVPerBlock(uGOVPerBlock);
        assertEq(chefV2.uGOVPerBlock(), uGOVPerBlock);
    }

    function testSetUGOVDiv(uint256 div) public {
        vm.prank(admin);
        chefV2.setUGOVShareForTreasury(div);
        assertEq(chefV2.uGOVDivider(), div);
    }

    function testSetMinPriceDiff(uint256 minPriceDiff) public {
        vm.expectEmit(true, false, false, true, address(chefV2));
        emit MinPriceDiffToUpdateMultiplierModified(minPriceDiff);
        vm.prank(admin);
        chefV2.setMinPriceDiffToUpdateMultiplier(minPriceDiff);
        assertEq(chefV2.minPriceDiffToUpdateMultiplier(), minPriceDiff);

    }

    function testDeposit(uint256 lpAmount) public {
        lpAmount = bound(lpAmount, 1, metapool.balanceOf(fourthAccount));
        uint256 shares = uFormulas.durationMultiply(lpAmount, 10, bondingV2.bondingDiscountMultiplier());
        vm.startPrank(admin);
        uint256 id = bondingShareV2.mint(fourthAccount, lpAmount, shares, block.number+100);
        vm.expectEmit(true, false, true, true, address(chefV2));
        emit Deposit(fourthAccount, shares, id);
        chefV2.deposit(fourthAccount, shares, id);
        vm.stopPrank();
        ( , uint256 accuGov) = chefV2.pool();
        uint256[2] memory info1 = [shares, (shares * accuGov) / 1e12];
        uint256[2] memory info2 = chefV2.getBondingShareInfo(id);
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
        shares = uFormulas.durationMultiply(fourthBal, 10, bondingV2.bondingDiscountMultiplier());
        vm.startPrank(admin);
        fourthID = bondingShareV2.mint(fourthAccount, fourthBal, shares, block.number+100);
        chefV2.deposit(fourthAccount, shares, fourthID);
        vm.stopPrank();
    }
}

contract DepositStateTest is DepositState {

    function testTotalShares() public {
        assertEq(chefV2.totalShares(), shares);
    }

    function testWithdraw(uint256 amount, uint256 blocks) public {
        blocks = bound(blocks, 1, 2**128-1);
        uint256 preBal = uGov.balanceOf(fourthAccount);
        (uint256 lastRewardBlock, ) = chefV2.pool();
        uint256 currentBlock = block.number;
        vm.roll(currentBlock + blocks);
        uint256 multiplier = (block.number - lastRewardBlock) * 1e18;
        uint256 reward = (multiplier * 10e18 / 1e18);
        uint256 uGOVPerShare = (reward *1e12)/ shares;
        uint256 userReward = (shares * uGOVPerShare) / 1e12;
        console.log("uGov Reward to User", userReward);
        amount = bound(amount, 1, shares);
        vm.expectEmit(true, true, true, true, address(chefV2));
        emit Withdraw(fourthAccount, amount, fourthID);
        vm.prank(admin);
        chefV2.withdraw(fourthAccount, amount, fourthID);
        assertEq(preBal + userReward, uGov.balanceOf(fourthAccount));
    }

    function testGetRewards(uint256 blocks) public {
        blocks = bound(blocks, 1, 2**128-1);
        
        (uint256 lastRewardBlock, ) = chefV2.pool();
        uint256 currentBlock = block.number;
        vm.roll(currentBlock + blocks);
        uint256 multiplier = (block.number - lastRewardBlock) * 1e18;
        uint256 reward = (multiplier * 10e18 / 1e18);
        uint256 uGOVPerShare = (reward *1e12)/ shares;
        uint256 userReward = (shares * uGOVPerShare) / 1e12;
        vm.prank(fourthAccount);
        uint256 rewardSent = chefV2.getRewards(1);
        assertEq(userReward, rewardSent);
    }

    function testCannotGetRewardsOtherAccount() public {
        vm.expectRevert("MS: caller is not owner");
        vm.prank(bondingMinAccount);
        chefV2.getRewards(1);
    }

    function testPendingUGOV(uint256 blocks) public {
        blocks = bound(blocks, 1, 2**128-1);
        
        (uint256 lastRewardBlock, ) = chefV2.pool();
        uint256 currentBlock = block.number;
        vm.roll(currentBlock + blocks);
        uint256 multiplier = (block.number - lastRewardBlock) * 1e18;
        uint256 reward = (multiplier * 10e18 / 1e18);
        uint256 uGOVPerShare = (reward *1e12)/ shares;
        uint256 userPending = (shares * uGOVPerShare) / 1e12;
        
        uint256 pendingUgov = chefV2.pendingUGOV(1);
        assertEq(userPending, pendingUgov);
    }

    function testGetBondingShareInfo() public {
        uint256[2] memory info1 = [shares, 0];
        uint256[2] memory info2 = chefV2.getBondingShareInfo(1);
        assertEq(info1[0], info2[0]);
        assertEq(info1[1], info2[1]);
    }

    
}