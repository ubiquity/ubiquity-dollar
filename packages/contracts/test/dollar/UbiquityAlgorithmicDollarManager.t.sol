// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../../src/dollar/interfaces/ICurveFactory.sol";
import "../../src/dollar/mocks/MockERC20.sol";
import {UbiquityAlgorithmicDollar} from "../../src/dollar/UbiquityAlgorithmicDollar.sol";
import {UbiquityAlgorithmicDollarManager} from "../../src/dollar/UbiquityAlgorithmicDollarManager.sol";
import "../../src/dollar/TWAPOracle.sol";
import "../helpers/LocalTestHelper.sol";

contract UbiquityAlgorithmicDollarManagerTest is LocalTestHelper {
    UbiquityAlgorithmicDollarManager uadManager;

    address userAddress = address(0x1);

    function setUp() public {
        uadManager = new UbiquityAlgorithmicDollarManager(admin);
    }

    function testConstructor_ShouldInitContract() public {
        assertTrue(uadManager.hasRole(uadManager.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(uadManager.hasRole(uadManager.UBQ_MINTER_ROLE(), admin));
        assertTrue(uadManager.hasRole(uadManager.PAUSER_ROLE(), admin));
        assertTrue(uadManager.hasRole(uadManager.COUPON_MANAGER_ROLE(), admin));
        assertTrue(uadManager.hasRole(uadManager.BONDING_MANAGER_ROLE(), admin));
        assertTrue(uadManager.hasRole(uadManager.INCENTIVE_MANAGER_ROLE(), admin));
        assertTrue(uadManager.hasRole(uadManager.UBQ_TOKEN_MANAGER_ROLE(), address(uadManager)));
    }

    function testSetTwapOracleAddress_ShouldRevert_IfCalledNotByAdmin() public {
        address mockAddress = address(0x2);
        vm.prank(userAddress);
        vm.expectRevert("uADMGR: Caller is not admin");
        uadManager.setTwapOracleAddress(mockAddress);
    }

    function testSetTwapOracleAddress_ShouldSetAddress() public {
        address mockAddress = address(0x2);

        vm.mockCall(
            mockAddress,
            abi.encodeWithSelector(TWAPOracle.update.selector),
            ""
        );

        vm.prank(admin);
        uadManager.setTwapOracleAddress(mockAddress);
        
        assertEq(uadManager.twapOracleAddress(), mockAddress);
    }

    function testSetuARTokenAddress_ShouldRevert_IfCalledNotByAdmin() public {
        address mockAddress = address(0x2);
        vm.prank(userAddress);
        vm.expectRevert("uADMGR: Caller is not admin");
        uadManager.setuARTokenAddress(mockAddress);
    }

    function testSetuARTokenAddress_ShouldSetAddress() public {
        address mockAddress = address(0x2);
        vm.prank(admin);
        uadManager.setuARTokenAddress(mockAddress);
        assertEq(uadManager.autoRedeemTokenAddress(), mockAddress);
    }

    function testSetDebtCouponAddress_ShouldRevert_IfCalledNotByAdmin() public {
        address mockAddress = address(0x2);
        vm.prank(userAddress);
        vm.expectRevert("uADMGR: Caller is not admin");
        uadManager.setDebtCouponAddress(mockAddress);
    }

    function testSetDebtCouponAddress_ShouldSetAddress() public {
        address mockAddress = address(0x2);
        vm.prank(admin);
        uadManager.setDebtCouponAddress(mockAddress);
        assertEq(uadManager.debtCouponAddress(), mockAddress);
    }

    function testSetIncentiveToUAD_ShouldRevert_IfCalledNotByAdmin() public {
        address mockAddress = address(0x2);
        vm.prank(userAddress);
        vm.expectRevert("uADMGR: Caller is not admin");
        uadManager.setIncentiveToUAD(mockAddress, mockAddress);
    }

    function testSetIncentiveToUAD_ShouldSetIncentive() public {
        // admin deploys UAD token
        vm.prank(admin);
        UbiquityAlgorithmicDollar uadToken = new UbiquityAlgorithmicDollar(address(uadManager));
        // admin sets UAD address in uad manager contract
        vm.prank(admin);
        uadManager.setDollarTokenAddress(address(uadToken));
        // set incentive
        address accountAddress = address(0x2);
        address incentiveAddress = address(0x3);
        vm.prank(admin);
        uadManager.setIncentiveToUAD(accountAddress, incentiveAddress);

        assertEq(uadToken.incentiveContract(accountAddress), incentiveAddress);
    }

    function testSetDollarTokenAddress_ShouldRevert_IfCalledNotByAdmin() public {
        address mockAddress = address(0x2);
        vm.prank(userAddress);
        vm.expectRevert("uADMGR: Caller is not admin");
        uadManager.setDollarTokenAddress(mockAddress);
    }

    function testSetDollarTokenAddress_ShouldSetAddress() public {
        address mockAddress = address(0x2);
        vm.prank(admin);
        uadManager.setDollarTokenAddress(mockAddress);
        assertEq(uadManager.dollarTokenAddress(), mockAddress);
    }

    function testSetGovernanceTokenAddress_ShouldRevert_IfCalledNotByAdmin() public {
        address mockAddress = address(0x2);
        vm.prank(userAddress);
        vm.expectRevert("uADMGR: Caller is not admin");
        uadManager.setGovernanceTokenAddress(mockAddress);
    }

    function testSetGovernanceTokenAddress_ShouldSetAddress() public {
        address mockAddress = address(0x2);
        vm.prank(admin);
        uadManager.setGovernanceTokenAddress(mockAddress);
        assertEq(uadManager.governanceTokenAddress(), mockAddress);
    }

    function testSetSushiSwapPoolAddress_ShouldRevert_IfCalledNotByAdmin() public {
        address mockAddress = address(0x2);
        vm.prank(userAddress);
        vm.expectRevert("uADMGR: Caller is not admin");
        uadManager.setSushiSwapPoolAddress(mockAddress);
    }

    function testSetSushiSwapPoolAddress_ShouldSetAddress() public {
        address mockAddress = address(0x2);
        vm.prank(admin);
        uadManager.setSushiSwapPoolAddress(mockAddress);
        assertEq(uadManager.sushiSwapPoolAddress(), mockAddress);
    }

    function testSetUARCalculatorAddress_ShouldRevert_IfCalledNotByAdmin() public {
        address mockAddress = address(0x2);
        vm.prank(userAddress);
        vm.expectRevert("uADMGR: Caller is not admin");
        uadManager.setUARCalculatorAddress(mockAddress);
    }

    function testSetUARCalculatorAddress_ShouldSetAddress() public {
        address mockAddress = address(0x2);
        vm.prank(admin);
        uadManager.setUARCalculatorAddress(mockAddress);
        assertEq(uadManager.uarCalculatorAddress(), mockAddress);
    }

    function testSetCouponCalculatorAddress_ShouldRevert_IfCalledNotByAdmin() public {
        address mockAddress = address(0x2);
        vm.prank(userAddress);
        vm.expectRevert("uADMGR: Caller is not admin");
        uadManager.setCouponCalculatorAddress(mockAddress);
    }

    function testSetCouponCalculatorAddress_ShouldSetAddress() public {
        address mockAddress = address(0x2);
        vm.prank(admin);
        uadManager.setCouponCalculatorAddress(mockAddress);
        assertEq(uadManager.couponCalculatorAddress(), mockAddress);
    }

    function testSetDollarMintingCalculatorAddress_ShouldRevert_IfCalledNotByAdmin() public {
        address mockAddress = address(0x2);
        vm.prank(userAddress);
        vm.expectRevert("uADMGR: Caller is not admin");
        uadManager.setDollarMintingCalculatorAddress(mockAddress);
    }

    function testSetDollarMintingCalculatorAddress_ShouldSetAddress() public {
        address mockAddress = address(0x2);
        vm.prank(admin);
        uadManager.setDollarMintingCalculatorAddress(mockAddress);
        assertEq(uadManager.dollarMintingCalculatorAddress(), mockAddress);
    }

    function testSetExcessDollarsDistributor_ShouldRevert_IfCalledNotByAdmin() public {
        address debtCouponManagerAddress = address(0x2);
        address excessCouponDistributorAddress = address(0x3);
        vm.prank(userAddress);
        vm.expectRevert("uADMGR: Caller is not admin");
        uadManager.setExcessDollarsDistributor(debtCouponManagerAddress, excessCouponDistributorAddress);
    }

    function testSetExcessDollarsDistributor_ShouldSetAddress() public {
        address debtCouponManagerAddress = address(0x2);
        address excessCouponDistributorAddress = address(0x3);
        vm.prank(admin);
        uadManager.setExcessDollarsDistributor(debtCouponManagerAddress, excessCouponDistributorAddress);
        assertEq(uadManager.getExcessDollarsDistributor(debtCouponManagerAddress), excessCouponDistributorAddress);
    }

    function testSetMasterChefAddress_ShouldRevert_IfCalledNotByAdmin() public {
        address mockAddress = address(0x2);
        vm.prank(userAddress);
        vm.expectRevert("uADMGR: Caller is not admin");
        uadManager.setMasterChefAddress(mockAddress);
    }

    function testSetMasterChefAddress_ShouldSetAddress() public {
        address mockAddress = address(0x2);
        vm.prank(admin);
        uadManager.setMasterChefAddress(mockAddress);
        assertEq(uadManager.masterChefAddress(), mockAddress);
    }

    function testSetFormulasAddress_ShouldRevert_IfCalledNotByAdmin() public {
        address mockAddress = address(0x2);
        vm.prank(userAddress);
        vm.expectRevert("uADMGR: Caller is not admin");
        uadManager.setFormulasAddress(mockAddress);
    }

    function testSetFormulasAddress_ShouldSetAddress() public {
        address mockAddress = address(0x2);
        vm.prank(admin);
        uadManager.setFormulasAddress(mockAddress);
        assertEq(uadManager.formulasAddress(), mockAddress);
    }

    function testSetBondingShareAddress_ShouldRevert_IfCalledNotByAdmin() public {
        address mockAddress = address(0x2);
        vm.prank(userAddress);
        vm.expectRevert("uADMGR: Caller is not admin");
        uadManager.setBondingShareAddress(mockAddress);
    }

    function testSetBondingShareAddress_ShouldSetAddress() public {
        address mockAddress = address(0x2);
        vm.prank(admin);
        uadManager.setBondingShareAddress(mockAddress);
        assertEq(uadManager.bondingShareAddress(), mockAddress);
    }

    function testSetStableSwapMetaPoolAddress_ShouldRevert_IfCalledNotByAdmin() public {
        address mockAddress = address(0x2);
        vm.prank(userAddress);
        vm.expectRevert("uADMGR: Caller is not admin");
        uadManager.setStableSwapMetaPoolAddress(mockAddress);
    }

    function testSetStableSwapMetaPoolAddress_ShouldSetAddress() public {
        address mockAddress = address(0x2);
        vm.prank(admin);
        uadManager.setStableSwapMetaPoolAddress(mockAddress);
        assertEq(uadManager.stableSwapMetaPoolAddress(), mockAddress);
    }

    function testSetBondingContractAddress_ShouldRevert_IfCalledNotByAdmin() public {
        address mockAddress = address(0x2);
        vm.prank(userAddress);
        vm.expectRevert("uADMGR: Caller is not admin");
        uadManager.setBondingContractAddress(mockAddress);
    }

    function testSetBondingContractAddress_ShouldSetAddress() public {
        address mockAddress = address(0x2);
        vm.prank(admin);
        uadManager.setBondingContractAddress(mockAddress);
        assertEq(uadManager.bondingContractAddress(), mockAddress);
    }

    function testSetTreasuryAddress_ShouldRevert_IfCalledNotByAdmin() public {
        address mockAddress = address(0x2);
        vm.prank(userAddress);
        vm.expectRevert("uADMGR: Caller is not admin");
        uadManager.setTreasuryAddress(mockAddress);
    }

    function testSetTreasuryAddress_ShouldSetAddress() public {
        address mockAddress = address(0x2);
        vm.prank(admin);
        uadManager.setTreasuryAddress(mockAddress);
        assertEq(uadManager.treasuryAddress(), mockAddress);
    }

    function testDeployStableSwapPool_ShouldRevert_IfCalledNotByAdmin() public {
        vm.prank(userAddress);
        vm.expectRevert("uADMGR: Caller is not admin");
        uadManager.deployStableSwapPool(
            address(0),
            address(0),
            address(0),
            0,
            0
        );
    }

    function testDeployStableSwapPool_ShouldRevert_IfCoinOrderMismatch() public {
        address crvFactoryAddress = address(0x2);
        address crvBasePoolAddress = address(0x3);
        address stableSwapMetaPoolAddress = address(0x4);
        MockERC20 crv3PoolToken = new MockERC20("crv3PoolToken", "crv3PoolToken", 18);

        // admin deploys UAD token
        vm.prank(admin);
        UbiquityAlgorithmicDollar uadToken = new UbiquityAlgorithmicDollar(address(uadManager));

        // admin sets UAD address in uad manager contract
        vm.prank(admin);
        uadManager.setDollarTokenAddress(address(uadToken));

        // prepare mocks
        vm.mockCall(
            crvFactoryAddress,
            abi.encodeWithSelector(ICurveFactory.deploy_metapool.selector),
            abi.encode(stableSwapMetaPoolAddress)
        );
        vm.mockCall(
            stableSwapMetaPoolAddress,
            abi.encodeWithSelector(IMetaPool.coins.selector, 0),
            abi.encode(address(crv3PoolToken))
        );
        vm.mockCall(
            stableSwapMetaPoolAddress,
            abi.encodeWithSelector(IMetaPool.coins.selector, 1),
            abi.encode(address(uadToken))
        );

        // deploy pool
        vm.prank(admin);
        vm.expectRevert("uADMGR: COIN_ORDER_MISMATCH");
        uadManager.deployStableSwapPool(
            crvFactoryAddress,
            crvBasePoolAddress,
            address(crv3PoolToken),
            0,
            0
        );
    }

    function testDeployStableSwapPool_ShouldDeployPool() public {
        address crvFactoryAddress = address(0x2);
        address crvBasePoolAddress = address(0x3);
        address stableSwapMetaPoolAddress = address(0x4);
        MockERC20 crv3PoolToken = new MockERC20("crv3PoolToken", "crv3PoolToken", 18);

        // admin deploys UAD token
        vm.prank(admin);
        UbiquityAlgorithmicDollar uadToken = new UbiquityAlgorithmicDollar(address(uadManager));

        // admin sets UAD address in uad manager contract
        vm.prank(admin);
        uadManager.setDollarTokenAddress(address(uadToken));

        // prepare mocks
        vm.mockCall(
            crvFactoryAddress,
            abi.encodeWithSelector(ICurveFactory.deploy_metapool.selector),
            abi.encode(stableSwapMetaPoolAddress)
        );
        vm.mockCall(
            stableSwapMetaPoolAddress,
            abi.encodeWithSelector(IMetaPool.coins.selector, 0),
            abi.encode(address(uadToken))
        );
        vm.mockCall(
            stableSwapMetaPoolAddress,
            abi.encodeWithSelector(IMetaPool.coins.selector, 1),
            abi.encode(address(crv3PoolToken))
        );

        // deploy pool
        vm.prank(admin);
        uadManager.deployStableSwapPool(
            crvFactoryAddress,
            crvBasePoolAddress,
            address(crv3PoolToken),
            0,
            0
        );

        // assert
        assertEq(uadManager.stableSwapMetaPoolAddress(), stableSwapMetaPoolAddress);
        assertEq(uadManager.curve3PoolTokenAddress(), address(crv3PoolToken));
    }

    function testGetExcessDollarsDistributor_ShouldReturnDistributor() public {
        address debtCouponManagerAddress = address(0x2);
        address excessCouponDistributorAddress = address(0x3);
        vm.prank(admin);
        uadManager.setExcessDollarsDistributor(debtCouponManagerAddress, excessCouponDistributorAddress);
        assertEq(uadManager.getExcessDollarsDistributor(debtCouponManagerAddress), excessCouponDistributorAddress);
    }
}
