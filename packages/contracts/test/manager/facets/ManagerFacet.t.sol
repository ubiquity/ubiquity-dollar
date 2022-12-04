// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DiamondTestSetup.sol";
import "../../../src/dollar/interfaces/ICurveFactory.sol";
import "../../../src/dollar/interfaces/IMetaPool.sol";
import "../../../src/dollar/mocks/MockUbiquityGovernance.sol";
import "../../../src/dollar/mocks/MockuADToken.sol";

import {
    UBQ_MINTER_ROLE,
    UBQ_BURNER_ROLE
} from "../../../src/manager/libraries/LibAppStorage.sol";

contract TestManagerFacet is DiamondSetup {

    function testCanCallGeneralFunctions() public {
        IManagerFacet.getExcessDollarsDistributor(contract1);
    }

    function testCanCallAdminFunction_OnlyWith_AdminRole() public prankAs(admin) {
        IManagerFacet.setCreditTokenAddress(contract1);
    }

    function testShouldUpdateDiamondStorage() public prankAs(admin) {
        IManagerFacet.setCreditTokenAddress(contract1);
        assertEq(IManagerFacet.getCreditTokenAddress(), contract1);
    }

    function testShouldSetDollarTokenAddress() public prankAs(admin) {
        IManagerFacet.setDollarTokenAddress(contract1);
        assertEq(IManagerFacet.getDollarTokenAddress(), contract1);
    }

    function testShouldSetCreditTokenAddress() public prankAs(admin) {
        IManagerFacet.setCreditTokenAddress(contract1);
        assertEq(IManagerFacet.getCreditTokenAddress(), contract1);
    }

    function testShouldSetDebtCouponAddress() public prankAs(admin) {
        IManagerFacet.setDebtCouponAddress(contract1);
        assertEq(IManagerFacet.getDebtCouponAddress(), contract1);
    }
    
    function testShouldSetGovernanceTokenAddress() public prankAs(admin) {
        IManagerFacet.setGovernanceTokenAddress(contract1);
        assertEq(IManagerFacet.getGovernanceTokenAddress(), contract1);
    }

    function testShouldSetSushiSwapPoolAddress() public prankAs(admin) {
        IManagerFacet.setSushiSwapPoolAddress(contract1);
        assertEq(IManagerFacet.getSushiSwapPoolAddress(), contract1);
    }

    function testShouldSetUCRCalculatorAddress() public prankAs(admin) {
        IManagerFacet.setUCRCalculatorAddress(contract1);
        assertEq(IManagerFacet.getUCRCalculatorAddress(), contract1);
    }

    function testShouldSetCouponCalculatorAddress() public prankAs(admin) {
        IManagerFacet.setCouponCalculatorAddress(contract1);
        assertEq(IManagerFacet.getCouponCalculatorAddress(), contract1);
    }
    
    function testShouldSetDollarMintingCalculatorAddress() public prankAs(admin) {
        IManagerFacet.setDollarMintingCalculatorAddress(contract1);
        assertEq(IManagerFacet.getDollarMintingCalculatorAddress(), contract1);
    }

    function testShouldSetExcessDollarsDistributor() public prankAs(admin) {
        IManagerFacet.setExcessDollarsDistributor(contract1, contract2);
        assertEq(IManagerFacet.getExcessDollarsDistributor(contract1), contract2);
    }

    function testShouldSetMasterChefAddress() public prankAs(admin) {
        IManagerFacet.setMasterChefAddress(contract1);
        assertEq(IManagerFacet.getMasterChefAddress(), contract1);
    }

    function testShouldSetFormulasAddress() public prankAs(admin) {
        IManagerFacet.setFormulasAddress(contract1);
        assertEq(IManagerFacet.getFormulasAddress(), contract1);
    }

    function testShouldSetBondingShareAddress() public prankAs(admin) {
        IManagerFacet.setBondingShareAddress(contract1);
        assertEq(IManagerFacet.getBondingShareAddress(), contract1);
    }

    function testShouldSetStableSwapMetaPoolAddress() public prankAs(admin) {
        IManagerFacet.setStableSwapMetaPoolAddress(contract1);
        assertEq(IManagerFacet.getStableSwapMetaPoolAddress(), contract1);
    }

    function testShouldSetBondingContractAddress() public prankAs(admin) {
        IManagerFacet.setBondingContractAddress(contract1);
        assertEq(IManagerFacet.getBondingContractAddress(), contract1);
    }

    function testShouldSetTreasuryAddress() public prankAs(admin) {
        IManagerFacet.setTreasuryAddress(contract1);
        assertEq(IManagerFacet.getTreasuryAddress(), contract1);
    }

    function testShouldSetIncentiveToUAD() public prankAs(admin) {
        address dollarTokenAddress = generateAddress("dollarTokenAddress", true, 10 ether);
        IManagerFacet.setDollarTokenAddress(dollarTokenAddress);
        IManagerFacet.setIncentiveToUAD(user1, contract1);
    }

    function testShouldSetMinterRoleWhenInitializing() public prankAs(admin) {
        assertEq(IManagerFacet.hasRole(UBQ_MINTER_ROLE, admin), true);
    }

    function testShouldInitializeDollarTokenAddress() public prankAs(admin) {
        assertEq(IManagerFacet.getDollarTokenAddress(), address(diamond));
    }

    function testShouldDeployStableSwapPool() public {

        vm.startPrank(admin);

        MockuADToken uAD;
        MockUbiquityGovernance uGov;

        uAD = new MockuADToken(10000);
        uGov = new MockUbiquityGovernance(10000);

        IManagerFacet.setDollarTokenAddress(address(uAD));
        IManagerFacet.setGovernanceTokenAddress(address(uGov));
        IERC20 crvToken = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);

        address secondAccount = address(0x3);
        address bondingZeroAccount = address(0x4);
        address bondingMinAccount = address(0x5);
        address bondingMaxAccount = address(0x6);
        address curveWhaleAddress = 0x4486083589A063ddEF47EE2E4467B5236C508fDe;

        address[6] memory mintings = [
            admin,
            address(diamond),
            secondAccount,
            bondingZeroAccount,
            bondingMinAccount,
            bondingMaxAccount
        ];

        for (uint256 i = 0; i < mintings.length; ++i) {
            deal(address(uAD), mintings[i], 10000e18);
        }

        address bondingV1Address = generateAddress("bondingV1", true, 10 ether);
        IManagerFacet.grantRole(UBQ_MINTER_ROLE, bondingV1Address);
        IManagerFacet.grantRole(UBQ_BURNER_ROLE, bondingV1Address);

        deal(address(uAD), curveWhaleAddress, 10e18);

        vm.stopPrank();

        address[4] memory crvDeal = [
            address(diamond),
            bondingMaxAccount,
            bondingMinAccount,
            secondAccount
        ];

        for (uint256 i; i < crvDeal.length; ++i) {
            vm.prank(curveWhaleAddress);
            crvToken.transfer(crvDeal[i], 10000e18);
        }

        vm.startPrank(admin);

        ICurveFactory curvePoolFactory = ICurveFactory(0x0959158b6040D32d04c301A72CBFD6b39E21c9AE);
        address curve3CrvBasePool = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
        address curve3CrvToken = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

        IManagerFacet.deployStableSwapPool(
            address(curvePoolFactory),
            curve3CrvBasePool,
            curve3CrvToken,
            10,
            50000000
        );

        IMetaPool metapool = IMetaPool(IManagerFacet.getStableSwapMetaPoolAddress());
        address bondingV2Address = generateAddress("bondingV2", true, 10 ether);
        metapool.transfer(address(bondingV2Address), 100e18);
        vm.stopPrank();

    }
}