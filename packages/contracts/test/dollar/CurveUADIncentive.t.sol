// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UbiquityAlgorithmicDollarManager} from "../../src/dollar/UbiquityAlgorithmicDollarManager.sol";
import {CouponsForDollarsCalculator} from "../../src/dollar/CouponsForDollarsCalculator.sol";
import {TWAPOracle} from "../../src/dollar/TWAPOracle.sol";
import {DebtCoupon} from "../../src/dollar/DebtCoupon.sol";
import {MockDebtCoupon} from "../../src/dollar/mocks/MockDebtCoupon.sol";
import {CurveUADIncentive} from "../../src/dollar/CurveUADIncentive.sol";

import "../helpers/TestHelper.sol";

contract CurveUADIncentiveTest is TestHelper {
    address uADManagerAddress;
    address curveIncentiveAddress;
    address twapOracleAddress;
    address stableSwapMetaPoolAddress = address(0x123);

    function setUp() public {
        uADManagerAddress = helpers_deployUbiquityAlgorithmicDollarManager();
        curveIncentiveAddress = address(new CurveUADIncentive(uADManagerAddress));
        twapOracleAddress = UbiquityAlgorithmicDollarManager(uADManagerAddress).twapOracleAddress();
        vm.prank(admin);
        UbiquityAlgorithmicDollarManager(uADManagerAddress).setStableSwapMetaPoolAddress(stableSwapMetaPoolAddress);
    }

    function mockInternalFuncs(uint256 _deviation, uint256 _twapPrice) public {
        vm.mockCall(twapOracleAddress, abi.encodeWithSelector(TWAPOracle.update), abi.encode());
        vm.mockCall(twapOracleAddress, abi.encodeWithSelector(TWAPOracle.consult, abi.encode(_twapPrice)));
    }

    function test_incentivize_revertsIfCallerNotUAD() public {
        vm.expectRevert("CurveIncentive: Caller is not uAD");
        CurveUADIncentive(curveIncentiveAddress).incentivize(address(0x111), address(0x112), admin, 100);
    }

    function test_incentivize_revertsIfSenderEqualToReceiver() public {
        vm.prank(UbiquityAlgorithmicDollarManager(uADManagerAddress).dollarTokenAddress());
        vm.expectRevert("CurveIncentive: cannot send self");
        CurveUADIncentive(curveIncentiveAddress).incentivize(address(0x111), address(0x111), admin, 100);
    }

    function test_incentivize_buy() public {}

    function test_incentivize_sell() public {}

    function test_setExemptAddress () public {}

    function test_switchSellPenalty() public {}

    function test_switchBuyIncentive () public {}

    function test_isExemptAddress() public {}


}
