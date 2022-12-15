// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import 
    "../../../src/dollar/core/UbiquityDollarManager.sol";
import 
    "../../../src/dollar/core/UbiquityDollarToken.sol";
import 
    "../../../src/dollar/core/CreditNFTRedemptionCalculator.sol";
import "../../../src/dollar/core/TWAPOracleDollar3pool.sol";
import "../../../src/dollar/core/CreditNFT.sol";
import "../../../src/dollar/mocks/MockCreditNFT.sol";
import "../../../src/dollar/transfer-hooks/CurveDollarIncentive.sol";

import "../../helpers/LocalTestHelper.sol";

contract CurveDollarIncentiveTest is LocalTestHelper {
    address dollarManagerAddress;
    address curveIncentiveAddress;
    address twapOracleAddress;
    address stableSwapMetaPoolAddress = address(0x123);

    event ExemptAddressUpdate(address indexed _account, bool _isExempt);

    function setUp() public override {
        super.setUp();
        dollarManagerAddress = address(manager);
        curveIncentiveAddress =
            address(new CurveDollarIncentive(dollarManagerAddress));
        twapOracleAddress = UbiquityDollarManager(dollarManagerAddress)
            .twapOracleAddress();
        vm.prank(admin);
        UbiquityDollarManager(dollarManagerAddress)
            .setStableSwapMetaPoolAddress(stableSwapMetaPoolAddress);
    }

    function mockInternalFuncs(uint256 _twapPrice) public {
        vm.mockCall(
            twapOracleAddress,
            abi.encodeWithSelector(TWAPOracleDollar3pool.update.selector),
            abi.encode()
        );
        vm.mockCall(
            twapOracleAddress,
            abi.encodeWithSelector(TWAPOracleDollar3pool.consult.selector),
            abi.encode(_twapPrice)
        );
    }

    function test_incentivize_revertsIfCallerNotUAD() public {
        vm.expectRevert("CurveIncentive: Caller is not Ubiquity Dollar");
        CurveDollarIncentive(curveIncentiveAddress).incentivize(
            address(0x111), address(0x112), admin, 100
        );
    }

    function test_incentivize_revertsIfSenderEqualToReceiver() public {
        vm.prank(
            UbiquityDollarManager(dollarManagerAddress)
                .dollarTokenAddress()
        );
        vm.expectRevert("CurveIncentive: cannot send self");
        CurveDollarIncentive(curveIncentiveAddress).incentivize(
            address(0x111), address(0x111), admin, 100
        );
    }

    function test_incentivize_buy() public {
        vm.startPrank(admin);
        manager.grantRole(manager.UBQ_MINTER_ROLE(), curveIncentiveAddress);
        address stableSwapPoolAddress = UbiquityDollarManager(
            dollarManagerAddress
        ).stableSwapMetaPoolAddress();
        IERC20 governanceToken = IERC20(
            UbiquityDollarManager(dollarManagerAddress)
                .governanceTokenAddress()
        );
        address dollarAddress = UbiquityDollarManager(dollarManagerAddress)
            .dollarTokenAddress();
        address mockReceiver = address(0x111);

        // 1. do nothing if the target address is included to exempt list
        uint256 init_balance = governanceToken.balanceOf(mockReceiver);
        
        CurveDollarIncentive(curveIncentiveAddress).setExemptAddress(
            mockReceiver, true
        );
        vm.stopPrank();
        vm.prank(dollarAddress);
        CurveDollarIncentive(curveIncentiveAddress).incentivize(
            stableSwapPoolAddress, mockReceiver, address(0), 100e18
        );

        uint256 last_balance = governanceToken.balanceOf(mockReceiver);
        assertEq(last_balance, init_balance);

        // 2. do nothing if buyIncentive is off
        init_balance = governanceToken.balanceOf(mockReceiver);
        vm.startPrank(admin);
        CurveDollarIncentive(curveIncentiveAddress).setExemptAddress(
            mockReceiver, false
        );
        CurveDollarIncentive(curveIncentiveAddress).switchBuyIncentive();
        vm.stopPrank();

        vm.prank(dollarAddress);
        CurveDollarIncentive(curveIncentiveAddress).incentivize(
            stableSwapPoolAddress, mockReceiver, address(0), 100e18
        );

        last_balance = governanceToken.balanceOf(mockReceiver);
        assertEq(last_balance, init_balance);

        // 3. do nothing if no incentive
        mockInternalFuncs(1e18);
        init_balance = governanceToken.balanceOf(mockReceiver);
        vm.startPrank(admin);
        CurveDollarIncentive(curveIncentiveAddress).setExemptAddress(
            mockReceiver, false
        );
        CurveDollarIncentive(curveIncentiveAddress).switchBuyIncentive();
        vm.stopPrank();

        vm.prank(dollarAddress);
        CurveDollarIncentive(curveIncentiveAddress).incentivize(
            stableSwapPoolAddress, mockReceiver, address(0), 100e18
        );

        last_balance = governanceToken.balanceOf(mockReceiver);
        assertEq(last_balance, init_balance);

        // 4. mint the incentive amount of tokens to the target address
        init_balance = governanceToken.balanceOf(mockReceiver);
        mockInternalFuncs(5e17);
        vm.prank(admin);
        UbiquityDollarManager(dollarManagerAddress).grantRole(
            keccak256("GOVERNANCE_TOKEN_MINTER_ROLE"), curveIncentiveAddress
        );
        vm.prank(dollarAddress);
        CurveDollarIncentive(curveIncentiveAddress).incentivize(
            stableSwapPoolAddress, mockReceiver, address(0), 100e18
        );

        last_balance = governanceToken.balanceOf(mockReceiver);
        assertEq(last_balance - init_balance, 50e18);
    }

    function test_incentivize_sell() public {
        address stableSwapPoolAddress = UbiquityDollarManager(
            dollarManagerAddress
        ).stableSwapMetaPoolAddress();
        IERC20 governanceToken = IERC20(
            UbiquityDollarManager(dollarManagerAddress)
                .governanceTokenAddress()
        );
        address dollarAddress = UbiquityDollarManager(dollarManagerAddress)
            .dollarTokenAddress();
        IERC20 dollarToken = IERC20(dollarAddress);
        address mockSender = address(0x222);

        // 1. do nothing if the target address is included to exempt list
        uint256 init_balance = dollarToken.balanceOf(mockSender);
        vm.prank(admin);
        CurveDollarIncentive(curveIncentiveAddress).setExemptAddress(
            mockSender, true
        );

        vm.prank(dollarAddress);
        CurveDollarIncentive(curveIncentiveAddress).incentivize(
            mockSender, stableSwapPoolAddress, address(0), 100e18
        );

        uint256 last_balance = dollarToken.balanceOf(mockSender);
        assertEq(last_balance, init_balance);

        // 2. do nothing if buyIncentive is off
        init_balance = dollarToken.balanceOf(mockSender);
        vm.startPrank(admin);
        CurveDollarIncentive(curveIncentiveAddress).setExemptAddress(
            mockSender, false
        );
        CurveDollarIncentive(curveIncentiveAddress).switchSellPenalty();
        vm.stopPrank();

        vm.prank(dollarAddress);
        CurveDollarIncentive(curveIncentiveAddress).incentivize(
            mockSender, stableSwapPoolAddress, address(0), 100e18
        );

        last_balance = dollarToken.balanceOf(mockSender);
        assertEq(last_balance, init_balance);

        // 3. do nothing if no penalty
        mockInternalFuncs(1e18);
        init_balance = dollarToken.balanceOf(mockSender);
        vm.startPrank(admin);
        CurveDollarIncentive(curveIncentiveAddress).setExemptAddress(
            mockSender, false
        );
        CurveDollarIncentive(curveIncentiveAddress).switchSellPenalty();
        vm.stopPrank();

        vm.prank(dollarAddress);
        CurveDollarIncentive(curveIncentiveAddress).incentivize(
            mockSender, stableSwapPoolAddress, address(0), 100e18
        );

        last_balance = dollarToken.balanceOf(mockSender);
        assertEq(last_balance, init_balance);

        // 4. burn the penalty amount of tokens from the target address
        vm.prank(admin);
        UbiquityDollarToken(dollarAddress).mint(mockSender, 10000e18);
        init_balance = dollarToken.balanceOf(mockSender);
        assertEq(init_balance, 10000e18);
        mockInternalFuncs(5e17);
        vm.prank(dollarAddress);
        CurveDollarIncentive(curveIncentiveAddress).incentivize(
            mockSender, stableSwapPoolAddress, address(0), 100e18
        );

        last_balance = dollarToken.balanceOf(mockSender);
        assertEq(init_balance - last_balance, 50e18);
    }

    function test_setExemptAddress() public {
        address exemptAddress = address(0x123);
        vm.expectRevert("CurveIncentive: not admin");
        CurveDollarIncentive(curveIncentiveAddress).setExemptAddress(
            exemptAddress, true
        );

        assertEq(
            CurveDollarIncentive(curveIncentiveAddress).isExemptAddress(
                exemptAddress
            ),
            false
        );
        vm.prank(admin);
        vm.expectEmit(true, true, false, true);
        emit ExemptAddressUpdate(exemptAddress, true);
        CurveDollarIncentive(curveIncentiveAddress).setExemptAddress(
            exemptAddress, true
        );
        assertEq(
            CurveDollarIncentive(curveIncentiveAddress).isExemptAddress(
                exemptAddress
            ),
            true
        );
    }

    function test_switchSellPenalty() public {
        vm.expectRevert("CurveIncentive: not admin");
        CurveDollarIncentive(curveIncentiveAddress).switchSellPenalty();

        assertEq(
            CurveDollarIncentive(curveIncentiveAddress).isSellPenaltyOn(), true
        );
        vm.prank(admin);
        CurveDollarIncentive(curveIncentiveAddress).switchSellPenalty();
        assertEq(
            CurveDollarIncentive(curveIncentiveAddress).isSellPenaltyOn(), false
        );
    }

    function test_switchBuyIncentive() public {
        vm.expectRevert("CurveIncentive: not admin");
        CurveDollarIncentive(curveIncentiveAddress).switchBuyIncentive();

        assertEq(
            CurveDollarIncentive(curveIncentiveAddress).isBuyIncentiveOn(), true
        );
        vm.prank(admin);
        CurveDollarIncentive(curveIncentiveAddress).switchBuyIncentive();
        assertEq(
            CurveDollarIncentive(curveIncentiveAddress).isBuyIncentiveOn(), false
        );
    }
}

       