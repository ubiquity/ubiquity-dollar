// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../helpers/LiveTestHelper.sol";

contract DepositState is LiveTestHelper {
    uint256 fourthBal;
    uint256 minBal;
    uint256 maxBal;
    uint256[] creationBlock;

    event Paused(address _caller);
    event Unpaused(address _caller);
    event TransferSingle(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount
    );

    function setUp() public virtual override {
        super.setUp();
        fourthBal = metapool.balanceOf(fourthAccount);
        minBal = metapool.balanceOf(stakingMinAccount);
        maxBal = metapool.balanceOf(stakingMaxAccount);
        address[4] memory depositingAccounts = [
            stakingMinAccount,
            fourthAccount,
            stakingMaxAccount,
            stakingMaxAccount
        ];
        uint256[4] memory depositAmounts = [
            minBal,
            fourthBal,
            maxBal / 2,
            maxBal / 2
        ];
        uint256[4] memory lockupWeeks = [
            uint256(1),
            uint256(52),
            uint256(208),
            uint256(208)
        ];

        for (uint256 i; i < depositingAccounts.length; ++i) {
            vm.startPrank(depositingAccounts[i]);
            metapool.approve(address(staking), 2 ** 256 - 1);
            creationBlock.push(block.number);
            staking.deposit(depositAmounts[i], lockupWeeks[i]);
            vm.stopPrank();
        }
    }
}

contract RemoteDepositStateTest is DepositState {
    uint256[] ids;
    uint256[] amounts;

    function testUpdateStake_ShouldUpdateStake(
        uint128 amount,
        uint128 debt,
        uint256 end
    ) public {
        vm.prank(admin);
        stakingShare.updateStake(1, uint256(amount), uint256(debt), end);
        StakingShare.Stake memory stake = stakingShare.getStake(1);
        assertEq(stake.lpAmount, amount);
        assertEq(stake.lpRewardDebt, debt);
        assertEq(stake.endBlock, end);
    }

    function testUpdateStake_ShouldRevert_IfNotMinter(
        uint128 amount,
        uint128 debt,
        uint256 end
    ) public {
        vm.expectRevert("Governance token: not minter");
        vm.prank(secondAccount);
        stakingShare.updateStake(1, uint256(amount), uint256(debt), end);
    }

    function testUpdateStake_ShouldRevert_IfPaused(
        uint128 amount,
        uint128 debt,
        uint256 end
    ) public {
        vm.prank(admin);
        stakingShare.pause();

        vm.expectRevert("Pausable: paused");
        vm.prank(admin);
        stakingShare.updateStake(1, uint256(amount), uint256(debt), end);
    }

    function testMint_ShouldMint(
        uint128 deposited,
        uint128 debt,
        uint256 end
    ) public {
        vm.prank(admin);
        uint256 id = stakingShare.mint(
            secondAccount,
            uint256(deposited),
            uint256(debt),
            end
        );
        StakingShare.Stake memory stake = stakingShare.getStake(id);
        assertEq(stake.minter, secondAccount);
        assertEq(stake.lpAmount, deposited);
        assertEq(stake.lpRewardDebt, debt);
        assertEq(stake.endBlock, end);
        assertEq(stake.creationBlock, block.number);
    }

    function testMint_ShouldRevert_IfMintingToZeroAddress(
        uint128 deposited,
        uint128 debt,
        uint256 end
    ) public {
        vm.expectRevert("ERC1155: mint to the zero address");
        vm.prank(admin);
        stakingShare.mint(address(0), uint256(deposited), uint256(debt), end);
    }

    function testMint_ShouldRevert_IfNotMinter(
        uint128 deposited,
        uint128 debt,
        uint256 end
    ) public {
        vm.expectRevert("Governance token: not minter");
        vm.prank(secondAccount);

        stakingShare.mint(address(0), uint256(deposited), uint256(debt), end);
    }

    function testMint_ShouldRevert_IfPaused(
        uint128 deposited,
        uint128 debt,
        uint256 end
    ) public {
        vm.prank(admin);
        stakingShare.pause();

        vm.prank(admin);
        vm.expectRevert("Pausable: paused");
        stakingShare.mint(address(0), uint256(deposited), uint256(debt), end);
    }

    function testPause_ShouldPause() public {
        vm.expectEmit(true, false, false, true);
        emit Paused(admin);

        vm.prank(admin);
        staking.pause();
    }

    function testPause_ShouldRevert_IfNotPauser() public {
        vm.expectRevert("not pauser");
        vm.prank(secondAccount);
        staking.pause();
    }

    function testUnpause_ShouldUnpause() public {
        vm.prank(admin);
        staking.pause();

        vm.expectEmit(true, false, false, true);
        emit Unpaused(admin);

        vm.prank(admin);
        staking.unpause();
    }

    function testUnpause_ShouldRevert_IfNotPauser() public {
        vm.prank(admin);
        staking.pause();

        vm.expectRevert("not pauser");
        vm.prank(secondAccount);
        staking.unpause();
    }

    function testSafeTransferFrom_ShouldTransferTokenId() public {
        vm.prank(stakingMinAccount);
        stakingShare.setApprovalForAll(admin, true);

        bytes memory data;
        vm.prank(admin);
        stakingShare.safeTransferFrom(
            stakingMinAccount,
            secondAccount,
            1,
            1,
            data
        );
        ids.push(1);

        assertEq(stakingShare.holderTokens(secondAccount), ids);
    }

    function testSafeTransferFrom_ShouldRevert_IfToAddressZero() public {
        vm.prank(stakingMinAccount);
        stakingShare.setApprovalForAll(admin, true);

        vm.expectRevert("ERC1155: transfer to the zero address");
        bytes memory data;
        vm.prank(admin);
        stakingShare.safeTransferFrom(
            stakingMinAccount,
            address(0),
            1,
            1,
            data
        );
    }

    function testSafeTransferFrom_ShouldRevert_IfInsufficientBalance() public {
        vm.prank(fifthAccount);
        stakingShare.setApprovalForAll(admin, true);

        vm.expectRevert("ERC1155: insufficient balance for transfer");
        bytes memory data;
        vm.prank(admin);
        stakingShare.safeTransferFrom(fifthAccount, secondAccount, 1, 1, data);
    }

    function testSafeTransferFrom_ShouldRevert_IfPaused() public {
        vm.prank(admin);
        stakingShare.pause();

        vm.expectRevert("Pausable: paused");
        vm.prank(admin);
        bytes memory data;
        stakingShare.safeTransferFrom(
            stakingMinAccount,
            secondAccount,
            1,
            1,
            data
        );
    }

    function testSafeBatchTransferFrom_ShouldTransferTokenIds() public {
        ids.push(3);
        ids.push(4);
        amounts.push(1);
        amounts.push(1);

        vm.prank(stakingMaxAccount);
        stakingShare.setApprovalForAll(admin, true);

        bytes memory data;

        vm.prank(admin);
        stakingShare.safeBatchTransferFrom(
            stakingMaxAccount,
            secondAccount,
            ids,
            amounts,
            data
        );
        assertEq(stakingShare.holderTokens(secondAccount), ids);
    }

    function testSafeBatchTransferFrom_ShouldRevert_IfPaused() public {
        vm.prank(admin);
        stakingShare.pause();

        vm.expectRevert("Pausable: paused");
        bytes memory data;
        vm.prank(admin);
        stakingShare.safeBatchTransferFrom(
            stakingMaxAccount,
            secondAccount,
            ids,
            amounts,
            data
        );
    }

    function testTotalSupply_ShouldReturn_TotalSupply() public {
        assertEq(stakingShare.totalSupply(), 4);
    }

    function testGetStake_ShouldReturnStake() public {
        StakingShare.Stake memory stake = StakingShare.Stake(
            fourthAccount,
            fourthBal,
            creationBlock[1],
            ubiquityFormulas.durationMultiply(
                fourthBal,
                52,
                staking.stakingDiscountMultiplier()
            ),
            staking.blockCountInAWeek() * 52,
            fourthBal
        );

        StakingShare.Stake memory stake_ = stakingShare.getStake(2);
        bytes32 stake1 = bytes32(abi.encode(stake));
        bytes32 stake2 = bytes32(abi.encode(stake_));
        assertEq(stake1, stake2);
    }

    function testHolderTokens_ShouldReturnHolderTokens() public {
        ids.push(1);
        uint256[] memory ids_ = stakingShare.holderTokens(stakingMinAccount);
        assertEq(ids, ids_);
    }

    function testSetUri_ShouldSetUri() public {
        string memory stringTest = "{'name':'Bonding Share','description':,"
        "'Ubiquity Bonding Share V2',"
        "'image': 'https://bafybeifibz4fhk4yag5reupmgh5cdbm2oladke4zfd7ldyw7avgipocpmy.ipfs.infura-ipfs.io/'}";
        vm.prank(admin);
        stakingShare.setBaseUri(stringTest);
        assertEq(
            stakingShare.uri(1),
            stringTest,
            "the uri is not set correctly by the method"
        );
    }

    function testSetUri_ShouldRevert_IfGovernanceTokenNotStakingManager()
        public
    {
        string memory stringTest = "{'a parsed json':'value'}";
        vm.expectRevert("Governance token: not staking manager");
        vm.prank(fifthAccount);
        stakingShare.setUri(1, stringTest);
    }
}
