// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.10;

import {ERC20} from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';

contract MockERC20 is ERC20 {
  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) ERC20(_name, _symbol) {}

  function mint(address to, uint value) public virtual {
    _mint(to, value);
  }

  function burn(address from, uint value) public virtual {
    _burn(from, value);
  }
}
