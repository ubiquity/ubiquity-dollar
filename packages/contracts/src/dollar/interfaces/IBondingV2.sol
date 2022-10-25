// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.3;

interface IBondingV2 {
    function deposit(uint256 _lpsAmount, uint256 _weeks) external returns (uint256 _id);

    function addLiquidity(uint256 _amount, uint256 _id, uint256 _weeks) external;


    function removeLiquidity(uint256 _amount, uint256 _id) external;
}
