// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UbiquityDollarManager} from
    "../../../src/dollar/UbiquityDollarManager.sol";
import {UbiquityDollarToken} from
    "../../../src/dollar/UbiquityDollarToken.sol";
import {CreditNFTRedemptionCalculator} from
    "../../../src/dollar/CreditNFTRedemptionCalculator.sol";
import {TWAPOracleDollar3pool} from "../../../src/dollar/TWAPOracleDollar3pool.sol";
import {CreditNFT} from "../../../src/dollar/CreditNFT.sol";
import {MockCreditNFT} from "../../../src/dollar/mocks/MockCreditNFT.sol";
import {CurveDollarIncentive} from "../../../src/dollar/transfer-hooks/CurveDollarIncentive.sol";

import "../../helpers/LocalTestHelper.sol";

contract CurveDollarIncentiveTest is LocalTestHelper {
    address uADManagerAddress;
    address curveIncentiveAddress;
    address twapOracleAddress;
    address stableSwapMetaPoolAddress = address(0x123);

    event ExemptAddressUpdate(address indexed _account, bool _isExempt);

    function setUp() public {
        uADManagerAddress = helpers_deployUbiquityDollarManager();
        curveIncentiveAddress =
            address(new CurveDollarIncentive(uADManagerAddress));
        twapOracleAddress = UbiquityDollarManager(uADManagerAddress)
            .twapOracleAddress();
        vm.prank(admin);
        UbiquityDollarManager(uADManagerAddress)
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
        vm.expectRevert("CurveIncentive: Caller is not uAD");
        CurveDollarIncentive(curveIncentiveAddress).incentivize(
            address(0x111), address(0x112), admin, 100
        );
    }

    function test_incentivize_revertsIfSenderEqualToReceiver() public {
        vm.prank(
            UbiquityDollarManager(uADManagerAddress)
                .dollarTokenAddress()
        );
        vm.expectRevert("CurveIncentive: cannot send self");
        CurveDollarIncentive(curveIncentiveAddress).incentivize(
            address(0x111), address(0x111), admin, 100
        );
    }

    function test_incentivize_buy() public {
        address stableSwapPoolAddress = UbiquityDollarManager(
            uADManagerAddress
        ).stableSwapMetaPoolAddress();
        IERC20 govToken = IERC20(
            UbiquityDollarManager(uADManagerAddress)
                .governanceTokenAddress()
        );
        address uAD_addr = UbiquityDollarManager(uADManagerAddress)
            .dollarTokenAddress();
        address mockReceiver = address(0x111);

        // 1. do nothing if the target address is included to exempt list
        uint256 init_balance = govToken.balanceOf(mockReceiver);
        vm.prank(admin);
        CurveDollarIncentive(curveIncentiveAddress).setExemptAddress(
            mockReceiver, true
        );

        vm.prank(uAD_addr);
        CurveDollarIncentive(curveIncentiveAddress).incentivize(
            stableSwapPoolAddress, mockReceiver, address(0), 100e18
        );

        uint256 last_balance = govToken.balanceOf(mockReceiver);
        assertEq(last_balance, init_balance);

        // 2. do nothing if buyIncentive is off
        init_balance = govToken.balanceOf(mockReceiver);
        vm.startPrank(admin);
        CurveDollarIncentive(curveIncentiveAddress).setExemptAddress(
            mockReceiver, false
        );
        CurveDollarIncentive(curveIncentiveAddress).switchBuyIncentive();
        vm.stopPrank();

        vm.prank(uAD_addr);
        CurveDollarIncentive(curveIncentiveAddress).incentivize(
            stableSwapPoolAddress, mockReceiver, address(0), 100e18
        );

        last_balance = govToken.balanceOf(mockReceiver);
        assertEq(last_balance, init_balance);

        // 3. do nothing if no incentive
        mockInternalFuncs(1e18);
        init_balance = govToken.balanceOf(mockReceiver);
        vm.startPrank(admin);
        CurveDollarIncentive(curveIncentiveAddress).setExemptAddress(
            mockReceiver, false
        );
        CurveDollarIncentive(curveIncentiveAddress).switchBuyIncentive();
        vm.stopPrank();

        vm.prank(uAD_addr);
        CurveDollarIncentive(curveIncentiveAddress).incentivize(
            stableSwapPoolAddress, mockReceiver, address(0), 100e18
        );

        last_balance = govToken.balanceOf(mockReceiver);
        assertEq(last_balance, init_balance);

        // 4. mint the incentive amount of tokens to the target address
        init_balance = govToken.balanceOf(mockReceiver);
        mockInternalFuncs(5e17);
        vm.prank(admin);
        UbiquityDollarManager(uADManagerAddress).grantRole(
            keccak256("UBQ_MINTER_ROLE"), curveIncentiveAddress
        );
        vm.prank(uAD_addr);
        CurveDollarIncentive(curveIncentiveAddress).incentivize(
            stableSwapPoolAddress, mockReceiver, address(0), 100e18
        );

        last_balance = govToken.balanceOf(mockReceiver);
        assertEq(last_balance - init_balance, 50e18);
    }

    function test_incentivize_sell() public {
        address stableSwapPoolAddress = UbiquityDollarManager(
            uADManagerAddress
        ).stableSwapMetaPoolAddress();
        IERC20 govToken = IERC20(
            UbiquityDollarManager(uADManagerAddress)
                .governanceTokenAddress()
        );
        address uAD_addr = UbiquityDollarManager(uADManagerAddress)
            .dollarTokenAddress();
        IERC20 uADToken = IERC20(uAD_addr);
        address mockSender = address(0x222);

        // 1. do nothing if the target address is included to exempt list
        uint256 init_balance = uADToken.balanceOf(mockSender);
        vm.prank(admin);
        CurveDollarIncentive(curveIncentiveAddress).setExemptAddress(
            mockSender, true
        );

        vm.prank(uAD_addr);
        CurveDollarIncentive(curveIncentiveAddress).incentivize(
            mockSender, stableSwapPoolAddress, address(0), 100e18
        );

        uint256 last_balance = uADToken.balanceOf(mockSender);
        assertEq(last_balance, init_balance);

        // 2. do nothing if buyIncentive is off
        init_balance = uADToken.balanceOf(mockSender);
        vm.startPrank(admin);
        CurveDollarIncentive(curveIncentiveAddress).setExemptAddress(
            mockSender, false
        );
        CurveDollarIncentive(curveIncentiveAddress).switchSellPenalty();
        vm.stopPrank();

        vm.prank(uAD_addr);
        CurveDollarIncentive(curveIncentiveAddress).incentivize(
            mockSender, stableSwapPoolAddress, address(0), 100e18
        );

        last_balance = uADToken.balanceOf(mockSender);
        assertEq(last_balance, init_balance);

        // 3. do nothing if no penalty
        mockInternalFuncs(1e18);
        init_balance = uADToken.balanceOf(mockSender);
        vm.startPrank(admin);
        CurveDollarIncentive(curveIncentiveAddress).setExemptAddress(
            mockSender, false
        );
        CurveDollarIncentive(curveIncentiveAddress).switchSellPenalty();
        vm.stopPrank();

        vm.prank(uAD_addr);
        CurveDollarIncentive(curveIncentiveAddress).incentivize(
            mockSender, stableSwapPoolAddress, address(0), 100e18
        );

        last_balance = uADToken.balanceOf(mockSender);
        assertEq(last_balance, init_balance);

        // 4. burn the penalty amount of tokens from the target address
        vm.prank(admin);
        UbiquityDollarToken(uAD_addr).mint(mockSender, 10000e18);
        init_balance = uADToken.balanceOf(mockSender);
        assertEq(init_balance, 10000e18);
        mockInternalFuncs(5e17);
        vm.prank(uAD_addr);
        CurveDollarIncentive(curveIncentiveAddress).incentivize(
            mockSender, stableSwapPoolAddress, address(0), 100e18
        );

        last_balance = uADToken.balanceOf(mockSender);
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
