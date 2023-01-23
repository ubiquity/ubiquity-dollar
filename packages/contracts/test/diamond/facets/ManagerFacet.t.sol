// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DiamondTestSetup.sol";
import "../../../src/dollar/interfaces/ICurveFactory.sol";
import "../../../src/dollar/interfaces/IMetaPool.sol";
import "../../../src/dollar/mocks/MockDollarToken.sol";
import "../../../src/dollar/mocks/MockTWAPOracleDollar3pool.sol";
import "../../../src/diamond/libraries/LibAccessControl.sol";

contract RemoteTestManagerFacet is DiamondSetup {
    function testCanCallGeneralFunctions_ShouldSucceed() public {
        IManager.excessDollarsDistributor(contract1);
    }

    function testSetTwapOracleAddress_ShouldSucceed() public prankAs(admin) {
        assertEq(IManager.twapOracleAddress(), address(diamond));
    }

    function testSetDollarTokenAddress_ShouldSucceed() public prankAs(admin) {
        assertEq(IManager.dollarTokenAddress(), address(diamond));
    }

    function testSetCreditTokenAddress_ShouldSucceed() public prankAs(admin) {
        IManager.setCreditTokenAddress(contract1);
        assertEq(IManager.creditTokenAddress(), contract1);
    }

    function testSetCreditNFTAddress_ShouldSucceed() public prankAs(admin) {
        IManager.setCreditNFTAddress(contract1);
        assertEq(IManager.creditNFTAddress(), contract1);
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

    function testSetCreditCalculatorAddress_ShouldSucceed()
        public
        prankAs(admin)
    {
        IManager.setCreditCalculatorAddress(contract1);
        assertEq(IManager.creditCalculatorAddress(), contract1);
    }

    function testSetCreditNFTCalculatorAddress_ShouldSucceed()
        public
        prankAs(admin)
    {
        IManager.setCreditNFTCalculatorAddress(contract1);
        assertEq(IManager.creditNFTCalculatorAddress(), contract1);
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
        assertEq(IManager.dollarTokenAddress(), address(diamond));
    }

    function testDeployStableSwapPool_ShouldSucceed() public {
        assertEq(IDollarFacet.decimals(), 18);
        vm.startPrank(admin);

        IDollarFacet.mint(admin, 10000);

        IERC20 crvToken = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);

        address secondAccount = address(0x3);
        address stakingZeroAccount = address(0x4);
        address stakingMinAccount = address(0x5);
        address stakingMaxAccount = address(0x6);
        address curveWhaleAddress = 0x4486083589A063ddEF47EE2E4467B5236C508fDe;

        address[6] memory mintings = [
            admin,
            address(diamond),
            secondAccount,
            stakingZeroAccount,
            stakingMinAccount,
            stakingMaxAccount
        ];

        for (uint256 i = 0; i < mintings.length; ++i) {
            deal(address(IDollarFacet), mintings[i], 10000e18);
        }

        address stakingV1Address = generateAddress("stakingV1", true, 10 ether);
        IAccessCtrl.grantRole(GOVERNANCE_TOKEN_MINTER_ROLE, stakingV1Address);
        IAccessCtrl.grantRole(GOVERNANCE_TOKEN_BURNER_ROLE, stakingV1Address);

        deal(address(IDollarFacet), curveWhaleAddress, 10e18);

        vm.stopPrank();

        address[4] memory crvDeal = [
            address(diamond),
            stakingMaxAccount,
            stakingMinAccount,
            secondAccount
        ];

        for (uint256 i; i < crvDeal.length; ++i) {
            vm.prank(curveWhaleAddress);
            crvToken.transfer(crvDeal[i], 10000e18);
        }

        vm.startPrank(admin);

        ICurveFactory curvePoolFactory = ICurveFactory(
            0x0959158b6040D32d04c301A72CBFD6b39E21c9AE
        );
        address curve3CrvBasePool = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
        address curve3CrvToken = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

        IManager.deployStableSwapPool(
            address(curvePoolFactory),
            curve3CrvBasePool,
            curve3CrvToken,
            10,
            50000000
        );

        IMetaPool metapool = IMetaPool(IManager.stableSwapMetaPoolAddress());
        address stakingV2Address = generateAddress("stakingV2", true, 10 ether);
        metapool.transfer(address(stakingV2Address), 100e18);
        vm.stopPrank();
    }
}
