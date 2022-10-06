// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {UbiquityAlgorithmicDollarManager} from "../../src/dollar/UbiquityAlgorithmicDollarManager.sol";
import {UbiquityGovernance} from "../../src/dollar/UbiquityGovernance.sol";
import {UARForDollarsCalculator} from "../../src/dollar/UARForDollarsCalculator.sol";
import {CouponsForDollarsCalculator} from "../../src/dollar/CouponsForDollarsCalculator.sol";
import {DollarMintingCalculator} from "../../src/dollar/DollarMintingCalculator.sol";
import {ExcessDollarsDistributor} from "../../src/dollar/ExcessDollarsDistributor.sol";
import {MockDebtCoupon} from "../../src/dollar/mocks/MockDebtCoupon.sol";
import {MockuADToken} from "../../src/dollar/mocks/MockuADToken.sol";
import {MockTWAPOracle} from "../../src/dollar/mocks/MockTWAPOracle.sol";
import {MockAutoRedeem} from "../../src/dollar/mocks/MockAutoRedeem.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract MockCouponsForDollarsCalculator {
    constructor() {}

    function getCouponAmount(uint256 dollarsToBurn) external view returns (uint256) {
        return dollarsToBurn;
    }
}

abstract contract TestHelper is Test {
    address public constant NATIVE_ASSET = address(0);

    address public admin = address(0x123abc);
    address public treasuryAddress = address(0x111222333);

    function helpers_deployUbiquityAlgorithmicDollarManager() public returns (address) {
        UbiquityAlgorithmicDollarManager _manager = new UbiquityAlgorithmicDollarManager(admin);

        vm.startPrank(admin);
        // deploy debt token
        MockDebtCoupon _debtCoupon = new MockDebtCoupon(100);
        _manager.setDebtCouponAddress(address(_debtCoupon));

        // deploy uAD token
        MockuADToken _uAD = new MockuADToken(10000e18);
        _manager.setDollarTokenAddress(address(_uAD));

        // deploy twapPrice oracle
        MockTWAPOracle _twapOracle = new MockTWAPOracle(address(0x100), address(_uAD), address(0x101), 100, 100);
        _manager.setTwapOracleAddress(address(_twapOracle));

        // deploy governance token
        UbiquityGovernance _uGov = new UbiquityGovernance(address(_manager));
        _manager.setGovernanceTokenAddress(address(_uGov));

        // deploy couponsForDollarCalculator
        MockCouponsForDollarsCalculator couponsForDollarsCalculator = new MockCouponsForDollarsCalculator();
        _manager.setCouponCalculatorAddress(address(couponsForDollarsCalculator));

        // deploy ubiquityAutoRedeem
        MockAutoRedeem autoRedeem = new MockAutoRedeem(0);
        _manager.setuARTokenAddress(address(autoRedeem));

        // deploy UARDollarCalculator
        UARForDollarsCalculator _uarDollarCalculator = new UARForDollarsCalculator(address(_manager));
        _manager.setUARCalculatorAddress(address(_uarDollarCalculator));

        // deploy dollarMintingCalculator
        DollarMintingCalculator _mintingCalculator = new DollarMintingCalculator(address(_manager));
        _manager.setDollarMintingCalculatorAddress(address(_mintingCalculator));

        // set treasury address
        _manager.setTreasuryAddress(treasuryAddress);

        vm.stopPrank();

        return address(_manager);
    }
}
