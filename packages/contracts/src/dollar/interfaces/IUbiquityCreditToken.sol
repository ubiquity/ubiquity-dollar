// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "./IERC20Ubiquity.sol";

interface IUbiquityCreditToken is IERC20Ubiquity {
    function raiseCapital(uint256 amount) external;
}
