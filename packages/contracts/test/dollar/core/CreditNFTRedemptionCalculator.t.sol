// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UbiquityDollarManager} from "../../../src/dollar/core/UbiquityDollarManager.sol";
import {CreditNftRedemptionCalculator} from "../../../src/dollar/core/CreditNftRedemptionCalculator.sol";
import {CreditNft} from "../../../src/dollar/core/CreditNft.sol";
import {MockCreditNft} from "../../../src/dollar/mocks/MockCreditNft.sol";

import "../../helpers/LocalTestHelper.sol";

contract CreditNFTRedemptionCalculatorTest is LocalTestHelper {
    address dollarManagerAddress;
    address creditNFTCalculatorAddress;

    function setUp() public override {
        super.setUp();
        dollarManagerAddress = address(manager);
        creditNFTCalculatorAddress = address(
            new CreditNftRedemptionCalculator(manager)
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
        CreditNftRedemptionCalculator(creditNFTCalculatorAddress)
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
            CreditNftRedemptionCalculator(creditNFTCalculatorAddress)
                .getCreditNftAmount(10000),
            40000
        );
    }
}
