// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./Constants.sol";

contract ManipulateTokens is Constants {
    function run() public {
        IERC20(USDCrvToken).transfer(address(admin), 10000e18);

    }
}