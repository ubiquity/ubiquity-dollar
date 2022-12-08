// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {UbiquityAlgorithmicDollarManager} from "../../src/dollar/UbiquityAlgorithmicDollarManager.sol";
import {TWAPOracleDollar3pool} from "../../src/dollar/TWAPOracleDollar3pool.sol";
import {DollarMintingCalculator} from "../../src/dollar/DollarMintingCalculator.sol";

import "../helpers/LocalTestHelper.sol";

contract DollarMintingCalculatorTest is LocalTestHelper {
    address uADManagerAddress;
    address uADAddress;
    address twapOracleAddress;
    address dollarMintingCalculatorAddress;

    function setUp() public {
        uADManagerAddress = helpers_deployUbiquityAlgorithmicDollarManager();
        twapOracleAddress = UbiquityAlgorithmicDollarManager(uADManagerAddress)
            .twapOracleAddress();
        dollarMintingCalculatorAddress = UbiquityAlgorithmicDollarManager(
            uADManagerAddress
        ).dollarMintingCalculatorAddress();
        uADAddress = UbiquityAlgorithmicDollarManager(uADManagerAddress)
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
        vm.expectRevert("DollarMintingCalculator: not > 1");
        DollarMintingCalculator(dollarMintingCalculatorAddress)
            .getDollarsToMint();
    }

    function test_getDollarsToMintWorks() public {
        mockTwapFuncs(2e18);
        uint256 totalSupply = MockDollarToken(uADAddress).totalSupply();
        uint256 amountToMint = DollarMintingCalculator(
            dollarMintingCalculatorAddress
        ).getDollarsToMint();
        assertEq(amountToMint, totalSupply);
    }
}
