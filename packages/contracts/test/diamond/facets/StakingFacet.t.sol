// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IMetaPool} from "../../../src/dollar/interfaces/IMetaPool.sol";
import {MockMetaPool} from "../../../src/dollar/mocks/MockMetaPool.sol";
import "../DiamondTestSetup.sol";
import {StakingShare} from "../../../src/dollar/core/StakingShare.sol";
import {BondingShare} from "../../../src/dollar/mocks/MockShareV1.sol";
import {IERC20Ubiquity} from "../../../src/dollar/interfaces/IERC20Ubiquity.sol";
import {ICurveFactory} from "../../../src/dollar/interfaces/ICurveFactory.sol";

import {DollarMintCalculatorFacet} from "../../../src/dollar/facets/DollarMintCalculatorFacet.sol";
import {CreditNftManagerFacet} from "../../../src/dollar/facets/CreditNftManagerFacet.sol";
import {UbiquityCreditToken} from "../../../src/dollar/core/UbiquityCreditToken.sol";
import {DollarMintExcessFacet} from "../../../src/dollar/facets/DollarMintExcessFacet.sol";
import "../../../src/dollar/libraries/Constants.sol";
import {MockCurveFactory} from "../../../src/dollar/mocks/MockCurveFactory.sol";
import {MockERC20} from "../../../src/dollar/mocks/MockERC20.sol";
import "forge-std/Test.sol";

contract ZeroStateStaking is DiamondTestSetup {
    MockERC20 crvToken;
    uint256 creditNftLengthBlocks = 100;
    address treasury = address(0x3);
    address secondAccount = address(0x4);
    address thirdAccount = address(0x5);
    address fourthAccount = address(0x6);
    address fifthAccount = address(0x7);
    address stakingZeroAccount = address(0x8);
    address stakingMinAccount = address(0x9);
    address stakingMaxAccount = address(0x10);

    string uri =
        "https://bafybeifibz4fhk4yag5reupmgh5cdbm2oladke4zfd7ldyw7avgipocpmy.ipfs.infura-ipfs.io/";

    event Deposit(
        address indexed _user,
        uint256 indexed _id,
        uint256 _lpAmount,
        uint256 _stakingShareAmount,
        uint256 _weeks,
        uint256 _endBlock
    );

    event Withdraw(
        address indexed user,
        uint256 amount,
        uint256 indexed stakingShareId
    );

    IMetaPool metapool;
    address metaPoolAddress;

    event GovernancePerBlockModified(uint256 indexed governancePerBlock);

    event MinPriceDiffToUpdateMultiplierModified(
        uint256 indexed minPriceDiffToUpdateMultiplier
    );
    event BlockCountInAWeekUpdated(uint256 _blockCountInAWeek);
    event StakingDiscountMultiplierUpdated(uint256 _stakingDiscountMultiplier);

    function setUp() public virtual override {
        super.setUp();
        crvToken = new MockERC20("3 CRV", "3CRV", 18);
        metaPoolAddress = address(
            new MockMetaPool(address(dollarToken), address(crvToken))
        );

        vm.startPrank(owner);

        twapOracleDollar3PoolFacet.setPool(metaPoolAddress, address(crvToken));

        address[7] memory mintings = [
            admin,
            address(diamond),
            owner,
            fourthAccount,
            stakingZeroAccount,
            stakingMinAccount,
            stakingMaxAccount
        ];

        for (uint256 i = 0; i < mintings.length; ++i) {
            deal(address(dollarToken), mintings[i], 10000e18);
        }
        address[5] memory crvDeal = [
            address(diamond),
            owner,
            stakingMaxAccount,
            stakingMinAccount,
            fourthAccount
        ];
        vm.stopPrank();
        for (uint256 i; i < crvDeal.length; ++i) {
            crvToken.mint(crvDeal[i], 10000e18);
        }

        vm.startPrank(admin);
        stakingShare.setApprovalForAll(address(diamond), true);
        accessControlFacet.grantRole(
            GOVERNANCE_TOKEN_MINTER_ROLE,
            address(stakingShare)
        );

        ICurveFactory curvePoolFactory = ICurveFactory(new MockCurveFactory());
        address curve3CrvBasePool = address(
            new MockMetaPool(address(diamond), address(crvToken))
        );

        //vm.prank(admin);
        managerFacet.deployStableSwapPool(
            address(curvePoolFactory),
            curve3CrvBasePool,
            address(crvToken),
            10,
            50000000
        );
        //
        metapool = IMetaPool(managerFacet.stableSwapMetaPoolAddress());
        metapool.transfer(address(stakingFacet), 100e18);
        metapool.transfer(secondAccount, 1000e18);
        vm.stopPrank();
        vm.prank(owner);
        twapOracleDollar3PoolFacet.setPool(
            address(metapool),
            address(crvToken)
        );

        vm.startPrank(admin);

        accessControlFacet.grantRole(GOVERNANCE_TOKEN_MANAGER_ROLE, admin);
        accessControlFacet.grantRole(CREDIT_NFT_MANAGER_ROLE, address(diamond));
        accessControlFacet.grantRole(
            GOVERNANCE_TOKEN_MINTER_ROLE,
            address(diamond)
        );

        accessControlFacet.grantRole(
            GOVERNANCE_TOKEN_BURNER_ROLE,
            address(diamond)
        );
        managerFacet.setCreditTokenAddress(address(creditToken));

        vm.stopPrank();

        vm.startPrank(stakingMinAccount);
        dollarToken.approve(address(metapool), 10000e18);
        crvToken.approve(address(metapool), 10000e18);
        vm.stopPrank();

        vm.startPrank(stakingMaxAccount);
        dollarToken.approve(address(metapool), 10000e18);
        crvToken.approve(address(metapool), 10000e18);
        vm.stopPrank();
        vm.startPrank(fourthAccount);
        dollarToken.approve(address(metapool), 10000e18);
        crvToken.approve(address(metapool), 10000e18);
        vm.stopPrank();

        uint256[2] memory amounts_ = [uint256(100e18), uint256(100e18)];

        uint256 dyuAD2LP = metapool.calc_token_amount(amounts_, true);

        vm.prank(stakingMinAccount);
        metapool.add_liquidity(
            amounts_,
            (dyuAD2LP * 99) / 100,
            stakingMinAccount
        );

        vm.prank(stakingMaxAccount);
        metapool.add_liquidity(
            amounts_,
            (dyuAD2LP * 99) / 100,
            stakingMaxAccount
        );

        vm.prank(fourthAccount);
        metapool.add_liquidity(amounts_, (dyuAD2LP * 99) / 100, fourthAccount);

        vm.startPrank(admin);
        accessControlFacet.grantRole(
            GOVERNANCE_TOKEN_MINTER_ROLE,
            address(diamond)
        );
        stakingFacet.setBlockCountInAWeek(420);

        vm.stopPrank();

        vm.prank(secondAccount);
        stakingShare.setApprovalForAll(address(diamond), true);

        vm.prank(thirdAccount);
        stakingShare.setApprovalForAll(address(diamond), true);
    }
}

contract ZeroStateStakingTest is ZeroStateStaking {
    using stdStorage for StdStorage;

    function testSetStakingDiscountMultiplier(uint256 x) public {
        vm.expectEmit(true, false, false, true);
        emit StakingDiscountMultiplierUpdated(x);
        vm.prank(admin);
        stakingFacet.setStakingDiscountMultiplier(x);
        assertEq(x, stakingFacet.stakingDiscountMultiplier());
    }

    function testSetBlockCountInAWeek(uint256 x) public {
        vm.expectEmit(true, false, false, true);
        emit BlockCountInAWeekUpdated(x);
        vm.prank(admin);
        stakingFacet.setBlockCountInAWeek(x);
        assertEq(x, stakingFacet.blockCountInAWeek());
    }

    function testDeposit_Staking(uint256 lpAmount, uint256 lockup) public {
        lpAmount = bound(lpAmount, 1, metapool.balanceOf(stakingMinAccount));
        lockup = bound(lockup, 1, 208);
        require(lpAmount >= 1 && lpAmount <= 100e18);
        require(lockup >= 1 && lockup <= 208);
        uint256 preBalance = metapool.balanceOf(stakingMinAccount);
        vm.startPrank(stakingMinAccount);
        metapool.approve(address(stakingFacet), 2 ** 256 - 1);
        vm.expectEmit(true, false, false, true);
        emit Deposit(
            stakingMinAccount,
            stakingShare.totalSupply(),
            lpAmount,
            stakingFormulasFacet.durationMultiply(
                lpAmount,
                lockup,
                stakingFacet.stakingDiscountMultiplier()
            ),
            lockup,
            (block.number + lockup * stakingFacet.blockCountInAWeek())
        );
        stakingFacet.deposit(lpAmount, lockup);
        assertEq(metapool.balanceOf(stakingMinAccount), preBalance - lpAmount);
    }

    function testLockupMultiplier() public {
        uint256 minLP = metapool.balanceOf(stakingMinAccount);
        uint256 maxLP = metapool.balanceOf(stakingMaxAccount);

        vm.startPrank(stakingMaxAccount);
        metapool.approve(address(stakingFacet), 2 ** 256 - 1);
        stakingFacet.deposit(maxLP, 208);
        vm.stopPrank();

        vm.startPrank(stakingMinAccount);
        metapool.approve(address(stakingFacet), 2 ** 256 - 1);
        stakingFacet.deposit(minLP, 1);
        vm.stopPrank();

        uint256[2] memory bsMaxAmount = chefFacet.getStakingShareInfo(1);
        uint256[2] memory bsMinAmount = chefFacet.getStakingShareInfo(2);

        assertLt(bsMinAmount[0], bsMaxAmount[0]);
    }

    function testCannotStakeMoreThan4Years(uint256 _weeks) public {
        _weeks = bound(_weeks, 209, 2 ** 256 - 1);
        vm.expectRevert("Staking: duration must be between 1 and 208 weeks");
        vm.prank(fourthAccount);
        stakingFacet.deposit(1, _weeks);
    }

    function testCannotDepositZeroWeeks() public {
        vm.expectRevert("Staking: duration must be between 1 and 208 weeks");
        vm.prank(fourthAccount);
        stakingFacet.deposit(1, 0);
    }
}

contract DepositStateStaking is ZeroStateStaking {
    uint256 fourthBal;
    uint256 fourthID;
    uint256 shares;

    function setUp() public virtual override {
        super.setUp();

        assertEq(chefFacet.totalShares(), 0);
        fourthBal = metapool.balanceOf(fourthAccount);
        shares = stakingFormulasFacet.durationMultiply(
            fourthBal,
            1,
            stakingFacet.stakingDiscountMultiplier()
        );
        vm.startPrank(admin);
        fourthID = stakingShare.totalSupply() + 1;
        vm.stopPrank();
        vm.startPrank(fourthAccount);
        metapool.approve(address(diamond), fourthBal);
        stakingFacet.deposit(fourthBal, 1);

        assertEq(stakingShare.totalSupply(), fourthID);
        assertEq(stakingShare.balanceOf(fourthAccount, fourthID), 1);

        vm.stopPrank();
    }
}

contract DepositStateTest is DepositStateStaking {
    function testTotalShares() public {
        assertEq(chefFacet.totalShares(), shares);
    }

    function testRemoveLiquidity(uint256 amount, uint256 blocks) public {
        assertEq(chefFacet.totalShares(), shares);

        // advance the block number to  staking time so the withdraw is possible
        uint256 currentBlock = block.number;
        blocks = bound(blocks, 45361, 2 ** 128 - 1);
        assertEq(chefFacet.totalShares(), shares);

        uint256 preBal = governanceToken.balanceOf(fourthAccount);
        (uint256 lastRewardBlock, ) = chefFacet.pool();
        vm.roll(currentBlock + blocks);
        uint256 multiplier = (block.number - lastRewardBlock) * 1e18;
        uint256 governancePerBlock = 10e18;
        uint256 reward = ((multiplier * governancePerBlock) / 1e18);
        uint256 governancePerShare = (reward * 1e12) / shares;
        assertEq(chefFacet.totalShares(), shares);
        // we have to bound the amount of LP token to withdraw to max what account four has deposited
        amount = bound(amount, 1, fourthBal);
        assertEq(chefFacet.totalShares(), shares);

        // calculate the reward in governance token for the user based on all his shares
        uint256 userReward = (shares * governancePerShare) / 1e12;

        vm.prank(fourthAccount);
        stakingFacet.removeLiquidity(amount, fourthID);

        assertEq(preBal + userReward, governanceToken.balanceOf(fourthAccount));
    }

    function testGetRewards(uint256 blocks) public {
        blocks = bound(blocks, 1, 2 ** 128 - 1);

        (uint256 lastRewardBlock, ) = chefFacet.pool();
        uint256 currentBlock = block.number;
        vm.roll(currentBlock + blocks);
        uint256 multiplier = (block.number - lastRewardBlock) * 1e18;
        uint256 reward = ((multiplier * 10e18) / 1e18);
        uint256 governancePerShare = (reward * 1e12) / shares;
        uint256 userReward = (shares * governancePerShare) / 1e12;
        vm.prank(fourthAccount);
        uint256 rewardSent = chefFacet.getRewards(1);
        assertEq(userReward, rewardSent);
    }

    function testCannotGetRewardsOtherAccount() public {
        vm.expectRevert("MS: caller is not owner");
        vm.prank(stakingMinAccount);
        chefFacet.getRewards(1);
    }

    function testPendingGovernance(uint256 blocks) public {
        blocks = bound(blocks, 1, 2 ** 128 - 1);

        (uint256 lastRewardBlock, ) = chefFacet.pool();
        uint256 currentBlock = block.number;
        vm.roll(currentBlock + blocks);
        uint256 multiplier = (block.number - lastRewardBlock) * 1e18;
        uint256 reward = ((multiplier * 10e18) / 1e18);
        uint256 governancePerShare = (reward * 1e12) / shares;
        uint256 userPending = (shares * governancePerShare) / 1e12;

        uint256 pendingGovernance = chefFacet.pendingGovernance(1);
        assertEq(userPending, pendingGovernance);
    }

    function testGetStakingShareInfo() public {
        uint256[2] memory info1 = [shares, 0];
        uint256[2] memory info2 = chefFacet.getStakingShareInfo(1);
        assertEq(info1[0], info2[0]);
        assertEq(info1[1], info2[1]);
    }
}
