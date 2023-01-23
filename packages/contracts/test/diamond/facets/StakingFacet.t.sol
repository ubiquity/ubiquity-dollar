// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {IMetaPool} from "../../../src/dollar/interfaces/IMetaPool.sol";
import {MockMetaPool} from "../../../src/dollar/mocks/MockMetaPool.sol";
import "../DiamondTestSetup.sol";
import {StakingShareForDiamond} from "../../../src/diamond/token/StakingShareForDiamond.sol";
import {BondingShareForDiamond} from "../../../src/diamond/mocks/MockShareV1.sol";
import {IERC20Ubiquity} from "../../../src/dollar/interfaces/IERC20Ubiquity.sol";
import {CreditRedemptionCalculator} from "../../../src/dollar/core/CreditRedemptionCalculator.sol";
import {ICurveFactory} from "../../../src/dollar/interfaces/ICurveFactory.sol";

import {CreditNFTRedemptionCalculator} from "../../../src/dollar/core/CreditNFTRedemptionCalculator.sol";
import {DollarMintCalculator} from "../../../src/dollar/core/DollarMintCalculator.sol";
import {MockCreditNFT} from "../../../src/dollar/mocks/MockCreditNFT.sol";
import {CreditNFTManager} from "../../../src/dollar/core/CreditNFTManager.sol";
import {UbiquityCreditTokenForDiamond} from "../../../src/diamond/token/UbiquityCreditTokenForDiamond.sol";
import {DollarMintExcess} from "../../../src/dollar/core/DollarMintExcess.sol";
import "../../../src/diamond/libraries/Constants.sol";
import "forge-std/console.sol";

contract ZeroState is DiamondSetup {
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
        address indexed user,
        uint256 amount,
        uint256 indexed stakingShareId
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

    function setUp() public virtual override {
        super.setUp();
        metaPoolAddress = address(
            new MockMetaPool(address(IDollarFacet), curve3CrvToken)
        );

        console.log(
            "setUp0 admin:%s owner:%s  metaPoolAddress:%s",
            admin,
            owner,
            metaPoolAddress
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
        console.log(
            "/// consult diams:%s crv:%s",
            ITWAPOracleDollar3pool.consult(address(diamond)),
            ITWAPOracleDollar3pool.consult(address(curve3CrvToken))
        );
        console.log(
            "/// address diams:%s crv:%s",
            address(diamond),
            address(curve3CrvToken)
        );

        CreditRedemptionCalculator creditRedemptionCalc = new CreditRedemptionCalculator(
                address(diamond)
            );
        vm.startPrank(admin);
        IManager.setCreditCalculatorAddress(address(creditRedemptionCalc));
        CreditNFTRedemptionCalculator creditNFTRedemptionCalc = new CreditNFTRedemptionCalculator(
                address(IManager)
            );
        IManager.setCreditNFTCalculatorAddress(
            address(creditNFTRedemptionCalc)
        );

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
        console.log("setUp3.24");
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

contract ZeroStateTest is ZeroState {
    function testSetGovernancePerBlock(uint256 governancePerBlock) public {
        vm.expectEmit(true, false, false, true, address(IUbiquityChefFacet));
        emit GovernancePerBlockModified(governancePerBlock);
        vm.prank(admin);
        IUbiquityChefFacet.setGovernancePerBlock(governancePerBlock);
        assertEq(IUbiquityChefFacet.governancePerBlock(), governancePerBlock);
    }

    function testSetGovernanceDiv(uint256 div) public {
        vm.prank(admin);
        IUbiquityChefFacet.setGovernanceShareForTreasury(div);
        assertEq(IUbiquityChefFacet.governanceDivider(), div);
    }

    function testSetMinPriceDiff(uint256 minPriceDiff) public {
        vm.expectEmit(true, false, false, true, address(IUbiquityChefFacet));
        emit MinPriceDiffToUpdateMultiplierModified(minPriceDiff);
        vm.prank(admin);
        IUbiquityChefFacet.setMinPriceDiffToUpdateMultiplier(minPriceDiff);
        assertEq(
            IUbiquityChefFacet.minPriceDiffToUpdateMultiplier(),
            minPriceDiff
        );
    }

    function testDepositFromZeroState(uint256 lpAmount) public {
        uint256 LPBalance = metapool.balanceOf(fourthAccount);
        lpAmount = bound(lpAmount, 1, LPBalance);
        // lock for 10 weeks
        uint256 shares = IStakingFormulasFacet.durationMultiply(
            lpAmount,
            10,
            IStakingFacet.stakingDiscountMultiplier()
        );
        console.log(
            "--test durationMultiply lpAmount:%s stakingDiscountMultiplier:%s shares:%s",
            lpAmount,
            IStakingFacet.stakingDiscountMultiplier(),
            shares
        );
        /*  vm.startPrank(admin);
        uint256 id = stakingShare.mint(
            fourthAccount,
            lpAmount,
            shares,
            block.number + 100
        );

        vm.stopPrank(); */
        uint256 id = stakingShare.totalSupply() + 1;
        // vm.expectEmit(true, false, true, true, address(IUbiquityChefFacet));
        // emit Deposit(fourthAccount, shares, id);

        uint256 allowance = metapool.allowance(
            fourthAccount,
            address(IUbiquityChefFacet)
        );
        console.log(
            "testDeposit bal:%s allowance:%s lpAmount:%s",
            LPBalance,
            allowance,
            lpAmount
        );

        uint256 fourthBalance = metapool.balanceOf(fourthAccount);
        console.log(" four balance", fourthBalance);

        vm.prank(fourthAccount);
        metapool.approve(address(diamond), fourthBalance);
        allowance = metapool.allowance(
            fourthAccount,
            address(IUbiquityChefFacet)
        );
        console.log(
            "testDeposit shares:%s id:%s allowance:%s ",
            shares,
            id,
            allowance
        );

        vm.expectEmit(true, true, true, true, address(IUbiquityChefFacet));

        emit Deposit(fourthAccount, shares, id);
        console.log(
            "testDeposit emit Deposit 2  fourthAccount:%s shares:%s id:%s",
            fourthAccount,
            shares,
            id
        );
        vm.prank(fourthAccount);
        IStakingFacet.deposit(lpAmount, 10);

        (, uint256 accGovernance) = IUbiquityChefFacet.pool();
        uint256[2] memory info1 = [shares, (shares * accGovernance) / 1e12];
        uint256[2] memory info2 = IUbiquityChefFacet.getStakingShareInfo(id);
        console.log("testDeposit info1-0: %s -1: %s ", info1[0], info1[1]);
        console.log("testDeposit info2-0: %s -1: %s ", info2[0], info2[1]);
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
        console.log(
            "****.0 IUbiquityChefFacet.totalShares():%s shares:%s",
            IUbiquityChefFacet.totalShares(),
            shares
        );
        assertEq(IUbiquityChefFacet.totalShares(), 0);
        console.log("DepositStatesetUp 1");
        fourthBal = metapool.balanceOf(fourthAccount);
        console.log("DepositStatesetUp 2");
        shares = IStakingFormulasFacet.durationMultiply(
            fourthBal,
            1,
            IStakingFacet.stakingDiscountMultiplier()
        );
        console.log("****.01 CALCULATED shares:%s", shares);
        console.log("DepositStatesetUp 3");
        vm.startPrank(admin);
        fourthID = stakingShare.totalSupply() + 1;
        vm.stopPrank();
        console.log("DepositStatesetUp 4 fourthID:%s", fourthID);
        vm.startPrank(fourthAccount);
        metapool.approve(address(diamond), fourthBal);
        IStakingFacet.deposit(fourthBal, 1);

        assertEq(stakingShare.totalSupply(), fourthID);
        assertEq(stakingShare.balanceOf(fourthAccount, fourthID), 1);
        console.log(
            "****.01 stakingShare totalSupply:%s balanceOf(fourthAccount,%s):%s",
            stakingShare.totalSupply(),
            fourthID,
            stakingShare.balanceOf(fourthAccount, fourthID)
        );
        console.log(
            "****.01 stakingShare address:%s from manager:%s",
            address(stakingShare),
            IManager.stakingShareAddress()
        );
        console.log(
            "****.01 ACTUAL shares:%s",
            IUbiquityChefFacet.totalShares()
        );
        vm.stopPrank();
    }
}

contract DepositStateTest is DepositState {
    function testTotalShares() public {
        assertEq(IUbiquityChefFacet.totalShares(), shares);
    }

    function testRemoveLiquidity(uint256 amount, uint256 blocks) public {
        console.log("****1 shares:%s", shares);
        assertEq(IUbiquityChefFacet.totalShares(), shares);

        // advance the block number to  staking time so the withdraw is possible
        uint256 currentBlock = block.number;
        blocks = bound(blocks, 45361, 2**128 - 1);
        //  vm.roll(currentBlock + blocks);
        console.log("****2 shares:%s", shares);
        assertEq(IUbiquityChefFacet.totalShares(), shares);

        uint256 preBal = governanceToken.balanceOf(fourthAccount);
        (uint256 lastRewardBlock, ) = IUbiquityChefFacet.pool();
        // currentBlock = block.number;
        vm.roll(currentBlock + blocks);
        uint256 multiplier = (block.number - lastRewardBlock) * 1e18;
        uint256 governancePerBlock = 10e18;
        uint256 reward = ((multiplier * governancePerBlock) / 1e18);
        uint256 governancePerShare = (reward * 1e12) / shares;
        console.log(
            "****3 shares:%s governancePerShare:%s multiplier:%s",
            shares,
            governancePerShare,
            multiplier
        );
        assertEq(IUbiquityChefFacet.totalShares(), shares);
        // we have to bound the amount of LP token to withdraw to max what account four has deposited
        amount = bound(amount, 1, fourthBal);
        console.log("****4 shares:%s", shares);
        assertEq(IUbiquityChefFacet.totalShares(), shares);

        // calculate the reward in governance token for the user based on all his shares
        uint256 userReward = (shares * governancePerShare) / 1e12;
        console.log(
            "Governance Reward to User is:%s  for shares:%s",
            userReward,
            shares
        );
        // vm.expectEmit(true, true, true, true, address(IUbiquityChefFacet));
        // emit Withdraw(fourthAccount, amount, fourthID);
        vm.prank(fourthAccount);
        console.log(
            "removeLiquidity fourthAccount:%s fourthID:%s amount:%s",
            fourthAccount,
            fourthID,
            amount
        );
        IStakingFacet.removeLiquidity(amount, fourthID);
        console.log(
            "Governance bal:%s , preBal:%s userReward:%s",
            governanceToken.balanceOf(fourthAccount),
            preBal,
            userReward
        );
        assertEq(preBal + userReward, governanceToken.balanceOf(fourthAccount));
    }

    function testGetRewards(uint256 blocks) public {
        blocks = bound(blocks, 1, 2**128 - 1);

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
        blocks = bound(blocks, 1, 2**128 - 1);

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
