// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../src/dollar/core/UbiquityDollarManager.sol";
import "../../../src/dollar/core/CreditNFTRedemptionCalculator.sol";
import "../../../src/dollar/core/CreditNFT.sol";
import "../../../src/dollar/mocks/MockCreditNFT.sol";

import "../../helpers/LocalTestHelper.sol";

contract CreditNFTRedemptionCalculatorTest is LocalTestHelper {
    address dollarManagerAddress;
    address creditNFTCalculatorAddress;

    function setUp() public override {
        super.setUp();
        dollarManagerAddress = address(manager);
        creditNFTCalculatorAddress =
            address(new CreditNFTRedemptionCalculator(dollarManagerAddress));
    }

    function test_getCreditNFTAmount_revertsIfDebtTooHigh() public {
        uint256 totalSupply = IERC20(
            UbiquityDollarManager(dollarManagerAddress)
                .dollarTokenAddress()
        ).totalSupply();
        MockCreditNFT(
            UbiquityDollarManager(dollarManagerAddress)
                .creditNFTAddress()
        ).setTotalOutstandingDebt(totalSupply + 1);

        vm.expectRevert("CreditNFT to dollar: DEBT_TOO_HIGH");
        CreditNFTRedemptionCalculator(creditNFTCalculatorAddress)
            .getCreditNFTAmount(0);
    }

    function test_getCreditNFTAmount() public {
        uint256 totalSupply = IERC20(
            UbiquityDollarManager(dollarManagerAddress)
                .dollarTokenAddress()
        ).totalSupply();
        MockCreditNFT(
            UbiquityDollarManager(dollarManagerAddress)
                .creditNFTAddress()
        ).setTotalOutstandingDebt(totalSupply / 2);
        assertEq(
            CreditNFTRedemptionCalculator(creditNFTCalculatorAddress)
                .getCreditNFTAmount(10000),
            40000
        );
    }
}
