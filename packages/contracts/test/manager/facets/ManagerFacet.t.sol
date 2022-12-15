// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DiamondTestSetup.sol";
import "../../../src/dollar/interfaces/ICurveFactory.sol";
import "../../../src/dollar/interfaces/IMetaPool.sol";
import "../../../src/dollar/mocks/MockDollarToken.sol";
import "../../../src/dollar/mocks/MockTWAPOracleDollar3pool.sol";
import "../../../src/manager/libraries/LibAccessControl.sol";

contract RemoteTestManagerFacet is DiamondSetup {
    function testCanCallGeneralFunctions() public {
        IManager.getExcessDollarsDistributor(contract1);
    }

    function testSetTwapOracleAddress_ShouldSucceed() public prankAs(admin) {
        assertEq(IManager.getTwapOracleAddress(), address(diamond));
    }

    function testSetDollarTokenAddress_ShouldSucceed() public prankAs(admin) {
        assertEq(IManager.getDollarTokenAddress(), address(diamond));
    }

    function testSetCreditTokenAddress_ShouldSucceed() public prankAs(admin) {
        IManagerFacet.setCreditTokenAddress(contract1);
        assertEq(IManagerFacet.getCreditTokenAddress(), contract1);
    }

    function testSetCreditNftAddress_ShouldSucceed() public prankAs(admin) {
        IManagerFacet.setCreditNftAddress(contract1);
        assertEq(IManagerFacet.getCreditNftAddress(), contract1);
    }

    function testSetGovernanceTokenAddress_ShouldSucceed()
        public
        prankAs(admin)
    {
        IManagerFacet.setGovernanceTokenAddress(contract1);
        assertEq(IManagerFacet.getGovernanceTokenAddress(), contract1);
    }

    function testSetSushiSwapPoolAddress_ShouldSucceed() public prankAs(admin) {
        IManagerFacet.setSushiSwapPoolAddress(contract1);
        assertEq(IManagerFacet.getSushiSwapPoolAddress(), contract1);
    }

    function testSetCreditCalculatorAddress_ShouldSucceed()
        public
        prankAs(admin)
    {
        IManagerFacet.setCreditCalculatorAddress(contract1);
        assertEq(IManagerFacet.getCreditCalculatorAddress(), contract1);
    }

    function testSetCreditNftCalculatorAddress_ShouldSucceed()
        public
        prankAs(admin)
    {
        IManagerFacet.setCreditNftCalculatorAddress(contract1);
        assertEq(IManagerFacet.getCreditNftCalculatorAddress(), contract1);
    }

    function testSetDollarMintCalculatorAddress_ShouldSucceed()
        public
        prankAs(admin)
    {
        IManagerFacet.setDollarMintCalculatorAddress(contract1);
        assertEq(IManagerFacet.getDollarMintCalculatorAddress(), contract1);
    }

    function testSetExcessDollarsDistributor_ShouldSucceed()
        public
        prankAs(admin)
    {
        IManagerFacet.setExcessDollarsDistributor(contract1, contract2);
        assertEq(
            IManagerFacet.getExcessDollarsDistributor(contract1),
            contract2
        );
    }

    function testSetMasterChefAddress_ShouldSucceed() public prankAs(admin) {
        IManagerFacet.setMasterChefAddress(contract1);
        assertEq(IManagerFacet.getMasterChefAddress(), contract1);
    }

    function testSetFormulasAddress_ShouldSucceed() public prankAs(admin) {
        IManagerFacet.setFormulasAddress(contract1);
        assertEq(IManagerFacet.getFormulasAddress(), contract1);
    }

    function testSetStakingShareAddress_ShouldSucceed() public prankAs(admin) {
        IManagerFacet.setStakingShareAddress(contract1);
        assertEq(IManagerFacet.getStakingShareAddress(), contract1);
    }

    function testSetStableSwapMetaPoolAddress_ShouldSucceed()
        public
        prankAs(admin)
    {
        IManagerFacet.setStableSwapMetaPoolAddress(contract1);
        assertEq(IManagerFacet.getStableSwapMetaPoolAddress(), contract1);
    }

    function testSetStakingContractAddress_ShouldSucceed()
        public
        prankAs(admin)
    {
        IManagerFacet.setStakingContractAddress(contract1);
        assertEq(IManagerFacet.getStakingContractAddress(), contract1);
    }

    function testSetTreasuryAddress_ShouldSucceed() public prankAs(admin) {
        IManagerFacet.setTreasuryAddress(contract1);
        assertEq(IManagerFacet.getTreasuryAddress(), contract1);
    }

    function testSetIncentiveToDollar_ShouldSucceed() public prankAs(admin) {
        assertEq(
            IAccessControl.hasRole(GOVERNANCE_TOKEN_MANAGER_ROLE, admin),
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

    function testDeployStableSwapPool_ShouldSucceed() public {
        assertEq(IUbiquityDollarToken.decimals(), 18);
        vm.startPrank(admin);

        IUbiquityDollarToken.mint(admin, 10000);

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
            deal(address(IUbiquityDollarToken), mintings[i], 10000e18);
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

        deal(address(IUbiquityDollarToken), curveWhaleAddress, 10e18);

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

        IMetaPool metapool = IMetaPool(
            IManagerFacet.getStableSwapMetaPoolAddress()
        );
        address stakingV2Address = generateAddress("stakingV2", true, 10 ether);
        metapool.transfer(address(stakingV2Address), 100e18);
        vm.stopPrank();
    }
}
