// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {UbiquityDollarManager} from
    "../../src/dollar/UbiquityDollarManager.sol";
import {UbiquityGovernanceToken} from "../../src/dollar/UbiquityGovernanceToken.sol";
import {CreditRedemptionCalculator} from
    "../../src/dollar/CreditRedemptionCalculator.sol";
import {CreditNFTRedemptionCalculator} from
    "../../src/dollar/CreditNFTRedemptionCalculator.sol";
import {DollarMintCalculator} from
    "../../src/dollar/DollarMintCalculator.sol";
import {DollarMintExcess} from
    "../../src/dollar/DollarMintExcess.sol";
import {MockDebtCoupon} from "../../src/dollar/mocks/MockDebtCoupon.sol";
import {MockDollarToken} from "../../src/dollar/mocks/MockDollarToken.sol";
import {MockTWAPOracleDollar3pool} from "../../src/dollar/mocks/MockTWAPOracleDollar3pool.sol";
import {MockCreditToken} from "../../src/dollar/mocks/MockCreditToken.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract MockCreditNFTRedemptionCalculator {
    constructor() {}

    function getCouponAmount(uint256 dollarsToBurn)
        external
        pure
        returns (uint256)
    {
        return dollarsToBurn;
    }
}

abstract contract LocalTestHelper is Test {
    address public constant NATIVE_ASSET = address(0);

    address public admin = address(0x123abc);
    address public treasuryAddress = address(0x111222333);

    function helpers_deployUbiquityDollarManager()
        public
        returns (address)
    {
        UbiquityDollarManager _manager =
            new UbiquityDollarManager(admin);

        vm.startPrank(admin);
        // deploy debt token
        MockDebtCoupon _debtCoupon = new MockDebtCoupon(100);
        _manager.setDebtCouponAddress(address(_debtCoupon));

        // deploy uAD token
        MockDollarToken _uAD = new MockDollarToken(10000e18);
        _manager.setDollarTokenAddress(address(_uAD));

        // deploy twapPrice oracle
        MockTWAPOracleDollar3pool _twapOracle =
        new MockTWAPOracleDollar3pool(address(0x100), address(_uAD), address(0x101), 100, 100);
        _manager.setTwapOracleAddress(address(_twapOracle));

        // deploy governance token
        UbiquityGovernanceToken _uGov = new UbiquityGovernanceToken(address(_manager));
        _manager.setGovernanceTokenAddress(address(_uGov));

        // deploy couponsForDollarCalculator
        MockCreditNFTRedemptionCalculator couponsForDollarsCalculator =
            new MockCreditNFTRedemptionCalculator();
        _manager.setCouponCalculatorAddress(
            address(couponsForDollarsCalculator)
        );

        // deploy ubiquityAutoRedeem
        MockCreditToken autoRedeem = new MockCreditToken(0);
        _manager.setuARTokenAddress(address(autoRedeem));

        // deploy UARDollarCalculator
        CreditRedemptionCalculator _uarDollarCalculator =
            new CreditRedemptionCalculator(address(_manager));
        _manager.setUARCalculatorAddress(address(_uarDollarCalculator));

        // deploy dollarMintingCalculator
        DollarMintCalculator _mintingCalculator =
            new DollarMintCalculator(address(_manager));
        _manager.setDollarMintingCalculatorAddress(address(_mintingCalculator));

        // set treasury address
        _manager.setTreasuryAddress(treasuryAddress);

        vm.stopPrank();

        return address(_manager);
    }
}
