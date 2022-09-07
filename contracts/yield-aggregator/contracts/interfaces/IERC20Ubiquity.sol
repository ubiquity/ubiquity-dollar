// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;

import 'openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';

/// @title ERC20 Ubiquiti preset interface
/// @author Ubiquity Algorithmic Dollar
interface IERC20Ubiquity is IERC20 {
  // ----------- Events -----------
  event Minting(address indexed _to, address indexed _minter, uint _amount);

  event Burning(address indexed _burned, uint _amount);

  // ----------- State changing api -----------
  function burn(uint amount) external;

  function permit(
    address owner,
    address spender,
    uint value,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  // ----------- Burner only state changing api -----------
  function burnFrom(address account, uint amount) external;

  // ----------- Minter only state changing api -----------
  function mint(address account, uint amount) external;
}
