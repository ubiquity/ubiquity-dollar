// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "abdk/ABDKMathQuad.sol";
import {CreditNft} from "../../dollar/core/CreditNft.sol";
import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";

/// @notice Library for calculating amount of Credits to mint on Dollars burn
library LibCreditRedemptionCalculator {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    /// @notice Struct used as a storage for the current library
    struct CreditRedemptionCalculatorData {
        uint256 coef;
    }

    /**
     * @notice Returns struct used as a storage for this library
     * @return l Struct used as a storage
     */
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

    /// @notice Storage slot used to store data for this library
    bytes32 constant CREDIT_REDEMPTION_CALCULATOR_STORAGE_SLOT =
        bytes32(
            uint256(
                keccak256(
                    "ubiquity.contracts.credit.redemption.calculator.storage"
                )
            ) - 1
        );

    /**
     * @notice Sets the `p` param in the Credit mint calculation formula:
     * `y = x * ((BlockDebtStart / BlockBurn) ^ p)`
     * @param coef New `p` param in wei
     */
    function setConstant(uint256 coef) internal {
        creditRedemptionCalculatorStorage().coef = coef;
    }

    /**
     * @notice Returns the `p` param used in the Credit mint calculation formula
     * @return `p` param
     */
    function getConstant() internal view returns (uint256) {
        return creditRedemptionCalculatorStorage().coef;
    }

    /**
     * @notice Returns amount of Credits to mint for `dollarsToBurn` amount of Dollars to burn
     * @param dollarsToBurn Amount of Dollars to burn
     * @param blockHeightDebt Block number when the latest debt cycle started (i.e. when Dollar price became < 1$)
     * @return Amount of Credits to mint
     */
    function getCreditAmount(
        uint256 dollarsToBurn,
        uint256 blockHeightDebt
    ) internal view returns (uint256) {
        AppStorage storage store = LibAppStorage.appStorage();
        address creditNftAddress = store.creditNftAddress;
        CreditNft cNFT = CreditNft(creditNftAddress);
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
