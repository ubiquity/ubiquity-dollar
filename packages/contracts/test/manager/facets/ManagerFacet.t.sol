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

    function testShouldSetTwapOracleAddress() public prankAs(admin) {
        assertEq(IManager.getTwapOracleAddress(), address(diamond));
    }

    function testShouldSetDollarTokenAddress() public prankAs(admin) {
        assertEq(IManager.getDollarTokenAddress(), address(diamond));
    }

    function testShouldSetCreditTokenAddress() public prankAs(admin) {
        IManager.setCreditTokenAddress(contract1);
        assertEq(IManager.getCreditTokenAddress(), contract1);
    }

    function testShouldSetCreditNFTAddress() public prankAs(admin) {
        IManager.setCreditNFTAddress(contract1);
        assertEq(IManager.getCreditNFTAddress(), contract1);
    }

    function testShouldSetGovernanceTokenAddress() public prankAs(admin) {
        IManager.setGovernanceTokenAddress(contract1);
        assertEq(IManager.getGovernanceTokenAddress(), contract1);
    }

    function testShouldSetSushiSwapPoolAddress() public prankAs(admin) {
        IManager.setSushiSwapPoolAddress(contract1);
        assertEq(IManager.getSushiSwapPoolAddress(), contract1);
    }

    function testShouldSetCreditCalculatorAddress() public prankAs(admin) {
        IManager.setCreditCalculatorAddress(contract1);
        assertEq(IManager.getCreditCalculatorAddress(), contract1);
    }

    function testShouldSetCreditNFTCalculatorAddress() public prankAs(admin) {
        IManager.setCreditNFTCalculatorAddress(contract1);
        assertEq(IManager.getCreditNFTCalculatorAddress(), contract1);
    }

    function testShouldSetDollarMintCalculatorAddress() public prankAs(admin) {
        IManager.setDollarMintCalculatorAddress(contract1);
        assertEq(IManager.getDollarMintCalculatorAddress(), contract1);
    }

    function testShouldSetExcessDollarsDistributor() public prankAs(admin) {
        IManager.setExcessDollarsDistributor(contract1, contract2);
        assertEq(IManager.getExcessDollarsDistributor(contract1), contract2);
    }

    function testShouldSetMasterChefAddress() public prankAs(admin) {
        IManager.setMasterChefAddress(contract1);
        assertEq(IManager.getMasterChefAddress(), contract1);
    }

    function testShouldSetFormulasAddress() public prankAs(admin) {
        IManager.setFormulasAddress(contract1);
        assertEq(IManager.getFormulasAddress(), contract1);
    }

    function testShouldSetStakingShareAddress() public prankAs(admin) {
        IManager.setStakingShareAddress(contract1);
        assertEq(IManager.getStakingShareAddress(), contract1);
    }

    function testShouldSetStableSwapMetaPoolAddress() public prankAs(admin) {
        IManager.setStableSwapMetaPoolAddress(contract1);
        assertEq(IManager.getStableSwapMetaPoolAddress(), contract1);
    }

    function testShouldSetStakingContractAddress() public prankAs(admin) {
        IManager.setStakingContractAddress(contract1);
        assertEq(IManager.getStakingContractAddress(), contract1);
    }

    function testShouldSetTreasuryAddress() public prankAs(admin) {
        IManager.setTreasuryAddress(contract1);
        assertEq(IManager.getTreasuryAddress(), contract1);
    }

    function testShouldsetIncentiveToDollar() public prankAs(admin) {
        assertEq(
            IAccessControl.hasRole(GOVERNANCE_TOKEN_MANAGER_ROLE, admin),
            true
        );
        IManager.setIncentiveToDollar(user1, contract1);
    }

    function testShouldSetMinterRoleWhenInitializing() public prankAs(admin) {
        assertEq(
            IAccessControl.hasRole(GOVERNANCE_TOKEN_MINTER_ROLE, admin),
            true
        );
    }

    function testShouldDeployStableSwapPool() public {
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

        IMetaPool metapool = IMetaPool(IManager.getStableSwapMetaPoolAddress());
        address stakingV2Address = generateAddress("stakingV2", true, 10 ether);
        metapool.transfer(address(stakingV2Address), 100e18);
        vm.stopPrank();
    }
}
