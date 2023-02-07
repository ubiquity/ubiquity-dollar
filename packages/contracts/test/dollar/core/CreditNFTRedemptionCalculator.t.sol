// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UbiquityDollarManager} from "../../../src/dollar/core/UbiquityDollarManager.sol";
import {CreditNFTRedemptionCalculator} from "../../../src/dollar/core/CreditNFTRedemptionCalculator.sol";
import {CreditNFT} from "../../../src/dollar/core/CreditNFT.sol";
import {MockCreditNFT} from "../../../src/dollar/mocks/MockCreditNFT.sol";

import "../../helpers/LocalTestHelper.sol";

contract CreditNFTRedemptionCalculatorTest is LocalTestHelper {
    address dollarManagerAddress;
    address creditNFTCalculatorAddress;

    function setUp() public override {
        super.setUp();
        dollarManagerAddress = address(manager);
        creditNFTCalculatorAddress = address(
            new CreditNFTRedemptionCalculator(manager)
        );
    }

    function test_getCreditNFTAmount_revertsIfDebtTooHigh() public {
        uint256 totalSupply = IERC20(
            UbiquityDollarManager(dollarManagerAddress).dollarTokenAddress()
        ).totalSupply();
        MockCreditNFT(
            UbiquityDollarManager(dollarManagerAddress).creditNFTAddress()
        ).setTotalOutstandingDebt(totalSupply + 1);

        vm.expectRevert("CreditNFT to Dollar: DEBT_TOO_HIGH");
        CreditNFTRedemptionCalculator(creditNFTCalculatorAddress)
            .getCreditNFTAmount(0);
    }

    function test_getCreditNFTAmount() public {
        uint256 totalSupply = IERC20(
            UbiquityDollarManager(dollarManagerAddress).dollarTokenAddress()
        ).totalSupply();
        MockCreditNFT(
            UbiquityDollarManager(dollarManagerAddress).creditNFTAddress()
        ).setTotalOutstandingDebt(totalSupply / 2);
        assertEq(
            CreditNFTRedemptionCalculator(creditNFTCalculatorAddress)
                .getCreditNFTAmount(10000),
            40000
        );
    }
}
