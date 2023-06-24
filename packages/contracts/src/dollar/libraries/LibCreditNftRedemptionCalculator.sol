// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "abdk/ABDKMathQuad.sol";

import {CreditNft} from "../../dollar/core/CreditNft.sol";
import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";

/// @title Uses the following formula: ((1/(1-R)^2) - 1)
library LibCreditNftRedemptionCalculator {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    function getCreditNFTAmount(
        uint256 dollarsToBurn
    ) internal view returns (uint256) {
        AppStorage storage store = LibAppStorage.appStorage();
        address creditNFTAddress = store.creditNftAddress;
        CreditNft cNFT = CreditNft(creditNFTAddress);
        require(
            cNFT.getTotalOutstandingDebt() <
                IERC20(store.dollarTokenAddress).totalSupply(),
            "CreditNFT to Dollar: DEBT_TOO_HIGH"
        );
        bytes16 one = uint256(1).fromUInt();
        bytes16 totalDebt = cNFT.getTotalOutstandingDebt().fromUInt();
        bytes16 r = totalDebt.div(
            IERC20(store.dollarTokenAddress).totalSupply().fromUInt()
        );

        bytes16 oneMinusRAllSquared = (one.sub(r)).mul(one.sub(r));
        bytes16 res = one.div(oneMinusRAllSquared);
        return res.mul(dollarsToBurn.fromUInt()).toUInt();
    }
}
