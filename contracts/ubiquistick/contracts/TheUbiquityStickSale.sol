// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// FORK from Land DAO -> https://github.com/Land-DAO/nft-contracts/blob/main/contracts/LandSale.sol

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ITheUbiquityStick.sol";

contract TheUbiquityStickSale is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  struct Purchase {
    uint256 count;
    uint256 price;
  }

  // TheUbiquityStick token contract interface
  ITheUbiquityStick public tokenContract;

  // Stores the allowed minting count and token price for each whitelisted address
  mapping(address => Purchase) private _allowances;

  // Stores the address of the treasury
  address public fundsAddress;

  uint256 public constant MAXIMUM_SUPPLY = 1024;
  uint256 public constant MAXIMUM_PER_TX = 10;
  address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  event Mint(address from, uint256 count, uint256 price);

  event Payback(address to, uint256 unspent);

  event Withdraw(address to, address token, uint256 amount);

  constructor() {}

  function setTokenContract(address _newTokenContract) external onlyOwner {
    require(_newTokenContract != address(0), "Invalid Address");
    tokenContract = ITheUbiquityStick(_newTokenContract);
  }

  function setFundsAddress(address _address) external onlyOwner {
    require(_address != address(0), "Invalid Address");
    fundsAddress = _address;
  }

  // Set the allowance for the specified address
  function setAllowance(
    address _address,
    uint256 _count,
    uint256 _price
  ) public onlyOwner {
    require(_address != address(0), "Invalid Address");
    _allowances[_address] = Purchase(_count, _price);
  }

  // Set the allowance for the specified address
  function batchSetAllowances(
    address[] calldata _addresses,
    uint256[] calldata _counts,
    uint256[] calldata _prices
  ) external onlyOwner {
    uint256 count = _addresses.length;

    for (uint16 i = 0; i < count; i++) {
      setAllowance(_addresses[i], _counts[i], _prices[i]);
    }
  }

  // Get the allowance for the specified address
  function allowance(address _address) public view returns (uint256 count, uint256 price) {
    Purchase memory _allowance = _allowances[_address];
    count = _allowance.count;
    price = _allowance.price;
  }

  // Handles token purchases
  receive() external payable nonReentrant {
    // Check if tokens are still available for sale
    require(tokenContract.totalSupply() < MAXIMUM_SUPPLY, "Sold Out");
    uint256 remainingTokenCount = MAXIMUM_SUPPLY - tokenContract.totalSupply();

    // Check if sufficient funds are sent, and that the address is whitelisted
    // and had enough allowance with enough funds
    uint256 count;
    uint256 price;
    (count, price) = allowance(msg.sender);
    require(count > 0, "Not Whitelisted For The Sale Or Insufficient Allowance");

    if (remainingTokenCount < count) count = remainingTokenCount;
    if (msg.value < count * price) count = msg.value / price;
    if (MAXIMUM_PER_TX < count) count = MAXIMUM_PER_TX;
    require(count > 0, "Not enough Funds");

    _allowances[msg.sender].count -= count;

    uint256 paid = count * price;
    tokenContract.batchSafeMint(msg.sender, count);
    emit Mint(msg.sender, count, paid);

    // Calculate any excess/unspent funds and transfer it back to the buyer
    if (msg.value > paid) {
      uint256 unspent = msg.value - paid;
      payable(msg.sender).transfer(unspent);
      emit Payback(msg.sender, unspent);
    }
  }

  function withdraw() public nonReentrant onlyOwner {
    payable(fundsAddress).transfer(address(this).balance);
  }
}
