// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../helpers/LiveTestHelper.sol";

contract DepositState is LiveTestHelper {
    uint256 fourthBal;
    uint256 minBal;
    uint256 maxBal;
    uint256[] creationBlock;

    function setUp() public virtual override {
        super.setUp();
        fourthBal = metapool.balanceOf(fourthAccount);
        minBal = metapool.balanceOf(bondingMinAccount);
        maxBal = metapool.balanceOf(bondingMaxAccount);
        address[4] memory depositingAccounts = [
            bondingMinAccount,
            fourthAccount,
            bondingMaxAccount,
            bondingMaxAccount
        ];
        uint256[4] memory depositAmounts =
            [minBal, fourthBal, maxBal / 2, maxBal / 2];
        uint256[4] memory lockupWeeks =
            [uint256(1), uint256(52), uint256(208), uint256(208)];

        for (uint256 i; i < depositingAccounts.length; ++i) {
            vm.startPrank(depositingAccounts[i]);
            metapool.approve(address(bondingV2), 2 ** 256 - 1);
            creationBlock.push(block.number);
            bondingV2.deposit(depositAmounts[i], lockupWeeks[i]);
            vm.stopPrank();
        }
    }
}

contract DepositStateTest is DepositState {
    uint256[] ids;
    uint256[] amounts;

    function testUpdateStake(uint128 amount, uint128 debt, uint256 end) public {
        vm.prank(admin);
        bondingShareV2.updateStake(1, uint256(amount), uint256(debt), end);
        StakingShare.Stake memory stake = bondingShareV2.getStake(1);
        assertEq(stake.lpAmount, amount);
        assertEq(stake.lpRewardDebt, debt);
        assertEq(stake.endBlock, end);
    }

    function testMint(uint128 deposited, uint128 debt, uint256 end) public {
        vm.prank(admin);
        uint256 id = bondingShareV2.mint(
            secondAccount, uint256(deposited), uint256(debt), end
        );
        StakingShare.Stake memory stake = bondingShareV2.getStake(id);
        assertEq(stake.minter, secondAccount);
        assertEq(stake.lpAmount, deposited);
        assertEq(stake.lpRewardDebt, debt);
        assertEq(stake.endBlock, end);
    }

    function testTransferFrom() public {
        vm.prank(bondingMinAccount);
        bondingShareV2.setApprovalForAll(admin, true);

        bytes memory data;
        vm.prank(admin);
        bondingShareV2.safeTransferFrom(
            bondingMinAccount, secondAccount, 1, 1, data
        );
        ids.push(1);

        assertEq(bondingShareV2.holderTokens(secondAccount), ids);
    }

    function testBatchTransfer() public {
        ids.push(3);
        ids.push(4);
        amounts.push(1);
        amounts.push(1);

        vm.prank(bondingMaxAccount);
        bondingShareV2.setApprovalForAll(admin, true);

        bytes memory data;

        vm.prank(admin);
        bondingShareV2.safeBatchTransferFrom(
            bondingMaxAccount, secondAccount, ids, amounts, data
        );
        assertEq(bondingShareV2.holderTokens(secondAccount), ids);
    }

    function testTotalSupply() public {
        assertEq(bondingShareV2.totalSupply(), 4);
    }

    // // TODO: needs to figured out why it sometimes fails
    // function test_TotalLP() public {
    //     uint256 totalLp = fourthBal + minBal + maxBal - 1;
    //     assertEq(bondingShareV2.totalLP(), totalLp);
    // }

    function testGetStake() public {
        StakingShare.Stake memory stake = StakingShare.Stake(
            fourthAccount,
            fourthBal,
            creationBlock[1],
            uFormulas.durationMultiply(
                fourthBal, 52, bondingV2.bondingDiscountMultiplier()
            ),
            bondingV2.blockCountInAWeek() * 52,
            fourthBal
        );

        StakingShare.Stake memory stake_ = bondingShareV2.getStake(2);
        bytes32 stake1 = bytes32(abi.encode(stake));
        bytes32 stake2 = bytes32(abi.encode(stake_));
        assertEq(stake1, stake2);
    }

    function testHolderTokens() public {
        ids.push(1);
        uint256[] memory ids_ = bondingShareV2.holderTokens(bondingMinAccount);
        assertEq(ids, ids_);
    }
}
