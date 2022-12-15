// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DiamondTestSetup.sol";
import "../../../src/dollar/interfaces/ICurveFactory.sol";
import "../../../src/dollar/interfaces/IMetaPool.sol";
import "../../../src/dollar/mocks/MockDollarToken.sol";
import "../../../src/dollar/mocks/MockTWAPOracleDollar3pool.sol";

import {GOVERNANCE_TOKEN_MINTER_ROLE, GOVERNANCE_TOKEN_BURNER_ROLE} from "../../../src/manager/libraries/LibAppStorage.sol";

contract TestManagerFacet is DiamondSetup {
    function testCanCallGeneralFunctions() public {
        IManagerFacet.getExcessDollarsDistributor(contract1);
    }

    function testShouldSetTwapOracleAddress() public prankAs(admin) {
        MockDollarToken dollarToken;
        dollarToken = new MockDollarToken(10000);
        // deploy twapPrice oracle
        MockTWAPOracleDollar3pool _twapOracle = new MockTWAPOracleDollar3pool(
            address(0x100),
            address(dollarToken),
            address(0x101),
            100,
            100
        );
        IManagerFacet.setTwapOracleAddress(address(_twapOracle));
        assertEq(IManagerFacet.getTwapOracleAddress(), address(_twapOracle));
    }

    function testShouldSetDollarTokenAddress() public prankAs(admin) {
        IManagerFacet.setDollarTokenAddress(contract1);
        assertEq(IManagerFacet.getDollarTokenAddress(), contract1);
    }

    function testShouldSetCreditTokenAddress() public prankAs(admin) {
        IManagerFacet.setCreditTokenAddress(contract1);
        assertEq(IManagerFacet.getCreditTokenAddress(), contract1);
    }

    function testShouldSetCreditNFTAddress() public prankAs(admin) {
        IManagerFacet.setCreditNFTAddress(contract1);
        assertEq(IManagerFacet.getCreditNFTAddress(), contract1);
    }

    function testShouldSetGovernanceTokenAddress() public prankAs(admin) {
        IManagerFacet.setGovernanceTokenAddress(contract1);
        assertEq(IManagerFacet.getGovernanceTokenAddress(), contract1);
    }

    function testShouldSetSushiSwapPoolAddress() public prankAs(admin) {
        IManagerFacet.setSushiSwapPoolAddress(contract1);
        assertEq(IManagerFacet.getSushiSwapPoolAddress(), contract1);
    }

    function testShouldSetCreditCalculatorAddress() public prankAs(admin) {
        IManagerFacet.setCreditCalculatorAddress(contract1);
        assertEq(IManagerFacet.getCreditCalculatorAddress(), contract1);
    }

    function testShouldSetCreditNFTCalculatorAddress() public prankAs(admin) {
        IManagerFacet.setCreditNFTCalculatorAddress(contract1);
        assertEq(IManagerFacet.getCreditNFTCalculatorAddress(), contract1);
    }

    function testShouldSetDollarMintCalculatorAddress() public prankAs(admin) {
        IManagerFacet.setDollarMintCalculatorAddress(contract1);
        assertEq(IManagerFacet.getDollarMintCalculatorAddress(), contract1);
    }

    function testShouldSetExcessDollarsDistributor() public prankAs(admin) {
        IManagerFacet.setExcessDollarsDistributor(contract1, contract2);
        assertEq(
            IManagerFacet.getExcessDollarsDistributor(contract1),
            contract2
        );
    }

    function testShouldSetMasterChefAddress() public prankAs(admin) {
        IManagerFacet.setMasterChefAddress(contract1);
        assertEq(IManagerFacet.getMasterChefAddress(), contract1);
    }

    function testShouldSetFormulasAddress() public prankAs(admin) {
        IManagerFacet.setFormulasAddress(contract1);
        assertEq(IManagerFacet.getFormulasAddress(), contract1);
    }

    function testShouldSetStakingShareAddress() public prankAs(admin) {
        IManagerFacet.setStakingShareAddress(contract1);
        assertEq(IManagerFacet.getStakingShareAddress(), contract1);
    }

    function testShouldSetStableSwapMetaPoolAddress() public prankAs(admin) {
        IManagerFacet.setStableSwapMetaPoolAddress(contract1);
        assertEq(IManagerFacet.getStableSwapMetaPoolAddress(), contract1);
    }

    function testShouldSetStakingContractAddress() public prankAs(admin) {
        IManagerFacet.setStakingContractAddress(contract1);
        assertEq(IManagerFacet.getStakingContractAddress(), contract1);
    }

    function testShouldSetTreasuryAddress() public prankAs(admin) {
        IManagerFacet.setTreasuryAddress(contract1);
        assertEq(IManagerFacet.getTreasuryAddress(), contract1);
    }

    function testShouldsetIncentiveToDollar() public prankAs(admin) {
        address dollarTokenAddress = generateAddress(
            "dollarTokenAddress",
            true,
            10 ether
        );
        IManagerFacet.setDollarTokenAddress(dollarTokenAddress);
        IManagerFacet.setIncentiveToDollar(user1, contract1);
    }

    function testShouldSetMinterRoleWhenInitializing() public prankAs(admin) {
        assertEq(
            IManagerFacet.hasRole(GOVERNANCE_TOKEN_MINTER_ROLE, admin),
            true
        );
    }

    function testShouldInitializeDollarTokenAddress() public prankAs(admin) {
        assertEq(IManagerFacet.getDollarTokenAddress(), address(diamond));
    }

    function testShouldDeployStableSwapPool() public {
        vm.startPrank(admin);

        MockDollarToken dollarToken;

        dollarToken = new MockDollarToken(10000);

        IManagerFacet.setDollarTokenAddress(address(dollarToken));
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
            deal(address(dollarToken), mintings[i], 10000e18);
        }

        address stakingV1Address = generateAddress("stakingV1", true, 10 ether);
        IManagerFacet.grantRole(GOVERNANCE_TOKEN_MINTER_ROLE, stakingV1Address);
        IManagerFacet.grantRole(GOVERNANCE_TOKEN_BURNER_ROLE, stakingV1Address);

        deal(address(dollarToken), curveWhaleAddress, 10e18);

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

        IManagerFacet.deployStableSwapPool(
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
