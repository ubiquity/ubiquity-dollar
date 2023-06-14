// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IManagerMainnet {
    function stableSwapMetaPoolAddress() external view returns (address);
    function deployStableSwapPool( address _curveFactory, address _crvBasePool, address _crv3PoolTokenAddress, uint256 _amplificationCoefficient, uint256 _fee) external;
}

import "../DiamondTestSetup.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICurveFactory} from "../../../src/dollar/interfaces/ICurveFactory.sol";
import {IMetaPool} from "../../../src/dollar/interfaces/IMetaPool.sol";
import {LibAccessControl} from "../../../src/dollar/libraries/LibAccessControl.sol";

contract ManagerFacetTest is DiamondSetup {

    IManagerMainnet manager = IManagerMainnet(0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98);
    IERC20 curve3CrvToken = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
    IERC20 UbiquityDollarMainnet = IERC20(0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6);
    address curveWhale = 0x4486083589A063ddEF47EE2E4467B5236C508fDe;
    address UbiquityDollarWhale = 0xf51a97aaBE438a6A92Fa81448DA63EAd09FB9945;
    address factory = 0x20955CB69Ae1515962177D164dfC9522feef567E;
    address crvFactory = 0xB9fC157394Af804a3578134A6585C0dc9cc990d4; //0x0959158b6040D32d04c301A72CBFD6b39E21c9AE;
    address adminPransker = 0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd;
    address basePool = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    //address metapool = 0x20955CB69Ae1515962177D164dfC9522feef567E;

    function setUp() public override {
        super.setUp();
    }

    function test_Fork() public override {
        vm.activeFork(); //Active??
    }
    
    function testCanCallGeneralFunctions_ShouldSucceed() public view {
        IManager.excessDollarsDistributor(contract1);
    }

    function testSetTwapOracleAddress_ShouldSucceed() public prankAs(admin) {
        assertEq(IManager.twapOracleAddress(), address(diamond));
    }

    function testSetDollarTokenAddress_ShouldSucceed() public prankAs(admin) {
        assertEq(IManager.dollarTokenAddress(), address(IDollar));
    }

    function testSetCreditTokenAddress_ShouldSucceed() public prankAs(admin) {
        IManager.setCreditTokenAddress(contract1);
        assertEq(IManager.creditTokenAddress(), contract1);
    }

    function testSetCreditNFTAddress_ShouldSucceed() public prankAs(admin) {
        IManager.setCreditNftAddress(contract1);
        assertEq(IManager.creditNftAddress(), contract1);
    }

    function testSetGovernanceTokenAddress_ShouldSucceed()
        public
        prankAs(admin)
    {
        IManager.setGovernanceTokenAddress(contract1);
        assertEq(IManager.governanceTokenAddress(), contract1);
    }

    function testSetSushiSwapPoolAddress_ShouldSucceed() public prankAs(admin) {
        IManager.setSushiSwapPoolAddress(contract1);
        assertEq(IManager.sushiSwapPoolAddress(), contract1);
    }

    function testSetDollarMintCalculatorAddress_ShouldSucceed()
        public
        prankAs(admin)
    {
        IManager.setDollarMintCalculatorAddress(contract1);
        assertEq(IManager.dollarMintCalculatorAddress(), contract1);
    }

    function testSetExcessDollarsDistributor_ShouldSucceed()
        public
        prankAs(admin)
    {
        IManager.setExcessDollarsDistributor(contract1, contract2);
        assertEq(IManager.excessDollarsDistributor(contract1), contract2);
    }

    function testSetMasterChefAddress_ShouldSucceed() public prankAs(admin) {
        IManager.setMasterChefAddress(contract1);
        assertEq(IManager.masterChefAddress(), contract1);
    }

    function testSetFormulasAddress_ShouldSucceed() public prankAs(admin) {
        IManager.setFormulasAddress(contract1);
        assertEq(IManager.formulasAddress(), contract1);
    }

    function testSetStakingShareAddress_ShouldSucceed() public prankAs(admin) {
        IManager.setStakingShareAddress(contract1);
        assertEq(IManager.stakingShareAddress(), contract1);
    }

    function testSetStableSwapMetaPoolAddress_ShouldSucceed()
        public
        prankAs(admin)
    {
        IManager.setStableSwapMetaPoolAddress(contract1);
        assertEq(IManager.stableSwapMetaPoolAddress(), contract1);
    }

    function testSetStakingContractAddress_ShouldSucceed()
        public
        prankAs(admin)
    {
        IManager.setStakingContractAddress(contract1);
        assertEq(IManager.stakingContractAddress(), contract1);
    }

    function testSetTreasuryAddress_ShouldSucceed() public prankAs(admin) {
        IManager.setTreasuryAddress(contract1);
        assertEq(IManager.treasuryAddress(), contract1);
    }

    function testSetIncentiveToDollar_ShouldSucceed() public prankAs(admin) {
        assertEq(
            IAccessCtrl.hasRole(GOVERNANCE_TOKEN_MANAGER_ROLE, admin),
            true
        );
        assertEq(
            IAccessCtrl.hasRole(
                GOVERNANCE_TOKEN_MANAGER_ROLE,
                address(diamond)
            ),
            true
        );
        IManager.setIncentiveToDollar(user1, contract1);
    }

    function testSetMinterRoleWhenInitializing_ShouldSucceed()
        public
        prankAs(admin)
    {
        assertEq(
            IAccessCtrl.hasRole(GOVERNANCE_TOKEN_MINTER_ROLE, admin),
            true
        );
    }

    function testInitializeDollarTokenAddress_ShouldSucceed()
        public
        prankAs(admin)
    {
        assertEq(IManager.dollarTokenAddress(), address(IDollar));
    }

    function test_Minting() public {
        address secondAccount = address(0x3);
        address stakingZeroAccount = address(0x4);
        address stakingMinAccount = address(0x5);
        address stakingMaxAccount = address(0x6);
        
        vm.startPrank(UbiquityDollarWhale);
        address[6] memory mintings = [
            admin,
            address(diamond),
            secondAccount,
            stakingZeroAccount,
            stakingMinAccount,
            stakingMaxAccount
        ];

        for (uint256 i = 0; i < mintings.length; ++i) {
            IERC20(UbiquityDollarMainnet).transfer(mintings[i], 1000e18);
        }
        vm.stopPrank();

        vm.startPrank(curveWhale);
        address[4] memory crvDeal = [
            //address(diamond),
            stakingMaxAccount,
            stakingMaxAccount,
            stakingMinAccount,
            secondAccount
        ];

        for (uint256 i; i < crvDeal.length; ++i) {
            // distribute crv to the accounts
            IERC20(curve3CrvToken).transfer(crvDeal[i], 10000e18);
        }
        vm.stopPrank();
    }

    function test_Transfer() public {
        vm.startPrank(curveWhale);
        IERC20(curve3CrvToken).transfer(address(this), 1 ether);
        vm.stopPrank();
    }

    function test_TestCrv3FactoryMetaPool() public {
        vm.startPrank(admin);
        address curve3CrvBasePool = ICurveFactory(crvFactory).deploy_metapool(address(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7), "UBIQUITYMETAPOOL", "3UBs", address(curve3CrvToken), 10, 4000000);
        vm.stopPrank();
    }

    function testDeployStableSwapPool_ShouldSucceed() public {
        vm.startPrank(admin);
        
        address secondAccount = address(0x3);
        address stakingZeroAccount = address(0x4);
        address stakingMinAccount = address(0x5);
        address stakingMaxAccount = address(0x6);
        vm.label(secondAccount, "SECOND ACCOUNT");
        vm.label(stakingZeroAccount, "STAKING ZERO ACC");
        vm.label(stakingMinAccount, "STAKING MIX ACCOUNT");
        vm.label(stakingMaxAccount, "STAKING MAX ACCOUNT");


        address stakingV1Address = generateAddress("stakingV1", true, 10 ether);
        IAccessCtrl.grantRole(GOVERNANCE_TOKEN_MINTER_ROLE, stakingV1Address);
        IAccessCtrl.grantRole(GOVERNANCE_TOKEN_BURNER_ROLE, stakingV1Address);
        
        vm.stopPrank();
        
        vm.startPrank(UbiquityDollarWhale);
        address[6] memory mintings = [
            admin,
            address(diamond),
            secondAccount,
            stakingZeroAccount,
            stakingMinAccount,
            stakingMaxAccount
        ];

        for (uint256 i = 0; i < mintings.length; ++i) {
            IERC20(UbiquityDollarMainnet).transfer(mintings[i], 1000e18);
        }
        vm.stopPrank();

        vm.startPrank(curveWhale);
        address[4] memory crvDeal = [
            address(diamond),
            stakingMaxAccount,
            stakingMinAccount,
            secondAccount
        ];

        for (uint256 i; i < crvDeal.length; ++i) {
            // distribute crv to the accounts
            IERC20(curve3CrvToken).transfer(crvDeal[i], 10000e18);
        }
        vm.stopPrank();

        vm.startPrank(adminPransker);
        vm.label(adminPransker, "MAINNET MANAGER");

        address curve3CrvBasePool = ICurveFactory(crvFactory).deploy_metapool(address(basePool), "UBIQUITYMETAPOOL", "3UBs", address(UbiquityDollarMainnet), 10, 4000000);
        vm.label(curve3CrvBasePool, "CURVE DEPLOYED POOL");
        vm.stopPrank();
        vm.label(address(curve3CrvToken), "CURVE TOKEN");
        vm.startPrank(adminPransker);
        IManagerMainnet(manager).deployStableSwapPool(address(crvFactory), address(basePool), address(curve3CrvToken),10,4000000);
        address metapool = IManagerMainnet(manager).stableSwapMetaPoolAddress();
        vm.label(metapool, "Stable Swap Address");
        address stakingV2Address = generateAddress("stakingV2", true, 10 ether);
        vm.label(stakingV2Address, "PRE GENERATED STAKING2VADDRESS");
        IMetaPool(metapool).transfer(address(stakingV2Address), 1e18);
        vm.stopPrank();
    }
}
