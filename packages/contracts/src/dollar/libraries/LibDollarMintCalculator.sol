// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDollarMintCalculator} from "../../dollar/interfaces/IDollarMintCalculator.sol";
import "abdk/ABDKMathQuad.sol";
import "./LibTWAPOracle.sol";
import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";

/// @notice Calculates amount of Dollars ready to be minted when TWAP price (i.e. Dollar price) > 1$
library LibDollarMintCalculator {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    /**
     * @notice Returns amount of Dollars to be minted based on formula `(TWAP_PRICE - 1) * DOLLAR_TOTAL_SUPPLY`
     * @return Amount of Dollars to be minted
     */
    function getDollarsToMint() internal view returns (uint256) {
        AppStorage storage store = LibAppStorage.appStorage();
        uint256 twapPrice = LibTWAPOracle.consult(store.dollarTokenAddress);
        require(twapPrice > 1 ether, "DollarMintCalculator: not > 1");
        bytes16 _one = (uint256(1 ether)).fromUInt();
        return
            twapPrice
                .fromUInt()
                .sub(_one)
                .mul(
                    (
                        IERC20(store.dollarTokenAddress)
                            .totalSupply()
                            .fromUInt()
                            .div(_one)
                    )
                )
                .toUInt();
    }
}
