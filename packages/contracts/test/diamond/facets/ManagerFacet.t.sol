// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../DiamondTestSetup.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICurveFactory} from "../../../src/dollar/interfaces/ICurveFactory.sol";
import {IMetaPool} from "../../../src/dollar/interfaces/IMetaPool.sol";
import {MockTWAPOracleDollar3pool} from "../../../src/dollar/mocks/MockTWAPOracleDollar3pool.sol";
import {LibAccessControl} from "../../../src/dollar/libraries/LibAccessControl.sol";
import {MockERC20} from "../../../src/dollar/mocks/MockERC20.sol";
import {MockMetaPool} from "../../../src/dollar/mocks/MockMetaPool.sol";
import {MockCurveFactory} from "../../../src/dollar/mocks/MockCurveFactory.sol";

contract ManagerFacetTest is DiamondSetup {
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

    function testSetCreditNftAddress_ShouldSucceed() public prankAs(admin) {
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
            IAccessControl.hasRole(GOVERNANCE_TOKEN_MANAGER_ROLE, admin),
            true
        );
        assertEq(
            IAccessControl.hasRole(
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
            IAccessControl.hasRole(GOVERNANCE_TOKEN_MINTER_ROLE, admin),
            true
        );
    }

    function testInitializeDollarTokenAddress_ShouldSucceed()
        public
        prankAs(admin)
    {
        assertEq(IManager.dollarTokenAddress(), address(IDollar));
    }

    function testDeployStableSwapPool_ShouldSucceed() public {
        assertEq(IDollar.decimals(), 18);
        vm.startPrank(admin);

        IDollar.mint(admin, 10000);

        MockERC20 curve3CrvToken = new MockERC20("3 CRV", "3CRV", 18);
        address secondAccount = address(0x3);
        address stakingZeroAccount = address(0x4);
        address stakingMinAccount = address(0x5);
        address stakingMaxAccount = address(0x6);

        address[6] memory mintings = [
            admin,
            address(diamond),
            secondAccount,
            stakingZeroAccount,
            stakingMinAccount,
            stakingMaxAccount
        ];

        for (uint256 i = 0; i < mintings.length; ++i) {
            deal(address(IDollar), mintings[i], 10000e18);
        }

        address stakingV1Address = generateAddress("stakingV1", true, 10 ether);
        IAccessControl.grantRole(
            GOVERNANCE_TOKEN_MINTER_ROLE,
            stakingV1Address
        );
        IAccessControl.grantRole(
            GOVERNANCE_TOKEN_BURNER_ROLE,
            stakingV1Address
        );

        vm.stopPrank();

        address[4] memory crvDeal = [
            address(diamond),
            stakingMaxAccount,
            stakingMinAccount,
            secondAccount
        ];

        // curve3CrvBasePool Curve.fi: DAI/USDC/USDT Pool
        // curve3CrvToken  TokenTracker that represents  Curve.fi DAI/USDC/USDT part in the pool  (3Crv)

        for (uint256 i; i < crvDeal.length; ++i) {
            // distribute crv to the accounts
            curve3CrvToken.mint(crvDeal[i], 10000e18);
        }

        vm.startPrank(admin);

        ICurveFactory curvePoolFactory = ICurveFactory(new MockCurveFactory());
        address curve3CrvBasePool = address(
            new MockMetaPool(address(diamond), address(curve3CrvToken))
        );
        IManager.deployStableSwapPool(
            address(curvePoolFactory),
            curve3CrvBasePool,
            address(curve3CrvToken),
            10,
            50000000
        );

        IMetaPool metapool = IMetaPool(IManager.stableSwapMetaPoolAddress());
        address stakingV2Address = generateAddress("stakingV2", true, 10 ether);
        metapool.transfer(address(stakingV2Address), 100e18);
        vm.stopPrank();
    }
}
