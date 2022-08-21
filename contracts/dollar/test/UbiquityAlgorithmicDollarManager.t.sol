// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/UbiquityAlgorithmicDollarManager.sol";
import "../src/BondingShare.sol";
import "../src/UbiquityAutoRedeem.sol";
import "../src/UARForDollarsCalculator.sol";
import "../src/UbiquityAlgorithmicDollar.sol";
import "../src/UbiquityGovernance.sol";
import "../src/DebtCoupon.sol";
import "../src/SushiSwapPool.sol";

contract UbiquityAlgorithmicDollarManagerTest is Test {
    DebtCoupon public debtCoupon;
    UbiquityAlgorithmicDollarManager public manager;
    address admin = address(0x1);
    UbiquityAlgorithmicDollar public uAD;
    UbiquityAutoRedeem public uAR;
    UARForDollarsCalculator public uarForDollarsCalculator;
    UbiquityGovernance public uGOV;
    string curveFactory;
    string curve3CrvBasePool;
    string curve3CrvToken;
    BondingShare public bondingShare;
}
