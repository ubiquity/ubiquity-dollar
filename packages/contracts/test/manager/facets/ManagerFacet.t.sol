// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DiamondTestSetup.sol";
import "../../../src/dollar/interfaces/ICurveFactory.sol";

contract TestManagerFacet is AddManagerFacetSetup {

    function testCanCallGeneralFunctions() public {
        ManagerFacet(address(diamond)).getExcessDollarsDistributor(contract1);
    }

    function testCanCallAdminFunction_OnlyWith_AdminRole() public prankAs(admin) {
        ManagerFacet(address(diamond)).setCreditTokenAddress(contract1);
    }

    function testShouldUpdateDiamondStorage() public prankAs(admin) {
        ManagerFacet(address(diamond)).setCreditTokenAddress(contract1);
        assertEq(ManagerFacet(address(diamond)).getCreditTokenAddress(), contract1);
    }

    function testShouldSetDollarTokenAddress() public prankAs(admin) {
        ManagerFacet(address(diamond)).setDollarTokenAddress(contract1);
        assertEq(ManagerFacet(address(diamond)).getDollarTokenAddress(), contract1);
    }

    function testShouldSetCreditTokenAddress() public prankAs(admin) {
        ManagerFacet(address(diamond)).setCreditTokenAddress(contract1);
        assertEq(ManagerFacet(address(diamond)).getCreditTokenAddress(), contract1);
    }

    function testShouldSetDebtCouponAddress() public prankAs(admin) {
        ManagerFacet(address(diamond)).setDebtCouponAddress(contract1);
        assertEq(ManagerFacet(address(diamond)).getDebtCouponAddress(), contract1);
    }
    
    function testShouldSetGovernanceTokenAddress() public prankAs(admin) {
        ManagerFacet(address(diamond)).setGovernanceTokenAddress(contract1);
        assertEq(ManagerFacet(address(diamond)).getGovernanceTokenAddress(), contract1);
    }

    function testShouldSetSushiSwapPoolAddress() public prankAs(admin) {
        ManagerFacet(address(diamond)).setSushiSwapPoolAddress(contract1);
        assertEq(ManagerFacet(address(diamond)).getSushiSwapPoolAddress(), contract1);
    }

    function testShouldSetUCRCalculatorAddress() public prankAs(admin) {
        ManagerFacet(address(diamond)).setUCRCalculatorAddress(contract1);
        assertEq(ManagerFacet(address(diamond)).getUCRCalculatorAddress(), contract1);
    }

    function testShouldSetCouponCalculatorAddress() public prankAs(admin) {
        ManagerFacet(address(diamond)).setCouponCalculatorAddress(contract1);
        assertEq(ManagerFacet(address(diamond)).getCouponCalculatorAddress(), contract1);
    }
    
    function testShouldSetDollarMintingCalculatorAddress() public prankAs(admin) {
        ManagerFacet(address(diamond)).setDollarMintingCalculatorAddress(contract1);
        assertEq(ManagerFacet(address(diamond)).getDollarMintingCalculatorAddress(), contract1);
    }

    function testShouldSetExcessDollarsDistributor() public prankAs(admin) {
        ManagerFacet(address(diamond)).setExcessDollarsDistributor(contract1, contract2);
        assertEq(ManagerFacet(address(diamond)).getExcessDollarsDistributor(contract1), contract2);
    }

    function testShouldSetMasterChefAddress() public prankAs(admin) {
        ManagerFacet(address(diamond)).setMasterChefAddress(contract1);
        assertEq(ManagerFacet(address(diamond)).getMasterChefAddress(), contract1);
    }

    function testShouldSetFormulasAddress() public prankAs(admin) {
        ManagerFacet(address(diamond)).setFormulasAddress(contract1);
        assertEq(ManagerFacet(address(diamond)).getFormulasAddress(), contract1);
    }

    function testShouldSetBondingShareAddress() public prankAs(admin) {
        ManagerFacet(address(diamond)).setBondingShareAddress(contract1);
        assertEq(ManagerFacet(address(diamond)).getBondingShareAddress(), contract1);
    }

    function testShouldSetStableSwapMetaPoolAddress() public prankAs(admin) {
        ManagerFacet(address(diamond)).setStableSwapMetaPoolAddress(contract1);
        assertEq(ManagerFacet(address(diamond)).getStableSwapMetaPoolAddress(), contract1);
    }

    function testShouldSetBondingContractAddress() public prankAs(admin) {
        ManagerFacet(address(diamond)).setBondingContractAddress(contract1);
        assertEq(ManagerFacet(address(diamond)).getBondingContractAddress(), contract1);
    }

    function testShouldSetTreasuryAddress() public prankAs(admin) {
        ManagerFacet(address(diamond)).setTreasuryAddress(contract1);
        assertEq(ManagerFacet(address(diamond)).getTreasuryAddress(), contract1);
    }

    function testShouldSetIncentiveToUAD() public prankAs(admin) {
        address dollarTokenAddress = generateAddress("dollarTokenAddress", true, 10 ether);
        ManagerFacet(address(diamond)).setDollarTokenAddress(dollarTokenAddress);
        ManagerFacet(address(diamond)).setIncentiveToUAD(user1, contract1);
    }

    function testShouldDeployStableSwapPool() public prankAs(admin) {
        ICurveFactory curvePoolFactory = ICurveFactory(0x0959158b6040D32d04c301A72CBFD6b39E21c9AE);
        address curve3CrvBasePool = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
        address curve3CrvToken = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

        ManagerFacet(address(diamond)).deployStableSwapPool(
            address(curvePoolFactory),
            curve3CrvBasePool,
            curve3CrvToken,
            10,
            50000000
        );
    }
}