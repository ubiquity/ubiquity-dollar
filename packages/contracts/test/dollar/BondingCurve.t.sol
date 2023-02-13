// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../helpers/LiveTestHelper.sol";

contract ZeroState is LiveTestHelper {

    event Deposit(
        address indexed user, 
        uint256 amount
    );

    event Withdraw(
        address indexed recipient, 
        uint256 amount
    );

    address[] ogs;
    address[] ogsEmpty;
    uint256[] balances;
    uint256[] lockup;

    function setUp() public virtual override {}
}