// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../contracts/mock/ZozoVault.sol";

contract ZozoVaultTest is Test {
    ZozoVault public zozoVault;
    ERC20 daiContract = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    function setUp() public {
        zozoVault = new ZozoVault(daiContract);
    }

    function depositAndRedeem(
        address _user1,
        address _user2,
        uint256 _amount
    ) public returns (bool) {
        bool success = false;
        console.log(
            "Start: Dai on user1 wallet: ",
            daiContract.balanceOf(_user1)
        );
        vm.prank(address(zozoVault));
        zozoVault.approve(_user1, 2 * _amount);
        vm.prank(address(_user1));
        daiContract.approve(address(zozoVault), 2 * _amount);
        vm.prank(_user1);
        uint256 shares = zozoVault.deposit(_amount, address(zozoVault));
        console.log(
            "Middle: Dai on user1 wallet: ",
            daiContract.balanceOf(_user1)
        );
        vm.prank(_user2);
        daiContract.transfer(address(zozoVault), _amount);
        vm.prank(_user1);
        zozoVault.redeem(shares, _user1, address(zozoVault));
        success = true;
        console.log(
            "End: Dai on user1 wallet: ",
            daiContract.balanceOf(_user1)
        );
        return success;
    }

    function testDepositAndRedeem() public {
        address user1 = 0x2fEb1512183545f48f6b9C5b4EbfCaF49CfCa6F3;
        address user2 = 0x10bf1Dcb5ab7860baB1C3320163C6dddf8DCC0e4;
        uint256 amount = 10e18;
        bool success = depositAndRedeem(user1, user2, amount);
        assertTrue(success);
    }
}
