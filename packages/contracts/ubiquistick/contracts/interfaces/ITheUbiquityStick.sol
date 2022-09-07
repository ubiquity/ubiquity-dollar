// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ITheUbiquityStick {
  function totalSupply() external view returns (uint256);

  function batchSafeMint(address, uint256) external;
}
