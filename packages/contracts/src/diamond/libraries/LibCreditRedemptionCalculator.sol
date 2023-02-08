// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "abdk-libraries-solidity/ABDKMathQuad.sol";
import {CreditNft} from "../../dollar/core/CreditNft.sol";
import {LibAppStorage} from "./LibAppStorage.sol";

import "forge-std/console.sol";

/// @title Uses the following formula: ((1/(1-R)^2) - 1)
library LibCreditRedemptionCalculator {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    struct CreditRedemptionCalculatorData {
        uint256 coef;
    }

    function creditRedemptionCalculatorStorage()
        internal
        pure
        returns (CreditRedemptionCalculatorData storage l)
    {
        bytes32 slot = CREDIT_REDEMPTION_CALCULATOR_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    bytes32 constant CREDIT_REDEMPTION_CALCULATOR_STORAGE_SLOT =
        keccak256("ubiquity.contracts.credit.redemption.calculator.storage");

    /// @notice set the constant for Credit Token calculation
    /// @param coef new constant for Credit Token calculation in ETH format
    /// @dev a coef of 1 ether means 1
    function setConstant(uint256 coef) internal {
        creditRedemptionCalculatorStorage().coef = coef;
    }

    /// @notice get the constant for Credit Token calculation
    function getConstant() internal view returns (uint256) {
        return creditRedemptionCalculatorStorage().coef;
    }

    // dollarsToBurn * (blockHeight_debt/blockHeight_burn) * _coef
    function getCreditAmount(
        uint256 dollarsToBurn,
        uint256 blockHeightDebt
    ) internal view returns (uint256) {
        address creditNFTAddress = LibAppStorage.appStorage().creditNftAddress;
        CreditNft cNFT = CreditNft(creditNFTAddress);
        require(
            cNFT.getTotalOutstandingDebt() <
                IERC20(address(this)).totalSupply(),
            "Credit to Dollar: DEBT_TOO_HIGH"
        );
        bytes16 coef = creditRedemptionCalculatorStorage().coef.fromUInt().div(
            (uint256(1 ether)).fromUInt()
        );
        bytes16 curBlock = uint256(block.number).fromUInt();
        bytes16 multiplier = blockHeightDebt.fromUInt().div(curBlock);
        // x^a = e^(a*lnx(x)) so multiplier^(_coef) = e^(_coef*lnx(multiplier))
        bytes16 op = (coef.mul(multiplier.ln())).exp();
        uint256 res = dollarsToBurn.fromUInt().mul(op).toUInt();
        return res;
    }
}
