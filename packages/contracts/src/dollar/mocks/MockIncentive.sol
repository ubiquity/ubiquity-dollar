// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract MockIncentive {
    event Incentivized(
        address indexed sender,
        address indexed recipient,
        address operator,
        uint256 amount
    );

    function incentivize(
        address sender,
        address recipient,
        address operator,
        uint256 amount
    ) public {
        emit Incentivized(sender, recipient, operator, amount);
    }
}
