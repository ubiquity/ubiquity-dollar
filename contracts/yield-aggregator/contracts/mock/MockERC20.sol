pragma solidity >=0.8.0;

import 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';

contract MockERC20 is ERC20 {
  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals
  ) public ERC20(name, symbol) {}

  function mint(address to, uint amount) public {
    _mint(to, amount);
  }
}
