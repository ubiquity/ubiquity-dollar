// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "src/dollar/Staking.sol";
import "src/dollar/mocks/MockBondingV1.sol";
import "src/dollar/mocks/MockBondingShareV1.sol";
import "src/dollar/StakingFormulas.sol";
import "src/dollar/StakingShare.sol";
import "src/dollar/interfaces/IMetaPool.sol";
import "src/dollar/core/UbiquityGovernanceToken.sol";
import "src/dollar/core/UbiquityDollarManager.sol";
import "src/dollar/mocks/MockDollarToken.sol";
import "src/dollar/UbiquityFormulas.sol";
import "src/dollar/core/TWAPOracleDollar3pool.sol";
import "src/dollar/UbiquityChef.sol";
import "src/dollar/core/CreditRedemptionCalculator.sol";
import "src/dollar/interfaces/ICurveFactory.sol";
import "src/dollar/interfaces/IMasterChef.sol";
import "src/dollar/core/CreditNftRedemptionCalculator.sol";
import "src/dollar/core/DollarMintCalculator.sol";
import "src/dollar/mocks/MockCreditNft.sol";
import "src/dollar/core/CreditNftManager.sol";
import "src/dollar/core/UbiquityCreditToken.sol";
import "src/dollar/core/DollarMintExcess.sol";
import "src/dollar/SushiSwapPool.sol";
import "src/dollar/interfaces/IERC1155Ubiquity.sol";
import "src/dollar/BondingCurve.sol";
import "src/dollar/mocks/MockUbiquistick.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import "forge-std/Test.sol";

//cspell:disable
contract LiveTestHelper is Test {
    using stdStorage for StdStorage;

    MockBondingV1 bondingV1;
    Staking staking;
    StakingFormulas stakingFormulas;
    StakingShare stakingShare;
    BondingCurve bondingCurve;

    UbiquityDollarManager manager;

    UbiquityFormulas ubiquityFormulas;
    TWAPOracleDollar3pool twapOracle;
    UbiquityChef ubiquityChef;
    CreditRedemptionCalculator creditRedemptionCalc;
    CreditNftRedemptionCalculator creditNftRedemptionCalc;
    DollarMintCalculator dollarMintCalc;
    MockCreditNft creditNft;
    CreditNftManager creditNftManager;
    UbiquityCreditToken creditToken;
    DollarMintExcess dollarMintExcess;
    SushiSwapPool sushiGovernancePool;
    IMetaPool metapool;

    MockDollarToken dollarToken;
    UbiquityGovernanceToken governanceToken;
    MockUbiquistick ubiquiStick;

    MockBondingShareV1 bondingShareV1;

    IUniswapV2Factory factory =
        IUniswapV2Factory(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);
    IUniswapV2Router02 router =
        IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    IERC20 DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 crvToken = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
    IERC20 WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    ICurveFactory curvePoolFactory =
        ICurveFactory(0x0959158b6040D32d04c301A72CBFD6b39E21c9AE);

    address admin = address(0x1);
    address treasury = address(0x3);
    address secondAccount = address(0x4);
    address thirdAccount = address(0x5);
    address fourthAccount = address(0x6);
    address fifthAccount = address(0x7);
    address stakingZeroAccount = address(0x8);
    address stakingMinAccount = address(0x9);
    address stakingMaxAccount = address(0x10);

    address sablier = 0xA4fc358455Febe425536fd1878bE67FfDBDEC59a;
    address curve3CrvBasePool = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address curveWhaleAddress = 0x4486083589A063ddEF47EE2E4467B5236C508fDe;
    address daiWhaleAddress = 0x16463c0fdB6BA9618909F5b120ea1581618C1b9E;
    address usdcWhaleAddress = 0x72A53cDBBcc1b9efa39c834A540550e23463AAcB;
    address curve3CrvToken = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

    string uri =
        "https://bafybeifibz4fhk4yag5reupmgh5cdbm2oladke4zfd7ldyw7avgipocpmy.ipfs.infura-ipfs.io/";
    uint256 creditNftLengthBlocks = 100;

    address[] migrating;
    uint256[] migrateLP;
    uint256[] locked;

    function setUp() public virtual {
        vm.startPrank(admin);

        manager = new UbiquityDollarManager(admin);
        address managerAddress = address(manager);

        bondingV1 = new MockBondingV1(managerAddress, sablier);
        bondingShareV1 = new MockBondingShareV1(manager);
        manager.setStakingShareAddress(address(bondingShareV1));
        manager.setStakingContractAddress(address(bondingV1));
        manager.grantRole(
            manager.GOVERNANCE_TOKEN_MINTER_ROLE(),
            address(bondingV1)
        );
        manager.grantRole(
            manager.GOVERNANCE_TOKEN_MINTER_ROLE(),
            address(bondingShareV1)
        );

        dollarToken = new MockDollarToken(10000);
        manager.setDollarTokenAddress(address(dollarToken));

        creditNft = new MockCreditNft(100);
        manager.setCreditNftAddress(address(creditNft));

        ubiquiStick = new MockUbiquistick();
        manager.setUbiquiStickAddress(address(ubiquiStick));

        uint32 connectorWeight;
        uint256 baseY;
        bondingCurve = new BondingCurve(
            address(manager),
            address(ubiquiStick)
        );

        manager.setBondingCurveAddress(address(bondingCurve));

        manager.grantRole(
            manager.BONDING_MINTER_ROLE(),
            admin
        );

        ubiquityFormulas = new UbiquityFormulas();
        manager.setFormulasAddress(address(ubiquityFormulas));

        governanceToken = new UbiquityGovernanceToken(manager);
        manager.setGovernanceTokenAddress(address(governanceToken));
        //manager.grantRole(manager.STAKING_MANAGER_ROLE(), admin);

        bondingV1.setBlockCountInAWeek(420);
        manager.setStakingContractAddress(address(bondingV1));

        bondingShareV1.setApprovalForAll(address(bondingV1), true);

        manager.setTreasuryAddress(treasury);

        deal(address(governanceToken), thirdAccount, 100000e18);
        deal(address(dollarToken), thirdAccount, 1000000e18);

        sushiGovernancePool = new SushiSwapPool(manager);
        manager.setSushiSwapPoolAddress(address(sushiGovernancePool));

        vm.stopPrank();

        vm.startPrank(thirdAccount);
        dollarToken.approve(address(router), 1000000e18);
        governanceToken.approve(address(router), 100000e18);
        router.addLiquidity(
            address(dollarToken),
            address(governanceToken),
            1000000e18,
            100000e18,
            990000e18,
            99000e18,
            thirdAccount,
            block.timestamp + 100
        );
        vm.stopPrank();

        vm.startPrank(admin);

        address[6] memory mintings = [
            admin,
            address(manager),
            fourthAccount,
            stakingZeroAccount,
            stakingMinAccount,
            stakingMaxAccount
        ];

        for (uint256 i = 0; i < mintings.length; ++i) {
            deal(address(dollarToken), mintings[i], 10000e18);
        }

        manager.grantRole(
            manager.GOVERNANCE_TOKEN_MINTER_ROLE(),
            address(bondingV1)
        );
        manager.grantRole(
            manager.GOVERNANCE_TOKEN_BURNER_ROLE(),
            address(bondingV1)
        );

        deal(address(dollarToken), curveWhaleAddress, 10e18);

        vm.stopPrank();

        address[4] memory crvDeal = [
            address(manager),
            stakingMaxAccount,
            stakingMinAccount,
            fourthAccount
        ];

        for (uint256 i; i < crvDeal.length; ++i) {
            vm.prank(curveWhaleAddress);
            crvToken.transfer(crvDeal[i], 10000e18);
        }

        vm.startPrank(admin);
        manager.deployStableSwapPool(
            address(curvePoolFactory),
            curve3CrvBasePool,
            curve3CrvToken,
            10,
            50000000
        );
        metapool = IMetaPool(manager.stableSwapMetaPoolAddress());
        metapool.transfer(address(staking), 100e18);
        metapool.transfer(secondAccount, 1000e18);

        twapOracle = new TWAPOracleDollar3pool(
            address(metapool),
            address(dollarToken),
            address(curve3CrvToken)
        );
        manager.setTwapOracleAddress(address(twapOracle));
        creditRedemptionCalc = new CreditRedemptionCalculator(manager);
        manager.setCreditCalculatorAddress(address(creditRedemptionCalc));

        creditNftRedemptionCalc = new CreditNftRedemptionCalculator(manager);
        manager.setCreditNftCalculatorAddress(address(creditNftRedemptionCalc));

        dollarMintCalc = new DollarMintCalculator(manager);
        manager.setDollarMintCalculatorAddress(address(dollarMintCalc));

        creditNftManager = new CreditNftManager(manager, creditNftLengthBlocks);

        manager.grantRole(
            manager.CREDIT_NFT_MANAGER_ROLE(),
            address(creditNftManager)
        );
        manager.grantRole(
            manager.GOVERNANCE_TOKEN_MINTER_ROLE(),
            address(creditNftManager)
        );
        manager.grantRole(
            manager.GOVERNANCE_TOKEN_BURNER_ROLE(),
            address(creditNftManager)
        );

        creditToken = new UbiquityCreditToken(manager);
        manager.setCreditTokenAddress(address(creditToken));

        dollarMintExcess = new DollarMintExcess(manager);
        manager.setExcessDollarsDistributor(
            address(creditNftManager),
            address(dollarMintExcess)
        );

        address[] memory tos;
        uint256[] memory amounts;
        uint256[] memory ids;

        ubiquityChef = new UbiquityChef(manager, tos, amounts, ids);

        manager.setMasterChefAddress(address(ubiquityChef));
        manager.grantRole(
            manager.GOVERNANCE_TOKEN_MINTER_ROLE(),
            address(ubiquityChef)
        );
        manager.grantRole(manager.GOVERNANCE_TOKEN_MANAGER_ROLE(), admin);
        manager.grantRole(
            manager.GOVERNANCE_TOKEN_MANAGER_ROLE(),
            managerAddress
        );

        ubiquityChef.setGovernancePerBlock(10e18);

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
        stakingShare = new StakingShare(manager, uri);
        manager.setStakingShareAddress(address(stakingShare));

        stakingFormulas = new StakingFormulas();

        migrating = [stakingZeroAccount, stakingMinAccount, stakingMaxAccount];
        migrateLP = [0, 0, 0];
        locked = [uint256(1), uint256(1), uint256(208)];

        staking = new Staking(
            manager,
            stakingFormulas,
            migrating,
            migrateLP,
            locked
        );

        deal(address(dollarToken), address(staking), 100e18);

        staking.setMigrating(true);

        manager.grantRole(
            manager.GOVERNANCE_TOKEN_MINTER_ROLE(),
            address(staking)
        );
        staking.setBlockCountInAWeek(420);

        manager.setStakingContractAddress(address(staking));

        manager.revokeRole(
            manager.GOVERNANCE_TOKEN_MINTER_ROLE(),
            address(bondingV1)
        );
        manager.revokeRole(
            manager.GOVERNANCE_TOKEN_BURNER_ROLE(),
            address(bondingV1)
        );
        vm.stopPrank();

        vm.prank(secondAccount);
        bondingShareV1.setApprovalForAll(address(bondingV1), true);

        vm.prank(thirdAccount);
        bondingShareV1.setApprovalForAll(address(bondingV1), true);
    }
}
