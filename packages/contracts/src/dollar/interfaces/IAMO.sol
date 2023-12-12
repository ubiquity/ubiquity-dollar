// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;
pragma experimental ABIEncoderV2;

interface IAmo {
    function dollarBalances()
        external
        view
        returns (uint256 uad_val_e18, uint256 collat_val_e18);
}
