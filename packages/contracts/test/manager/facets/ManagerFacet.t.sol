// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DiamondTestSetup.sol";
import "../../../src/dollar/interfaces/ICurveFactory.sol";
import "../../../src/dollar/interfaces/IMetaPool.sol";

contract TestManagerFacet is AddManagerFacetSetup {

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

    function testShouldDeployStableSwapPool() public prankAs(admin) {
        address uAD = 0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6;
        IManagerFacet.setDollarTokenAddress(uAD);
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
    }
}