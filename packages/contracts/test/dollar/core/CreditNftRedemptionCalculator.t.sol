// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UbiquityDollarManager} from "../../../src/dollar/core/UbiquityDollarManager.sol";
import {CreditNftRedemptionCalculator} from "../../../src/dollar/core/CreditNftRedemptionCalculator.sol";
import {CreditNft} from "../../../src/dollar/core/CreditNft.sol";
import {MockCreditNft} from "../../../src/dollar/mocks/MockCreditNft.sol";

import "../../helpers/LocalTestHelper.sol";

contract CreditNftRedemptionCalculatorTest is LocalTestHelper {
    address dollarManagerAddress;
    address creditNftCalculatorAddress;

    function setUp() public {
        dollarManagerAddress = helpers_deployUbiquityDollarManager();
        creditNftCalculatorAddress = address(
            new CreditNftRedemptionCalculator(dollarManagerAddress)
        );
    }

    function test_getCreditNftAmount_revertsIfDebtTooHigh() public {
        uint256 totalSupply = IERC20(
            UbiquityDollarManager(dollarManagerAddress).dollarTokenAddress()
        ).totalSupply();
        MockCreditNft(
            UbiquityDollarManager(dollarManagerAddress).creditNftAddress()
        ).setTotalOutstandingDebt(totalSupply + 1);

        vm.expectRevert("CreditNFT to Dollar: DEBT_TOO_HIGH");
        CreditNftRedemptionCalculator(creditNftCalculatorAddress)
            .getCreditNftAmount(0);
    }

    function test_getCreditNftAmount() public {
        uint256 totalSupply = IERC20(
            UbiquityDollarManager(dollarManagerAddress).dollarTokenAddress()
        ).totalSupply();
        MockCreditNft(
            UbiquityDollarManager(dollarManagerAddress).creditNftAddress()
        ).setTotalOutstandingDebt(totalSupply / 2);
        assertEq(
            CreditNftRedemptionCalculator(creditNftCalculatorAddress)
                .getCreditNftAmount(10000),
            40000
        );
    }
}
