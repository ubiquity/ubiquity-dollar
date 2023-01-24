// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 
import "abdk-libraries-solidity/ABDKMathQuad.sol";

import {CreditNFT} from "../../dollar/core/CreditNFT.sol";



/// @title Uses the following formula: ((1/(1-R)^2) - 1)
library LibCreditNFTRedemptionCalculator  {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;
 

    /*   using ABDKMath64x64 for uint256;
    using ABDKMath64x64 for int128;*/
 
    function getCreditNFTAmount(
        uint256 dollarsToBurn
    ) internal view override returns (uint256) {
        address creditNFTAddress= LibAppStorage.appStorage().creditNFTAddress;
        CreditNFT cNFT = CreditNFT(creditNFTAddress);
        require(
            cNFT.getTotalOutstandingDebt() <
                IERC20(address(this)).totalSupply(),
            "CreditNFT to Dollar: DEBT_TOO_HIGH"
        );
        bytes16 one = uint256(1).fromUInt();
        bytes16 totalDebt = cNFT
            .getTotalOutstandingDebt()
            .fromUInt();
        bytes16 r = totalDebt.div(
            IERC20(address(this)).totalSupply().fromUInt()
        );

        bytes16 oneMinusRAllSquared = (one.sub(r)).mul(one.sub(r));
        bytes16 res = one.div(oneMinusRAllSquared);
        return res.mul(dollarsToBurn.fromUInt()).toUInt();
    }
}
