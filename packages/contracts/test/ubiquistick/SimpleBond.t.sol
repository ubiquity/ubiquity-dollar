// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../../src/ubiquistick/SimpleBond.sol";
import "../../src/ubiquistick/UbiquiStick.sol";

import "forge-std/Test.sol";

contract ZeroState is Test {
    address admin;
    address treasury;
    address firstAccount;
    address secondAccount;

    ERC20 rewardToken;
    ERC20 bondToken;
    ERC20 fakeToken;
    UbiquiStick stick;
    SimpleBond bond;

    event LogSetRewards(address token, uint256 rewardsRatio);

    event LogBond(
        address addr,
        address token,
        uint256 amount,
        uint256 rewards,
        uint256 block,
        uint256 bondId
    );

    event LogClaim(address addr, uint256 index, uint256 rewards);

    function setUp() public virtual {
        admin = address(0x1);
        treasury = address(0x2);
        firstAccount = address(0x3);
        secondAccount = address(0x4);

        vm.startPrank(admin);
        rewardToken = new ERC20("rToken", "RT");
        bondToken = new ERC20("bToken", "BT");
        fakeToken = new ERC20("fToken", "FT");
        stick = new UbiquiStick();
        bond = new SimpleBond(address(rewardToken), 100, treasury);
        vm.stopPrank();
    }
}

contract ZeroStateTest is ZeroState {
    function testSetSticker_ShouldSetSticker() public {
        vm.prank(admin);
        bond.setSticker(address(stick));
        assertEq(bond.sticker(), address(stick));
    }

    function testSetRewards_ShouldSetRewards(uint256 ratio) public {
        vm.prank(admin);
        bond.setRewards(address(bondToken), ratio);
        assertEq(bond.rewardsRatio(address(bondToken)), ratio);
    }

    function testSetVestingBlocks_ShouldSetVestingBlocks(
        uint256 blocks
    ) public {
        blocks = bound(blocks, 1, 2 ** 256 - 1);
        vm.prank(admin);
        bond.setVestingBlocks(blocks);
        assertEq(bond.vestingBlocks(), blocks);
    }

    function testSetTreasury_ShouldSetTreasury() public {
        vm.prank(admin);
        bond.setTreasury(admin);
        assertEq(bond.treasury(), admin);
    }
}

contract StickerState is ZeroState {
    function setUp() public virtual override {
        super.setUp();
        vm.startPrank(admin);
        bond.setRewards(address(bondToken), 50);
        bond.setSticker(address(stick));
        stick.safeMint(firstAccount);
        stick.safeMint(secondAccount);
        vm.stopPrank();
        deal(address(bondToken), firstAccount, 2 ** 256 - 1);
        deal(address(bondToken), secondAccount, 2 ** 256 - 1);
    }
}

contract StickerStateTest is StickerState {
    function testBond(uint256 amount) public {
        amount = bound(amount, 1, 2 ** 128 - 1);
        vm.startPrank(firstAccount);
        bondToken.approve(address(bond), 2 ** 256 - 1);
        vm.expectEmit(true, true, true, true, address(bond));
        emit LogBond(
            firstAccount,
            address(bondToken),
            amount,
            ((50 * amount) / 1e9),
            block.number,
            0
        );
        bond.bond(address(bondToken), amount);
        vm.stopPrank();
        assertEq(bond.bondsCount(firstAccount), 1);
        (, uint256 amount_, , , ) = bond.bonds(firstAccount, 0);
        assertEq(amount, amount_);
    }

    function testBond_ShouldRevert_IfTokenNotAllowed() public {
        vm.expectRevert("Token not allowed");
        vm.prank(secondAccount);
        bond.bond(address(fakeToken), 1);
    }
}

contract BondedState is StickerState {
    uint256[] firstIDs;
    uint256[] secondIDs;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(firstAccount);
        bondToken.approve(address(bond), 2 ** 256 - 1);
        firstIDs.push(bond.bond(address(bondToken), 1e24));
        firstIDs.push(bond.bond(address(bondToken), 1e24));
        firstIDs.push(bond.bond(address(bondToken), 1e24));
        vm.stopPrank();
        vm.startPrank(secondAccount);
        bondToken.approve(address(bond), 2 ** 256 - 1);
        secondIDs.push(bond.bond(address(bondToken), 1e25));
        secondIDs.push(bond.bond(address(bondToken), 1e25));
        secondIDs.push(bond.bond(address(bondToken), 1e25));
        secondIDs.push(bond.bond(address(bondToken), 1e25));
        secondIDs.push(bond.bond(address(bondToken), 1e25));
        vm.stopPrank();
    }
}

contract BondedStateTest is BondedState {
    uint256[5] amounts;
    uint256[5] rewards;
    uint256[5] blocks_;

    function testClaim_ShouldClaimRewards(uint256 blocks) public {
        blocks = bound(blocks, 0, 2 ** 128 - 1);
        uint256 preBal = rewardToken.balanceOf(firstAccount);
        vm.warp(block.number + blocks);
        (, uint256 amount0, , , uint256 block0) = bond.bonds(firstAccount, 0);
        (, uint256 amount1, , , uint256 block1) = bond.bonds(firstAccount, 1);
        (, uint256 amount2, , , uint256 block2) = bond.bonds(firstAccount, 2);

        uint256 expected;

        expected += (((amount0 * 50) / 1e9) * (block.number - block0)) / 100;
        expected += (((amount1 * 50) / 1e9) * (block.number - block1)) / 100;
        expected += (((amount2 * 50) / 1e9) * (block.number - block2)) / 100;

        vm.prank(firstAccount);
        uint256 claimed = bond.claim();

        assertEq(expected, claimed);
        assertEq(preBal + expected, rewardToken.balanceOf(firstAccount));
    }

    function testClaimBond_ShouldEmitLogClaimAndClaimBondRewards(
        uint256 blocks
    ) public {
        blocks = bound(blocks, 0, 2 ** 128 - 1);
        vm.warp(block.number + blocks);
        (, uint256 amount0, , , uint256 block0) = bond.bonds(secondAccount, 0);
        uint256 expected = (((amount0 * 50) / 1e9) * (block.number - block0)) /
            100;
        vm.expectEmit(true, true, true, true, address(bond));
        emit LogClaim(secondAccount, 0, expected);
        vm.prank(secondAccount);
        uint256 claimed = bond.claimBond(0);
        assertEq(expected, claimed);
    }

    function testWithdraw_ShouldWithdrawBondTokens(uint256 amount) public {
        amount = bound(amount, 1, bondToken.balanceOf(address(bond)));
        uint256 preBalTreasury = bondToken.balanceOf(treasury);
        uint256 preBalBond = bondToken.balanceOf(address(bond));
        vm.prank(admin);
        bond.withdraw(address(bondToken), amount);
        assertEq(preBalTreasury + amount, bondToken.balanceOf(treasury));
        assertEq(preBalBond - amount, bondToken.balanceOf(address(bond)));
    }

    function testRewardsOf_ShouldReturnRewardsOfBond(uint256 blocks) public {
        blocks = bound(blocks, 0, 2 ** 128 - 1);

        vm.warp(block.number + blocks);

        for (uint256 i; i < amounts.length; ++i) {
            (, uint256 amount, uint256 reward, , uint256 block_) = bond.bonds(
                secondAccount,
                i
            );
            amounts[i] = amount;
            rewards[i] = reward;
            blocks_[i] = block_;
        }

        uint256 rewardsExpected;

        for (uint256 i; i < rewards.length; i++) {
            rewardsExpected += rewards[i];
        }

        uint256 claimableExpected;

        for (uint256 i; i < amounts.length; ++i) {
            claimableExpected +=
                (((amounts[i] * 50) / 1e9) * (block.number - blocks_[i])) /
                100;
        }

        (
            uint256 rewards_,
            uint256 rewardsClaimed,
            uint256 rewardsClaimable
        ) = bond.rewardsOf(secondAccount);
        assertEq(rewardsExpected, rewards_);
        assertEq(0, rewardsClaimed);
        assertEq(claimableExpected, rewardsClaimable);
    }

    function testRewardsBondOf_ShouldReturnCorrectValues(
        uint256 blocks,
        uint256 i
    ) public {
        blocks = bound(blocks, 0, 2 ** 128 - 1);
        i = bound(i, 0, 4);
        vm.warp(block.number + blocks);

        (, uint256 amount, uint256 rewardExpected, , uint256 block_) = bond
            .bonds(secondAccount, i);

        uint256 claimableExpected = (((amount * 50) / 1e9) *
            (block.number - block_)) / 100;
        (uint256 reward, uint256 rewardClaimed, uint256 rewardClaimable) = bond
            .rewardsBondOf(secondAccount, i);
        assertEq(rewardExpected, reward);
        assertEq(rewardClaimed, 0);
        assertEq(rewardClaimable, claimableExpected);
    }

    function testBondsCount_ShouldReturnCorrectCount() public {
        uint256 firstCount = bond.bondsCount(firstAccount);
        uint256 secondCount = bond.bondsCount(secondAccount);

        assertEq(firstCount, firstIDs.length);
        assertEq(secondCount, secondIDs.length);
    }
}
