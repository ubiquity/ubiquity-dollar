// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDollarMintCalculator} from "../../dollar/interfaces/IDollarMintCalculator.sol";
import "abdk-libraries-solidity/ABDKMathQuad.sol";
import "./LibTWAPOracle.sol";

/// @title Calculates amount of dollars ready to be minted when twapPrice > 1
library LibDollarMintCalculator {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    /// @notice returns (TWAP_PRICE  -1) * Ubiquity_Dollar_Total_Supply
    function getDollarsToMint() internal view returns (uint256) {
        uint256 twapPrice = LibTWAPOracle.consult(address(this));
        require(twapPrice > 1 ether, "DollarMintCalculator: not > 1");
        bytes16 _one = (uint256(1 ether)).fromUInt();
        return
            twapPrice
                .fromUInt()
                .sub(_one)
                .mul((IERC20(address(this)).totalSupply().fromUInt().div(_one)))
                .toUInt();
    }
}
