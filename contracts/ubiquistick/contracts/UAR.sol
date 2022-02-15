// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUAR.sol";

contract UAR is IUAR, ERC20, Ownable {
  address public immutable treasuryAddress;

  constructor(
    string memory name,
    string memory symbol,
    address treasuryAddress_
  ) ERC20(name, symbol) {
    treasuryAddress = treasuryAddress_;
  }

  /// @notice raise capital in form of uAR (only redeemable when uAD > 1$)
  /// @param amount the amount to be minted
  /// @dev you should be minter to call that function
  function raiseCapital(uint256 amount) external override onlyOwner {
    _mint(treasuryAddress, amount);
  }
}
