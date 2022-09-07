// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import 'forge-std/Test.sol';
import '../contracts/ProxyYieldAggregator.sol';
import '../contracts/mock/ZozoVault.sol';

contract ProxyYieldAggregatorTest is Test {
  ProxyYieldAggregator public proxyYieldAggregator;
  ZozoVault public zozoVault;
  address UBQDeployer = 0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd;
  ERC20 dai = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  address daiWhale = 0x1B7BAa734C00298b9429b518D621753Bb0f6efF2;

  IUbiquityAlgorithmicDollarManager manager =
    IUbiquityAlgorithmicDollarManager(0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98);
  uint16 minSplit = 500; // 5%
  uint16 premium = 4200; // 42%
  address user1 = 0x41e25bdD8CC3146A1d0287f38A4c39122b2182fc;
  uint amountDaiUser1 = 54e18;
  uint16 private constant PRECISION = 10_000;

  function setUp() public {
    zozoVault = new ZozoVault(dai);
    console.log('this: ', address(this));
    proxyYieldAggregator = new ProxyYieldAggregator(zozoVault, address(manager), minSplit, premium);
    console.log('proxyYieldAggregator deployed: ', address(proxyYieldAggregator));
    //console.logBytes32(manager.UBQ_MINTER_ROLE());
    // grant minter role to proxy

    bytes32 minterRole = manager.UBQ_MINTER_ROLE();
    vm.prank(UBQDeployer);
    manager.grantRole(minterRole, address(proxyYieldAggregator));
    // add one depositor to zozo vault

    addDai(user1, amountDaiUser1);
    vm.prank(user1);
    dai.approve(address(zozoVault), amountDaiUser1);
    vm.prank(user1);
    uint user1Shares = zozoVault.deposit(amountDaiUser1, user1);
    console.log('user1Shares: ', user1Shares);
  }

  function addDai(address receiver, uint amount) public {
    // add DAI to zozo Vault to simulate yield
    uint balance = dai.balanceOf(daiWhale);
    console.log('daiWhale: ', balance);
    vm.prank(daiWhale);
    dai.transfer(receiver, amount);
  }

  function testDepositWithStrategyAsset() public {
    uint amount = 10e18;
    addDai(address(this), amount);
    uint balance = dai.balanceOf(address(this));
    console.log('Start deposit: Dai on  wallet: ', balance);
    assertEq(balance, amount);
    // we allow proxy to take our dai
    dai.approve(address(proxyYieldAggregator), amount);

    assertEq(balance, amount);
    uint proxyShares = proxyYieldAggregator.depositWithStrategyAsset(address(this), amount);
    console.log('proxyShares: ', proxyShares);
    balance = dai.balanceOf(address(this));
    assertEq(balance, 0);
    // all dai are now in the zozo vault
    assertEq(dai.balanceOf(address(zozoVault)), amount + amountDaiUser1);
  }

  function testDepositWithStrategyAsset_And_Redeem() public {
    uint amount = 10e18;
    uint amountDaiWonByStrat = 18e18;
    // get some dai to invest
    addDai(address(this), amount);

    uint balance = dai.balanceOf(address(this));
    assertEq(balance, amount);
    // we allow proxy to take our dai
    dai.approve(address(proxyYieldAggregator), amount);

    uint sDAIbalance = zozoVault.balanceOf(address(proxyYieldAggregator));
    uint pDAIbalance = proxyYieldAggregator.balanceOf(address(this));
    assertEq(sDAIbalance, 0);
    assertEq(pDAIbalance, 0);
    uint prevShares = zozoVault.previewDeposit(amount);
    uint pShares = proxyYieldAggregator.previewDeposit(prevShares);
    proxyYieldAggregator.depositWithStrategyAsset(address(this), amount);

    balance = dai.balanceOf(address(this));
    assertEq(balance, 0);
    sDAIbalance = zozoVault.balanceOf(address(proxyYieldAggregator));
    pDAIbalance = proxyYieldAggregator.balanceOf(address(this));
    assertEq(sDAIbalance, prevShares);
    assertEq(pDAIbalance, pShares);

    assertEq(dai.balanceOf(address(zozoVault)), amount + amountDaiUser1);

    // transfer DAI to strategy to simulate a positive yield
    addDai(address(zozoVault), amountDaiWonByStrat);

    assertEq(dai.balanceOf(address(zozoVault)), amount + amountDaiUser1 + amountDaiWonByStrat);
    // redeem without specifying split
    IERC20Ubiquity ubiquityAutoRedeem = IERC20Ubiquity(manager.autoRedeemTokenAddress());
    assertEq(ubiquityAutoRedeem.balanceOf(address(this)), 0);
    assertEq(zozoVault.balanceOf(address(this)), 0);

    proxyYieldAggregator.redeem(pDAIbalance, address(this), address(this));

    assertEq(dai.balanceOf(address(this)), 0);
    sDAIbalance = zozoVault.balanceOf(address(proxyYieldAggregator));
    pDAIbalance = proxyYieldAggregator.balanceOf(address(this));
    assertEq(sDAIbalance, 0);
    assertEq(pDAIbalance, 0);
    uint splitAmount = ((minSplit * prevShares) / PRECISION);
    assertEq(zozoVault.balanceOf(address(this)), prevShares - splitAmount);
    uint treasuryBalance = zozoVault.balanceOf(manager.treasuryAddress());
    assertEq(treasuryBalance, splitAmount);
    // uCR check

    uint vaultAssetForSplitAmount = zozoVault.previewRedeem(splitAmount);
    uint uCRMinted = (vaultAssetForSplitAmount * premium) / PRECISION;
    assertEq(ubiquityAutoRedeem.balanceOf(address(this)), uCRMinted);
  }

  function testDepositWithStrategyAsset_And_RedeemStrategyAsset() public {
    uint amount = 10e18;
    uint amountDaiWonByStrat = 18e18;
    // get some dai to invest
    addDai(address(this), amount);

    uint balance = dai.balanceOf(address(this));
    assertEq(balance, amount);
    // we allow proxy to take our dai
    dai.approve(address(proxyYieldAggregator), amount);
    uint sDAIbalance = zozoVault.balanceOf(address(proxyYieldAggregator));
    uint pDAIbalance = proxyYieldAggregator.balanceOf(address(this));
    assertEq(sDAIbalance, 0);
    assertEq(pDAIbalance, 0);
    uint prevShares = zozoVault.previewDeposit(amount);
    //uint stratAssets = _strategy.previewMint(prevShares);
    uint pShares = proxyYieldAggregator.previewDeposit(prevShares);

    proxyYieldAggregator.depositWithStrategyAsset(address(this), amount);
    // deposit done
    balance = dai.balanceOf(address(this));
    assertEq(balance, 0);
    sDAIbalance = zozoVault.balanceOf(address(proxyYieldAggregator));
    pDAIbalance = proxyYieldAggregator.balanceOf(address(this));
    assertEq(sDAIbalance, prevShares);
    assertEq(pDAIbalance, pShares);

    assertEq(dai.balanceOf(address(zozoVault)), amount + amountDaiUser1);

    // transfer DAI to strategy to simulate a positive yield
    addDai(address(zozoVault), amountDaiWonByStrat);

    assertEq(dai.balanceOf(address(zozoVault)), amount + amountDaiUser1 + amountDaiWonByStrat);

    IERC20Ubiquity ubiquityAutoRedeem = IERC20Ubiquity(manager.autoRedeemTokenAddress());
    assertEq(ubiquityAutoRedeem.balanceOf(address(this)), 0);
    assertEq(zozoVault.balanceOf(address(this)), 0);
    uint16 currentSplit = 1000;
    // start redeem
    proxyYieldAggregator.reedemStrategyAsset(
      pDAIbalance,
      address(this),
      address(this),
      currentSplit
    );

    uint sDAIbalanceAfter = zozoVault.balanceOf(address(proxyYieldAggregator));
    uint pDAIbalanceAfter = proxyYieldAggregator.balanceOf(address(this));
    assertEq(sDAIbalanceAfter, 0);
    assertEq(pDAIbalanceAfter, 0);
    uint totalDai = zozoVault.totalAssets();
    uint totalStratShares = zozoVault.totalSupply();

    uint splitAmount = ((currentSplit * prevShares) / PRECISION);
    uint remainingStratShares = prevShares - splitAmount;
    uint prevStratRedeem = zozoVault.previewRedeem(remainingStratShares);

    assertEq(prevStratRedeem, (remainingStratShares * totalDai) / totalStratShares);

    assertEq(dai.balanceOf(address(this)), prevStratRedeem);
    assertEq(zozoVault.balanceOf(address(this)), 0);
    uint treasuryBalance = zozoVault.balanceOf(manager.treasuryAddress());
    assertEq(treasuryBalance, splitAmount);
    // uCR check
    uint vaultAssetForSplitAmount = zozoVault.previewRedeem(splitAmount);
    uint uCRMinted = (vaultAssetForSplitAmount * premium) / PRECISION;
    assertEq(ubiquityAutoRedeem.balanceOf(address(this)), uCRMinted);
  }
  /*  function deposit(address _user1, uint _amount) public returns (bool) {
    bool success = false;
    console.log('Start deposit: Dai on user1 wallet: ', daiContract.balanceOf(_user1));
    console.log(
      'Start deposit: Dai on proxy: ',
      daiContract.balanceOf(address(proxyYieldAggregator))
    );

    console.log('Start deposit: Shares on user1 wallet: ', proxyYieldAggregator.balanceOf(_user1));
    vm.prank(address(manager));
    proxyYieldAggregator.manageVault(_token, _vault);
    vm.prank(_user1);
    proxyYieldAggregator.deposit(_token, _amount);
    console.log('End deposit: Dai on user1 wallet: ', daiContract.balanceOf(_user1));
    console.log(
      'End deposit: Dai on proxy: ',
      daiContract.balanceOf(address(proxyYieldAggregator))
    );
    console.log('End deposit: Shares on user1 wallet: ', proxyYieldAggregator.balanceOf(_user1));
    success = true;
    return success;
  } */

  /*
  function redeem(
    address _user1,
    address _token,
    uint _shares,
    uint _proportion
  ) public returns (bool) {
    bool success = false;
    console.log('Start redeem: Dai on user1 wallet: ', daiContract.balanceOf(_user1));
    console.log(
      'Start redeem: Dai on proxy: ',
      daiContract.balanceOf(address(proxyYieldAggregator))
    );
    console.log('Start redeem: Shares on user1 wallet: ', proxyYieldAggregator.balanceOf(_user1));
    console.log('Start redeem: uAD on user1 wallet: ', ubiquityAutoRedeem.balanceOf(_user1));
    vm.prank(_user1);
    proxyYieldAggregator.redeem(_token, _shares, _proportion);
    console.log('End redeem: Dai on user1 wallet: ', daiContract.balanceOf(_user1));
    console.log('End redeem: Dai on proxy: ', daiContract.balanceOf(address(proxyYieldAggregator)));
    console.log('End redeem: Shares on user1 wallet: ', ubiquityAutoRedeem.balanceOf(_user1));
    success = true;
    return success;
  }
 */

  /* 
  function testRedeem() public {
    address user1 = 0x41e25bdD8CC3146A1d0287f38A4c39122b2182fc;
    uint proportion = 1 / uint(2);
    bool success = redeem(
      user1,
      address(daiContract),
      proxyYieldAggregator.balanceOf(user1),
      proportion
    );
    assertTrue(success);
  } */
}
