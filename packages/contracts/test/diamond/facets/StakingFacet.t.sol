// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {IMetaPool} from "../../../src/dollar/interfaces/IMetaPool.sol";
import {MockMetaPool} from "../../../src/dollar/mocks/MockMetaPool.sol";
import "../DiamondTestSetup.sol";
import {StakingShareForDiamond} from "../../../src/diamond/token/StakingShareForDiamond.sol";
import {BondingShareForDiamond} from "../../../src/diamond/mocks/MockShareV1.sol";
import {IERC20Ubiquity} from "../../../src/dollar/interfaces/IERC20Ubiquity.sol";
import {ICurveFactory} from "../../../src/dollar/interfaces/ICurveFactory.sol";

import {DollarMintCalculator} from "../../../src/dollar/core/DollarMintCalculator.sol";
import {MockCreditNFT} from "../../../src/dollar/mocks/MockCreditNFT.sol";
import {CreditNFTManager} from "../../../src/dollar/core/CreditNFTManager.sol";
import {UbiquityCreditTokenForDiamond} from "../../../src/diamond/token/UbiquityCreditTokenForDiamond.sol";
import {DollarMintExcess} from "../../../src/dollar/core/DollarMintExcess.sol";
import "../../../src/diamond/libraries/Constants.sol";

contract ZeroStateStaking is DiamondSetup {
    ICurveFactory curvePoolFactory =
        ICurveFactory(0x0959158b6040D32d04c301A72CBFD6b39E21c9AE);
    IERC20 crvToken = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
    uint256 creditNFTLengthBlocks = 100;
    address treasury = address(0x3);
    address secondAccount = address(0x4);
    address thirdAccount = address(0x5);
    address fourthAccount = address(0x6);
    address fifthAccount = address(0x7);
    address stakingZeroAccount = address(0x8);
    address stakingMinAccount = address(0x9);
    address stakingMaxAccount = address(0x10);

    address curve3CrvBasePool = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address curveWhaleAddress = 0x4486083589A063ddEF47EE2E4467B5236C508fDe;
    address curve3CrvToken = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    string uri =
        "https://bafybeifibz4fhk4yag5reupmgh5cdbm2oladke4zfd7ldyw7avgipocpmy.ipfs.infura-ipfs.io/";
    StakingShareForDiamond stakingShare;
    BondingShareForDiamond stakingShareV1;
    IERC20Ubiquity governanceToken;
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
        metaPoolAddress = address(
            new MockMetaPool(address(IDollarFacet), curve3CrvToken)
        );

        vm.startPrank(owner);

        ITWAPOracleDollar3pool.setPool(metaPoolAddress, curve3CrvToken);

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
            deal(address(diamond), mintings[i], 10000e18);
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
            vm.prank(curveWhaleAddress);
            crvToken.transfer(crvDeal[i], 10000e18);
        }

        vm.startPrank(admin);
        stakingShareV1 = new BondingShareForDiamond(address(diamond));
        IManager.setStakingShareAddress(address(stakingShareV1));
        stakingShareV1.setApprovalForAll(address(diamond), true);
        IAccessCtrl.grantRole(
            GOVERNANCE_TOKEN_MINTER_ROLE,
            address(stakingShareV1)
        );
        governanceToken = IERC20Ubiquity(IManager.governanceTokenAddress());
        //  vm.stopPrank();

        //vm.prank(admin);
        IManager.deployStableSwapPool(
            address(curvePoolFactory),
            curve3CrvBasePool,
            curve3CrvToken,
            10,
            50000000
        );
        //
        metapool = IMetaPool(IManager.stableSwapMetaPoolAddress());
        metapool.transfer(address(IStakingFacet), 100e18);
        metapool.transfer(secondAccount, 1000e18);
        vm.stopPrank();
        vm.prank(owner);
        ITWAPOracleDollar3pool.setPool(address(metapool), curve3CrvToken);

        vm.startPrank(admin);

        DollarMintCalculator dollarMintCalc = new DollarMintCalculator(
            address(IManager)
        );
        IManager.setDollarMintCalculatorAddress(address(dollarMintCalc));
        CreditNFTManager creditNFTManager = new CreditNFTManager(
            address(IManager),
            creditNFTLengthBlocks
        );
        IAccessCtrl.grantRole(GOVERNANCE_TOKEN_MANAGER_ROLE, admin);
        IAccessCtrl.grantRole(
            CREDIT_NFT_MANAGER_ROLE,
            address(creditNFTManager)
        );
        IAccessCtrl.grantRole(
            GOVERNANCE_TOKEN_MINTER_ROLE,
            address(creditNFTManager)
        );

        IAccessCtrl.grantRole(
            GOVERNANCE_TOKEN_BURNER_ROLE,
            address(creditNFTManager)
        );
        UbiquityCreditTokenForDiamond creditToken = new UbiquityCreditTokenForDiamond(
                address(IManager)
            );
        IManager.setCreditTokenAddress(address(creditToken));
        DollarMintExcess dollarMintExcess = new DollarMintExcess(
            address(IManager)
        );
        IManager.setExcessDollarsDistributor(
            address(creditNFTManager),
            address(dollarMintExcess)
        );
        vm.stopPrank();

        vm.startPrank(stakingMinAccount);
        IDollarFacet.approve(address(metapool), 10000e18);
        crvToken.approve(address(metapool), 10000e18);
        vm.stopPrank();

        vm.startPrank(stakingMaxAccount);
        IDollarFacet.approve(address(metapool), 10000e18);
        crvToken.approve(address(metapool), 10000e18);
        vm.stopPrank();
        vm.startPrank(fourthAccount);
        IDollarFacet.approve(address(metapool), 10000e18);
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

        ///uint256 bondingMinBal = metapool.balanceOf(stakingMinAccount);
        ///uint256 bondingMaxBal = metapool.balanceOf(stakingMaxAccount);

        vm.startPrank(admin);
        stakingShare = new StakingShareForDiamond(address(diamond), uri);
        IManager.setStakingShareAddress(address(stakingShare));
        IAccessCtrl.grantRole(GOVERNANCE_TOKEN_MINTER_ROLE, address(diamond));
        IStakingFacet.setBlockCountInAWeek(420);

        vm.stopPrank();

        vm.prank(secondAccount);
        stakingShareV1.setApprovalForAll(address(diamond), true);

        vm.prank(thirdAccount);
        stakingShareV1.setApprovalForAll(address(diamond), true);
    }
}

contract ZeroStateStakingTest is ZeroStateStaking {
    using stdStorage for StdStorage;

    function testSetStakingDiscountMultiplier(uint256 x) public {
        vm.expectEmit(true, false, false, true);
        emit StakingDiscountMultiplierUpdated(x);
        vm.prank(admin);
        IStakingFacet.setStakingDiscountMultiplier(x);
        assertEq(x, IStakingFacet.stakingDiscountMultiplier());
    }

    function testSetBlockCountInAWeek(uint256 x) public {
        vm.expectEmit(true, false, false, true);
        emit BlockCountInAWeekUpdated(x);
        vm.prank(admin);
        IStakingFacet.setBlockCountInAWeek(x);
        assertEq(x, IStakingFacet.blockCountInAWeek());
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
            IStakingFormulasFacet.durationMultiply(
                lpAmount,
                lockup,
                IStakingFacet.stakingDiscountMultiplier()
            ),
            lockup,
            (block.number + lockup * IStakingFacet.blockCountInAWeek())
        );
        vm.startPrank(stakingMinAccount);
        metapool.approve(address(IStakingFacet), 2 ** 256 - 1);
        IStakingFacet.deposit(lpAmount, lockup);
        assertEq(metapool.balanceOf(stakingMinAccount), preBalance - lpAmount);
    }

    function testLockupMultiplier() public {
        uint256 minLP = metapool.balanceOf(stakingMinAccount);
        uint256 maxLP = metapool.balanceOf(stakingMaxAccount);

        vm.startPrank(stakingMaxAccount);
        metapool.approve(address(IStakingFacet), 2 ** 256 - 1);
        IStakingFacet.deposit(maxLP, 208);
        vm.stopPrank();

        vm.startPrank(stakingMinAccount);
        metapool.approve(address(IStakingFacet), 2 ** 256 - 1);
        IStakingFacet.deposit(minLP, 1);
        vm.stopPrank();

        uint256[2] memory bsMaxAmount = IUbiquityChefFacet.getStakingShareInfo(
            1
        );
        uint256[2] memory bsMinAmount = IUbiquityChefFacet.getStakingShareInfo(
            2
        );

        assertLt(bsMinAmount[0], bsMaxAmount[0]);
    }

    function testCannotStakeMoreThan4Years(uint256 _weeks) public {
        _weeks = bound(_weeks, 209, 2 ** 256 - 1);
        vm.expectRevert("Staking: duration must be between 1 and 208 weeks");
        vm.prank(fourthAccount);
        IStakingFacet.deposit(1, _weeks);
    }

    function testCannotDepositZeroWeeks() public {
        vm.expectRevert("Staking: duration must be between 1 and 208 weeks");
        vm.prank(fourthAccount);
        IStakingFacet.deposit(1, 0);
    }
}

contract DepositStateStaking is ZeroStateStaking {
    uint256 fourthBal;
    uint256 fourthID;
    uint256 shares;

    function setUp() public virtual override {
        super.setUp();

        assertEq(IUbiquityChefFacet.totalShares(), 0);
        fourthBal = metapool.balanceOf(fourthAccount);
        shares = IStakingFormulasFacet.durationMultiply(
            fourthBal,
            1,
            IStakingFacet.stakingDiscountMultiplier()
        );
        vm.startPrank(admin);
        fourthID = stakingShare.totalSupply() + 1;
        vm.stopPrank();
        vm.startPrank(fourthAccount);
        metapool.approve(address(diamond), fourthBal);
        IStakingFacet.deposit(fourthBal, 1);

        assertEq(stakingShare.totalSupply(), fourthID);
        assertEq(stakingShare.balanceOf(fourthAccount, fourthID), 1);

        vm.stopPrank();
    }
}

contract DepositStateTest is DepositStateStaking {
    function testTotalShares() public {
        assertEq(IUbiquityChefFacet.totalShares(), shares);
    }

    function testRemoveLiquidity(uint256 amount, uint256 blocks) public {
        assertEq(IUbiquityChefFacet.totalShares(), shares);

        // advance the block number to  staking time so the withdraw is possible
        uint256 currentBlock = block.number;
        blocks = bound(blocks, 45361, 2 ** 128 - 1);
        assertEq(IUbiquityChefFacet.totalShares(), shares);

        uint256 preBal = governanceToken.balanceOf(fourthAccount);
        (uint256 lastRewardBlock, ) = IUbiquityChefFacet.pool();
        vm.roll(currentBlock + blocks);
        uint256 multiplier = (block.number - lastRewardBlock) * 1e18;
        uint256 governancePerBlock = 10e18;
        uint256 reward = ((multiplier * governancePerBlock) / 1e18);
        uint256 governancePerShare = (reward * 1e12) / shares;
        assertEq(IUbiquityChefFacet.totalShares(), shares);
        // we have to bound the amount of LP token to withdraw to max what account four has deposited
        amount = bound(amount, 1, fourthBal);
        assertEq(IUbiquityChefFacet.totalShares(), shares);

        // calculate the reward in governance token for the user based on all his shares
        uint256 userReward = (shares * governancePerShare) / 1e12;

        vm.prank(fourthAccount);
        IStakingFacet.removeLiquidity(amount, fourthID);

        assertEq(preBal + userReward, governanceToken.balanceOf(fourthAccount));
    }

    function testGetRewards(uint256 blocks) public {
        blocks = bound(blocks, 1, 2 ** 128 - 1);

        (uint256 lastRewardBlock, ) = IUbiquityChefFacet.pool();
        uint256 currentBlock = block.number;
        vm.roll(currentBlock + blocks);
        uint256 multiplier = (block.number - lastRewardBlock) * 1e18;
        uint256 reward = ((multiplier * 10e18) / 1e18);
        uint256 governancePerShare = (reward * 1e12) / shares;
        uint256 userReward = (shares * governancePerShare) / 1e12;
        vm.prank(fourthAccount);
        uint256 rewardSent = IUbiquityChefFacet.getRewards(1);
        assertEq(userReward, rewardSent);
    }

    function testCannotGetRewardsOtherAccount() public {
        vm.expectRevert("MS: caller is not owner");
        vm.prank(stakingMinAccount);
        IUbiquityChefFacet.getRewards(1);
    }

    function testPendingGovernance(uint256 blocks) public {
        blocks = bound(blocks, 1, 2 ** 128 - 1);

        (uint256 lastRewardBlock, ) = IUbiquityChefFacet.pool();
        uint256 currentBlock = block.number;
        vm.roll(currentBlock + blocks);
        uint256 multiplier = (block.number - lastRewardBlock) * 1e18;
        uint256 reward = ((multiplier * 10e18) / 1e18);
        uint256 governancePerShare = (reward * 1e12) / shares;
        uint256 userPending = (shares * governancePerShare) / 1e12;

        uint256 pendingGovernance = IUbiquityChefFacet.pendingGovernance(1);
        assertEq(userPending, pendingGovernance);
    }

    function testGetStakingShareInfo() public {
        uint256[2] memory info1 = [shares, 0];
        uint256[2] memory info2 = IUbiquityChefFacet.getStakingShareInfo(1);
        assertEq(info1[0], info2[0]);
        assertEq(info1[1], info2[1]);
    }
}
