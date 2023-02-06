// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITWAPOracleDollar3pool {
    function update() external;

    function consult(address token) external view returns (uint256 amountOut);
}
