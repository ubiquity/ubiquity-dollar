// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../DiamondTestSetup.sol";
import {IMetaPool} from "../../../src/dollar/interfaces/IMetaPool.sol";
import {MockMetaPool} from "../../../src/dollar/mocks/MockMetaPool.sol";
import {MockERC20} from "../../../src/dollar/mocks/MockERC20.sol";
import {ICurveFactory} from "../../../src/dollar/interfaces/ICurveFactory.sol";
import {MockCurveFactory} from "../../../src/dollar/mocks/MockCurveFactory.sol";

import {IERC20Ubiquity} from "../../../src/dollar/interfaces/IERC20Ubiquity.sol";
import {StakingShare} from "../../../src/dollar/core/StakingShare.sol";
import {BondingShare} from "../../../src/dollar/mocks/MockShareV1.sol";
import {DollarMintCalculatorFacet} from "../../../src/dollar/facets/DollarMintCalculatorFacet.sol";
import {UbiquityCreditToken} from "../../../src/dollar/core/UbiquityCreditToken.sol";

contract UbiquityPoolFacetTest is DiamondTestSetup {
    MockERC20 crvToken;
    address curve3CrvToken;
    address metaPoolAddress;
    address twapOracleAddress;

    IMetaPool metapool;
    address stakingMinAccount = address(0x9);
    address stakingMaxAccount = address(0x10);
    address secondAccount = address(0x4);
    address thirdAccount = address(0x5);
    address fourthAccount = address(0x6);
    address fifthAccount = address(0x7);
    address stakingZeroAccount = address(0x8);

    function setUp() public override {
        super.setUp();
        crvToken = new MockERC20("3 CRV", "3CRV", 18);
        curve3CrvToken = address(crvToken);
        metaPoolAddress = address(
            new MockMetaPool(address(dollarToken), curve3CrvToken)
        );

        vm.startPrank(owner);

        twapOracleDollar3PoolFacet.setPool(metaPoolAddress, curve3CrvToken);

        address[7] memory mintings = [
            admin,
            address(diamond),
            owner,
            fourthAccount,
            stakingZeroAccount,
            stakingMinAccount,
            stakingMaxAccount
        ];

        for (uint256 i = 0; i < mintings.length; ++i) {
            deal(address(dollarToken), mintings[i], 10000e18);
        }

        address[5] memory crvDeal = [
            address(diamond),
            owner,
            stakingMaxAccount,
            stakingMinAccount,
            fourthAccount
        ];
        vm.stopPrank();
        for (uint256 i; i < crvDeal.length; ++i) {
            crvToken.mint(crvDeal[i], 10000e18);
        }

        vm.startPrank(admin);
        managerFacet.setStakingShareAddress(address(stakingShare));
        stakingShare.setApprovalForAll(address(diamond), true);
        accessControlFacet.grantRole(
            GOVERNANCE_TOKEN_MINTER_ROLE,
            address(stakingShare)
        );
        //  vm.stopPrank();
        ICurveFactory curvePoolFactory = ICurveFactory(new MockCurveFactory());
        address curve3CrvBasePool = address(
            new MockMetaPool(address(diamond), address(crvToken))
        );
        //vm.prank(admin);
        managerFacet.deployStableSwapPool(
            address(curvePoolFactory),
            curve3CrvBasePool,
            curve3CrvToken,
            10,
            50000000
        );
        //
        metapool = IMetaPool(managerFacet.stableSwapMetaPoolAddress());
        metapool.transfer(address(stakingFacet), 100e18);
        metapool.transfer(secondAccount, 1000e18);
        vm.stopPrank();
        vm.prank(owner);
        twapOracleDollar3PoolFacet.setPool(address(metapool), curve3CrvToken);

        vm.startPrank(admin);

        accessControlFacet.grantRole(GOVERNANCE_TOKEN_MANAGER_ROLE, admin);
        accessControlFacet.grantRole(CREDIT_NFT_MANAGER_ROLE, address(diamond));
        accessControlFacet.grantRole(
            GOVERNANCE_TOKEN_MINTER_ROLE,
            address(diamond)
        );

        accessControlFacet.grantRole(
            GOVERNANCE_TOKEN_BURNER_ROLE,
            address(diamond)
        );
        managerFacet.setCreditTokenAddress(address(creditToken));

        vm.stopPrank();

        vm.startPrank(stakingMinAccount);
        dollarToken.approve(address(metapool), 10000e18);
        crvToken.approve(address(metapool), 10000e18);
        vm.stopPrank();

        vm.startPrank(stakingMaxAccount);
        dollarToken.approve(address(metapool), 10000e18);
        crvToken.approve(address(metapool), 10000e18);
        vm.stopPrank();
        vm.startPrank(fourthAccount);
        dollarToken.approve(address(metapool), 10000e18);
        crvToken.approve(address(metapool), 10000e18);
        vm.stopPrank();

        uint256[2] memory amounts_ = [uint256(100e18), uint256(100e18)];

        uint256 dyuAD2LP = metapool.calc_token_amount(amounts_, true);

        vm.prank(stakingMinAccount);
        metapool.add_liquidity(
            amounts_,
            (dyuAD2LP * 99) / 100,
            stakingMinAccount
        );

        vm.prank(stakingMaxAccount);
        metapool.add_liquidity(
            amounts_,
            (dyuAD2LP * 99) / 100,
            stakingMaxAccount
        );

        vm.prank(fourthAccount);
        metapool.add_liquidity(amounts_, (dyuAD2LP * 99) / 100, fourthAccount);
    }

    function test_setRedeemActiveShouldWorkIfAdmin() public {
        vm.prank(admin);
        ubiquityPoolFacet.setRedeemActive(address(0x333), true);
        assertEq(ubiquityPoolFacet.getRedeemActive(address(0x333)), true);
    }

    function test_setRedeemActiveShouldFailIfNotAdmin() public {
        vm.expectRevert("Manager: Caller is not admin");
        ubiquityPoolFacet.setRedeemActive(address(0x333), true);
    }

    function test_setMintActiveShouldWorkIfAdmin() public {
        vm.prank(admin);
        ubiquityPoolFacet.setMintActive(address(0x333), true);
        assertEq(ubiquityPoolFacet.getMintActive(address(0x333)), true);
    }

    function test_setMintActiveShouldFailIfNotAdmin() public {
        vm.expectRevert("Manager: Caller is not admin");
        ubiquityPoolFacet.setMintActive(address(0x333), true);
    }

    function test_addTokenShouldWorkIfAdmin() public {
        vm.prank(admin);
        ubiquityPoolFacet.addToken(
            address(dollarToken),
            IMetaPool(metaPoolAddress)
        );
    }

    function test_addTokenWithZeroAddressFail() public {
        vm.startPrank(admin);
        vm.expectRevert("0 address detected");
        ubiquityPoolFacet.addToken(address(0), IMetaPool(metaPoolAddress));
        vm.expectRevert("0 address detected");
        ubiquityPoolFacet.addToken(address(dollarToken), IMetaPool(address(0)));
        vm.stopPrank();
    }

    function test_addTokenShouldFailIfNotAdmin() public {
        vm.expectRevert("Manager: Caller is not admin");
        ubiquityPoolFacet.addToken(
            address(dollarToken),
            IMetaPool(address(0x444))
        );
    }

    function test_mintDollarShouldFailWhenSlippageIsReached() public {
        MockERC20 collateral = new MockERC20("collateral", "collateral", 18);
        collateral.mint(fourthAccount, 10 ether);
        vm.prank(admin);
        ubiquityPoolFacet.addToken(address(collateral), (metapool));
        vm.prank(admin);
        ubiquityPoolFacet.setMintActive(address(collateral), true);
        vm.startPrank(fourthAccount);
        collateral.approve(address(ubiquityPoolFacet), type(uint256).max);
        vm.expectRevert("Slippage limit reached");
        ubiquityPoolFacet.mintDollar(
            address(collateral),
            10 ether,
            10000 ether
        );
        vm.stopPrank();
    }

    function test_mintDollarShouldWork() public {
        MockERC20 collateral = new MockERC20("collateral", "collateral", 18);
        collateral.mint(fourthAccount, 10 ether);
        vm.prank(admin);
        ubiquityPoolFacet.addToken(address(collateral), (metapool));
        assertEq(collateral.balanceOf(fourthAccount), 10 ether);
        vm.prank(admin);
        ubiquityPoolFacet.setMintActive(address(collateral), true);
        vm.startPrank(fourthAccount);
        collateral.approve(address(ubiquityPoolFacet), type(uint256).max);

        uint256 balanceBefore = dollarToken.balanceOf(fourthAccount);
        ubiquityPoolFacet.mintDollar(address(collateral), 1 ether, 0 ether);
        assertGt(dollarToken.balanceOf(fourthAccount), balanceBefore);
        vm.stopPrank();
    }

    function test_redeemDollarShouldFailWhenDollarIAboveOne() public {
        MockERC20 collateral = new MockERC20("collateral", "collateral", 18);
        collateral.mint(fourthAccount, 10 ether);
        vm.prank(admin);
        ubiquityPoolFacet.addToken(address(collateral), (metapool));
        assertEq(collateral.balanceOf(fourthAccount), 10 ether);
        vm.prank(admin);
        ubiquityPoolFacet.setMintActive(address(collateral), true);
        vm.startPrank(fourthAccount);
        collateral.approve(address(ubiquityPoolFacet), type(uint256).max);

        uint256 balanceBefore = dollarToken.balanceOf(fourthAccount);
        ubiquityPoolFacet.mintDollar(address(collateral), 1 ether, 0 ether);
        assertGt(dollarToken.balanceOf(fourthAccount), balanceBefore);
        vm.stopPrank();

        vm.prank(admin);
        ubiquityPoolFacet.setRedeemActive(address(collateral), true);
        vm.startPrank(fourthAccount);
        vm.expectRevert(
            "Ubiquity Dollar Token value must be less than 1 USD to redeem"
        );
        ubiquityPoolFacet.redeemDollar(address(collateral), 1 ether, 0 ether);
        vm.stopPrank();
    }

    function test_redeemDollarShouldWork() public {
        MockERC20 collateral = new MockERC20("collateral", "collateral", 18);
        collateral.mint(fourthAccount, 10 ether);
        vm.prank(admin);
        ubiquityPoolFacet.addToken(address(collateral), (metapool));
        assertEq(collateral.balanceOf(fourthAccount), 10 ether);
        vm.prank(admin);
        ubiquityPoolFacet.setMintActive(address(collateral), true);
        vm.startPrank(fourthAccount);
        collateral.approve(address(ubiquityPoolFacet), type(uint256).max);

        ubiquityPoolFacet.mintDollar(address(collateral), 10 ether, 0 ether);
        uint256 balanceBefore = dollarToken.balanceOf(fourthAccount);
        vm.stopPrank();
        MockMetaPool mock = MockMetaPool(
            managerFacet.stableSwapMetaPoolAddress()
        );
        // set the mock data for meta pool
        uint256[2] memory _price_cumulative_last = [
            uint256(100e18),
            uint256(42e16)
        ];
        uint256 _last_block_timestamp = 120000;
        uint256[2] memory _twap_balances = [uint256(100e18), uint256(42e16)];
        uint256[2] memory _dy_values = [uint256(100e18), uint256(42e16)];
        mock.updateMockParams(
            _price_cumulative_last,
            _last_block_timestamp,
            _twap_balances,
            _dy_values
        );
        twapOracleDollar3PoolFacet.update();
        vm.prank(admin);
        ubiquityPoolFacet.setRedeemActive(address(collateral), true);
        vm.startPrank(fourthAccount);
        ubiquityPoolFacet.redeemDollar(address(collateral), 1 ether, 0 ether);

        assertLt(dollarToken.balanceOf(fourthAccount), balanceBefore);
        vm.stopPrank();
    }

    function test_collectRedemptionShouldWork() public {
        MockERC20 collateral = new MockERC20("collateral", "collateral", 18);
        collateral.mint(fourthAccount, 10 ether);
        vm.prank(admin);
        ubiquityPoolFacet.addToken(address(collateral), (metapool));
        assertEq(collateral.balanceOf(fourthAccount), 10 ether);
        vm.prank(admin);
        ubiquityPoolFacet.setMintActive(address(collateral), true);
        vm.startPrank(fourthAccount);
        collateral.approve(address(ubiquityPoolFacet), type(uint256).max);

        ubiquityPoolFacet.mintDollar(address(collateral), 10 ether, 0 ether);
        uint256 balanceBefore = dollarToken.balanceOf(fourthAccount);
        uint256 balanceCollateralBefore = collateral.balanceOf(fourthAccount);
        vm.stopPrank();
        MockMetaPool mock = MockMetaPool(
            managerFacet.stableSwapMetaPoolAddress()
        );
        // set the mock data for meta pool
        uint256[2] memory _price_cumulative_last = [
            uint256(100e18),
            uint256(42e16)
        ];
        uint256 _last_block_timestamp = 120000;
        uint256[2] memory _twap_balances = [uint256(100e18), uint256(42e16)];
        uint256[2] memory _dy_values = [uint256(100e18), uint256(42e16)];
        mock.updateMockParams(
            _price_cumulative_last,
            _last_block_timestamp,
            _twap_balances,
            _dy_values
        );
        twapOracleDollar3PoolFacet.update();
        vm.prank(admin);
        ubiquityPoolFacet.setRedeemActive(address(collateral), true);
        vm.startPrank(fourthAccount);
        ubiquityPoolFacet.redeemDollar(address(collateral), 1 ether, 0 ether);

        assertLt(dollarToken.balanceOf(fourthAccount), balanceBefore);
        ubiquityPoolFacet.collectRedemption(address(collateral));
        assertGt(collateral.balanceOf(fourthAccount), balanceCollateralBefore);
        vm.stopPrank();
    }
}
