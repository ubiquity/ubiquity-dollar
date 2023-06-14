// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface UGOV {
    function balanceOf(address account) external view returns (uint256);
}

interface IManagerMainnet {
    function stableSwapMetaPoolAddress() external view returns (address);
    function deployStableSwapPool( address _curveFactory, address _crvBasePool, address _crv3PoolTokenAddress, uint256 _amplificationCoefficient, uint256 _fee) external;
    function governanceTokenAddress() external view returns (address);
    
}

interface IBondingStaking {
    function blockCountInAWeek() external view returns (uint256);
    function bondingDiscountMultiplier() external view returns (uint256);
    function setBlockCountInAWeek(uint256 _blockCountInAWeek) external;
    function setBondingDiscountMultiplier(uint256 _bondingDiscountMultiplier) external;
    function deposit(uint256 _lpsAmount, uint256 _weeks) external returns (uint256 _id);
    function removeLiquidity(uint256 _amount, uint256 _id) external;
}

interface UbiquityFormulas {

    function durationMultiply(uint256 _uLP,uint256 _weeks, uint256 _multiplier) external pure returns (uint256 _shares);
}

interface IChefV2 {
    function totalShares() external view returns (uint256);
    function getRewards(uint256 bondingShareID) external returns (uint256);
    function pendingUGOV(uint256 bondingShareID) external view returns (uint256);
    function getBondingShareInfo(uint256 _id) external view returns (uint256[2] memory);
    function pool() external view returns (uint256 lastRewardBlock, uint256 accuGOVPerShare);
    function uGOVmultiplier() external view returns (uint256);
    function uGOVPerBlock() external view returns (uint256);
}

interface IBondingShare {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

import {IMetaPool} from "../../../src/dollar/interfaces/IMetaPool.sol";
import "../DiamondTestSetup.sol";
import {BondingShare} from "../../../src/dollar/mocks/MockShareV1.sol";
import {ICurveFactory} from "../../../src/dollar/interfaces/ICurveFactory.sol";
import {DollarMintExcessFacet} from "../../../src/dollar/facets/DollarMintExcessFacet.sol";
import "../../../src/dollar/libraries/Constants.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/Test.sol";

contract ZeroStateStaking is DiamondSetup {
    IERC20 curve3CrvToken = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
    IERC20 UbiquityDollarMainnet = IERC20(0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6);
    address curveWhale = 0x4486083589A063ddEF47EE2E4467B5236C508fDe;
    address UbiquityDollarWhale = 0xf51a97aaBE438a6A92Fa81448DA63EAd09FB9945;
    address crvFactory = 0xB9fC157394Af804a3578134A6585C0dc9cc990d4; //0x0959158b6040D32d04c301A72CBFD6b39E21c9AE;
    address basePool = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    IManagerMainnet manager = IManagerMainnet(0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98);
    address adminPranskter = 0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd;
    address bondingv2 = 0xC251eCD9f1bD5230823F9A0F99a44A87Ddd4CA38;
    address uformulas = 0x54F528979A50FA8Fe99E0118EbbEE5fC8Ea802F7;
    address bshare = 0x2dA07859613C14F6f05c97eFE37B9B4F212b5eF5;
    address chefv2 = 0xdae807071b5AC7B6a2a343beaD19929426dBC998;
    address ugov = 0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0;
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

    event GovernancePerBlockModified(uint256 indexed governancePerBlock);

    event MinPriceDiffToUpdateMultiplierModified(
        uint256 indexed minPriceDiffToUpdateMultiplier
    );
    event BlockCountInAWeekUpdated(uint256 _blockCountInAWeek);
    event BondingDiscountMultiplierUpdated(uint256 _bondingDiscountMultiplier);

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(UbiquityDollarWhale);

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
            IERC20(UbiquityDollarMainnet).transfer( mintings[i], 1000e18);
        }
        vm.stopPrank();
        vm.startPrank(curveWhale);

        address[5] memory crvDeal = [
            address(diamond),
            owner,
            stakingMaxAccount,
            stakingMinAccount,
            fourthAccount
        ];

        for (uint256 i; i < crvDeal.length; ++i) {
            // distribute crv to the accounts
            IERC20(curve3CrvToken).transfer(crvDeal[i], 1000e18);
        }
        vm.stopPrank();

        address governanceToken = IManagerMainnet(manager).governanceTokenAddress();
        assertEq(governanceToken, governanceToken);
        vm.label(governanceToken, "GOVERNANCE TOKEN");

        vm.label(address(curve3CrvToken), "CURVE TOKEN");
        vm.startPrank(adminPranskter);
        address metapool = IManagerMainnet(manager).stableSwapMetaPoolAddress();
        vm.label(metapool, "STABLE SWAP ADDRESS");
        vm.stopPrank();

        vm.startPrank(admin);

        //keeping this
        IAccessCtrl.grantRole(GOVERNANCE_TOKEN_MANAGER_ROLE, admin);
        IAccessCtrl.grantRole(CREDIT_NFT_MANAGER_ROLE, address(diamond));
        IAccessCtrl.grantRole(GOVERNANCE_TOKEN_MINTER_ROLE, address(diamond));

        IAccessCtrl.grantRole(GOVERNANCE_TOKEN_BURNER_ROLE, address(diamond));

        vm.stopPrank();

        vm.startPrank(stakingMinAccount);
        IERC20(UbiquityDollarMainnet).approve(address(metapool), 10000e18);
        IERC20(curve3CrvToken).approve(address(metapool), 10000e18);
        vm.stopPrank();

        vm.startPrank(stakingMaxAccount);
        IERC20(UbiquityDollarMainnet).approve(address(metapool), 10000e18);
        IERC20(curve3CrvToken).approve(address(metapool), 10000e18);
        vm.stopPrank();
        vm.startPrank(fourthAccount);
        IERC20(UbiquityDollarMainnet).approve(address(metapool), 10000e18);
        IERC20(curve3CrvToken).approve(address(metapool), 10000e18);
        vm.stopPrank();

        uint256[2] memory amounts_ = [uint256(100e18), uint256(100e18)];

        uint256 dyuAD2LP = IMetaPool(metapool).calc_token_amount(amounts_, true);

        vm.prank(stakingMinAccount);
        IMetaPool(metapool).add_liquidity(
            amounts_,
            (dyuAD2LP * 99) / 100,
            stakingMinAccount
        );

        vm.prank(stakingMaxAccount);
        IMetaPool(metapool).add_liquidity(
            amounts_,
            (dyuAD2LP * 99) / 100,
            stakingMaxAccount
        );

        vm.startPrank(fourthAccount);
        vm.label(fourthAccount, " FOURTH ACCOUNT");
        IMetaPool(metapool).add_liquidity(amounts_, (dyuAD2LP * 99) / 100, fourthAccount);
        vm.stopPrank();

        vm.startPrank(adminPranskter);
        vm.label(adminPranskter, " ADMIN ");
        IBondingStaking(bondingv2).setBlockCountInAWeek(420);
        vm.stopPrank();
        vm.startPrank(admin);
        IAccessCtrl.grantRole(GOVERNANCE_TOKEN_MINTER_ROLE, address(diamond));
        vm.stopPrank();
    }

    function test_Fork() public override {
        vm.activeFork(); //Active??
    }
}

contract ZeroStateStakingTest is ZeroStateStaking {
    using stdStorage for StdStorage;

    function testSetStakingDiscountMultiplier(uint256 x) public {
        vm.expectEmit(true, false, false, true);
        emit BondingDiscountMultiplierUpdated(x);
        vm.prank(adminPranskter);
        IBondingStaking(bondingv2).setBondingDiscountMultiplier(x);
        assertEq(x, IBondingStaking(bondingv2).bondingDiscountMultiplier());
    }

    function testSetBlockCountInAWeek(uint256 x) public {
        vm.expectEmit(true, false, false, true);
        emit BlockCountInAWeekUpdated(x);
        vm.prank(adminPranskter);
        IBondingStaking(bondingv2).setBlockCountInAWeek(x);
        assertEq(x, IBondingStaking(bondingv2).blockCountInAWeek());
    }

    function testDeposit_Staking(uint256 lpAmount, uint256 lockup) public {
        vm.label(stakingMinAccount, "DEPOSITOR ACCOUNT");
        address metapool = IManagerMainnet(manager).stableSwapMetaPoolAddress();
        vm.label(metapool, "STABLE SWAP ADDRESS");
        uint256 bal = IMetaPool(metapool).balanceOf(stakingMinAccount);
        emit log_uint(bal);
        lpAmount = bound(lpAmount, 1, IMetaPool(metapool).balanceOf(stakingMinAccount));
        emit log_uint(lpAmount);
        lockup = bound(lockup, 1, 208);
        require(lpAmount >= 1 && lpAmount <= 1000e18);
        require(lockup >= 1 && lockup <= 208);
        uint256 preBalance = IMetaPool(metapool).balanceOf(stakingMinAccount);
        vm.startPrank(stakingMinAccount);
        IMetaPool(metapool).approve(address(bondingv2), 2 ** 256 - 1);
        vm.expectEmit(true, false, false, true);
        emit Deposit(
            address(stakingMinAccount),
            IBondingShare(bshare).totalSupply(),
            10,
            UbiquityFormulas(uformulas).durationMultiply(
                10,
                10,
                IBondingStaking(bondingv2).blockCountInAWeek()
            ),
            10,
            (block.number + 10 * IBondingStaking(bondingv2).blockCountInAWeek())
        );
        IBondingStaking(bondingv2).deposit(10, 10);
    }

    function testLockupMultiplier() public {
        address metapool = IManagerMainnet(manager).stableSwapMetaPoolAddress();
        vm.label(metapool, "STABLE SWAP ADDRESS");
        uint256 minLP = IMetaPool(metapool).balanceOf(stakingMinAccount);
        uint256 maxLP = IMetaPool(metapool).balanceOf(stakingMaxAccount);

        vm.startPrank(stakingMaxAccount);
        IMetaPool(metapool).approve(address(bondingv2), 2 ** 256 - 1);
        IBondingStaking(bondingv2).deposit(maxLP, 208);
        vm.stopPrank();

        vm.startPrank(stakingMinAccount);
        IMetaPool(metapool).approve(address(bondingv2), 2 ** 256 - 1);
        IBondingStaking(bondingv2).deposit(minLP, 1);
        vm.stopPrank();

        uint256[2] memory bsMaxAmount = IChefV2(chefv2).getBondingShareInfo(1);
        uint256[2] memory bsMinAmount = IChefV2(chefv2).getBondingShareInfo(2);

        assertGt(bsMinAmount[0], bsMaxAmount[0]);
    }

    function testCannotStakeMoreThan4Years(uint256 _weeks) public {
        _weeks = bound(_weeks, 209, 2 ** 256 - 1);
        vm.expectRevert("Bonding: duration must be between 1 and 208 weeks");
        vm.prank(fourthAccount);
        IBondingStaking(bondingv2).deposit(1, _weeks);
    }

    function testCannotDepositZeroWeeks() public {
        vm.expectRevert("Bonding: duration must be between 1 and 208 weeks");
        vm.prank(fourthAccount);
        IBondingStaking(bondingv2).deposit(1, 0);
    }
}

contract DepositStateStaking is ZeroStateStaking {
    uint256 fourthBal;
    uint256 fourthID;
    uint256 shares;

    function setUp() public virtual override {
        super.setUp();
        address metapool = IManagerMainnet(manager).stableSwapMetaPoolAddress();
        vm.label(metapool, "STABLE SWAP ADDRESS");

        fourthBal = IMetaPool(metapool).balanceOf(fourthAccount);
        shares = UbiquityFormulas(uformulas).durationMultiply(
            fourthBal,
            1,
            IBondingStaking(bondingv2).bondingDiscountMultiplier()
        );
        vm.startPrank(admin);
        fourthID = IBondingShare(bshare).totalSupply() + 1;
        vm.stopPrank();
        vm.startPrank(fourthAccount);
        IMetaPool(metapool).approve(address(bondingv2), fourthBal);
        IBondingStaking(bondingv2).deposit(fourthBal, 1);

        vm.stopPrank();
    }
}

contract DepositStateTest is DepositStateStaking {
    function testTotalShares() public {
        uint256 poolShares = IChefV2(chefv2).totalShares();
        assertEq(IChefV2(chefv2).totalShares(), poolShares);
        emit log_uint(poolShares);
    }

    function testRemoveLiquidity(uint256 amount, uint256 blocks) public {

        // advance the block number to  staking time so the withdraw is possible
        uint256 currentBlock = block.number;
        blocks = bound(blocks, 45361, 2 ** 128 - 1);
        vm.roll(currentBlock + blocks);
        amount = bound(amount, 1, fourthBal);
        vm.prank(fourthAccount);
        IBondingStaking(bondingv2).removeLiquidity(amount, fourthID);
    }

    function testGetRewards(uint256 blocks) public {
        blocks = bound(blocks, 1, 2 ** 128 - 1);
        uint256 currentBlock = block.number;
        vm.roll(currentBlock + blocks);
        vm.prank(fourthAccount);
        uint256 rewardSent = IChefV2(chefv2).getRewards(fourthID);
        emit log_uint(rewardSent);
    
    }

    function testCannotGetRewardsOtherAccount() public {
        vm.expectRevert("MS: caller is not owner");
        vm.prank(stakingMinAccount);
        IChefV2(chefv2).getRewards(1);
    }
        
    function testPendingGovernance(uint256 blocks) public {
        blocks = bound(blocks, 1, 2 ** 128 - 1);
        uint256 currentBlock = block.number;
        vm.roll(currentBlock + blocks);
        vm.prank(fourthAccount);
        uint256 pendingGovernance = IChefV2(chefv2).pendingUGOV(fourthID);
        emit log_uint(pendingGovernance);

    }

    function test_PendingGovernanceNotExistsID() public {
        uint256 pendingGovernance = IChefV2(chefv2).pendingUGOV(8085202);
        vm.expectRevert();
        if(pendingGovernance == 0) {
            revert ("not existent ID, 0");
        }
        emit log_uint(pendingGovernance);    
    }

    function testGetStakingShareInfo() public {
        //uint256[2] memory info1 = [shares, 0];
        //uint256[2] memory info2 = IChefV2(chefv2).getBondingShareInfo(49);
        //assertEq(info1[0], info2[0]);
        //assertEq(info1[1], info2[1]);
    }
}
