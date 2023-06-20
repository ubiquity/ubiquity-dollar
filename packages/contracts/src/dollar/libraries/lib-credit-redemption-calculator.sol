// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ierc-20.sol";
import "abdk-libraries-solidity/abdk-math-quad.sol";
import {CreditNft} from "../../dollar/core/CreditNft.sol";
import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";

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
        bytes32(
            uint256(
                keccak256(
                    "ubiquity.contracts.credit.redemption.calculator.storage"
                )
            ) - 1
        );

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
        AppStorage storage store = LibAppStorage.appStorage();
        address creditNFTAddress = store.creditNftAddress;
        CreditNft cNFT = CreditNft(creditNFTAddress);
        require(
            cNFT.getTotalOutstandingDebt() <
                IERC20(store.dollarTokenAddress).totalSupply(),
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
