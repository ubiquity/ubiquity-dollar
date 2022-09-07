// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import 'forge-std/Test.sol';
import '../contracts/mock/ZozoVault.sol';

contract ZozoVaultTest is Test {
  ZozoVault public zozoVault;
  ERC20 daiContract = ERC20(0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60);

  function setUp() public {
    zozoVault = new ZozoVault(daiContract);
  }

  function depositAndRedeem(
    address _user1,
    address _user2,
    uint _amount
  ) public returns (bool) {
    bool success = false;
    console.log('Start: Dai on user1 wallet: ', daiContract.balanceOf(_user1));
    vm.prank(address(zozoVault));
    zozoVault.approve(_user1, 2 * _amount);
    vm.prank(address(_user1));
    daiContract.approve(address(zozoVault), 2 * _amount);
    vm.prank(_user1);
    uint shares = zozoVault.deposit(_amount, address(zozoVault));
    console.log('Middle: Dai on user1 wallet: ', daiContract.balanceOf(_user1));
    vm.prank(_user2);
    daiContract.transfer(address(zozoVault), _amount);
    vm.prank(_user1);
    zozoVault.redeem(shares, _user1, address(zozoVault));
    success = true;
    console.log('End: Dai on user1 wallet: ', daiContract.balanceOf(_user1));
    return success;
  }

  function testDepositAndRedeem() public {
    address user1 = 0x41e25bdD8CC3146A1d0287f38A4c39122b2182fc;
    address user2 = 0x6a49Acd2930BeCa9299236f647dF9b478cC18648;
    uint amount = 10e18;
    bool success = depositAndRedeem(user1, user2, amount);
    assertTrue(success);
  }
}
