// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {UbiquityDollarManager} from "../../../src/dollar/core/UbiquityDollarManager.sol";
import {TWAPOracleDollar3pool} from "../../../src/dollar/core/TWAPOracleDollar3pool.sol";
import {DollarMintCalculator} from "../../../src/dollar/core/DollarMintCalculator.sol";

import "../../helpers/LocalTestHelper.sol";

contract DollarMintCalculatorTest is LocalTestHelper {
    address dollarManagerAddress;
    address dollarAddress;
    address twapOracleAddress;
    address dollarMintCalculatorAddress;

    function setUp() public override {
        super.setUp();
        dollarManagerAddress = address(manager);
        twapOracleAddress = UbiquityDollarManager(dollarManagerAddress)
            .twapOracleAddress();
        dollarMintCalculatorAddress = UbiquityDollarManager(
            dollarManagerAddress
        ).dollarMintCalculatorAddress();
        dollarAddress = UbiquityDollarManager(dollarManagerAddress)
            .dollarTokenAddress();
    }

    function mockTwapFuncs(uint256 _twapPrice) public {
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

    function test_getDollarsToMintRevertsIfPriceLowerThan1USD() public {
        mockTwapFuncs(5e17);
        vm.expectRevert("DollarMintCalculator: not > 1");
        DollarMintCalculator(dollarMintCalculatorAddress).getDollarsToMint();
    }

    function test_getDollarsToMintWorks() public {
        mockTwapFuncs(2e18);
        uint256 totalSupply = MockDollarToken(dollarAddress).totalSupply();
        uint256 amountToMint = DollarMintCalculator(dollarMintCalculatorAddress)
            .getDollarsToMint();
        assertEq(amountToMint, totalSupply);
    }
}
