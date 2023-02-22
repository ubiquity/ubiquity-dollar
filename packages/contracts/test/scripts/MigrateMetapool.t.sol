// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "src/dollar/core/UbiquityDollarManager.sol";
import "src/dollar/Staking.sol";
import "src/dollar/mocks/MockBondingShareV2.sol";
import "src/dollar/interfaces/IMetaPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "forge-std/Test.sol";

contract MigrateMetapool is Test {
    address admin = 0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd;
    UbiquityDollarManager manager =
        UbiquityDollarManager(0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98);
    Staking staking =
        Staking(payable(0xC251eCD9f1bD5230823F9A0F99a44A87Ddd4CA38));
    BondingShareV2 bonds =
        BondingShareV2(0x2dA07859613C14F6f05c97eFE37B9B4F212b5eF5);
    IERC20 dollarToken = IERC20(0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6);
    IERC20 curve3Token = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
    IMetaPool v2Metapool =
        IMetaPool(0x20955CB69Ae1515962177D164dfC9522feef567E);
    IMetaPool v3Metapool =
        IMetaPool(0x9558b18f021FC3cBa1c9B777603829A42244818b);

    uint256 mainnet;
    uint256 snapshot;

    function setUp() public {
        /*string memory forkURL = vm.envString("RPC_URL");

        if (
            keccak256(abi.encodePacked(forkURL)) !=
            keccak256(abi.encodePacked(""))
        ) {
            mainnet = vm.createSelectFork(forkURL);
        } else {
            mainnet = vm.createSelectFork("https://eth.ubq.fi/v1/mainnet");
        }*/
        mainnet = vm.createSelectFork("https://eth.ubq.fi/v1/mainnet");
        snapshot = vm.snapshot();
    }

    function testMigrateCompare() public {
        uint256 v2dollarBal = dollarToken.balanceOf(address(v2Metapool));
        uint256 v2curve3Bal = curve3Token.balanceOf(address(v2Metapool));

        uint256 v2LP = v2Metapool.balanceOf(address(staking)) +
            v2Metapool.balanceOf(admin);

        (uint256 metaBalance, uint256 metaBalanceV3) = migrate();

        uint256 v3LP = v3Metapool.balanceOf(address(staking)) +
            v3Metapool.balanceOf(admin);
        uint256 v3dollarBal = dollarToken.balanceOf(address(v3Metapool));
        uint256 v3curve3Bal = curve3Token.balanceOf(address(v3Metapool));

        console.log("LP Tokens in Staking before migration: ", metaBalance);
        console.log("LP Tokens in Staking after migration: ", metaBalanceV3);
        console.log("Total LP Tokens Curve Metapool V2: ", v2LP);
        console.log("Total LP Tokens Curve Metapool V3: ", v3LP);
        console.log(
            "Amount of UbiquityDollar Tokens in Curve Metapool V2: ",
            v2dollarBal
        );
        console.log(
            "Amount of Curve3 Tokens in Curve Metapool V2: ",
            v2curve3Bal
        );
        console.log(
            "Amount of UbiquityDollar Tokens in Curve Metapool V3: ",
            v3dollarBal
        );
        console.log(
            "Amount of Curve3 Tokens in Curve Metapool V3: ",
            v3curve3Bal
        );
    }

    function testV2WithdrawVsV3() public {
        address user = 0x4007CE2083c7F3E18097aeB3A39bb8eC149a341d;
        uint256[] memory tokens = bonds.holderTokens(user);

        uint256 dollarTokenPreBal = dollarToken.balanceOf(user);
        BondingShareV2.Bond memory bond = bonds.getBond(tokens[0]);
        uint256 withdraw = bond.lpAmount;

        vm.roll(block.number + 10483200);

        vm.startPrank(user);
        staking.removeLiquidity(withdraw, tokens[0]);
        uint256 v2Bal = v2Metapool.balanceOf(user);
        v2Metapool.remove_liquidity(v2Bal, [uint256(0), uint256(0)]);
        vm.stopPrank();

        uint256 userDollarV2 = dollarToken.balanceOf(user) - dollarTokenPreBal;
        uint256 userLPV2 = curve3Token.balanceOf(user);

        vm.revertTo(snapshot);

        migrate();

        vm.roll(block.number + 10483200);
        BondingShareV2.Bond memory bondV3 = bonds.getBond(tokens[0]);
        uint256 withdrawV3 = bondV3.lpAmount;
        vm.startPrank(user);
        staking.removeLiquidity(withdrawV3, tokens[0]);
        uint256 v3Bal = v3Metapool.balanceOf(user);

        v3Metapool.remove_liquidity(v3Bal, [uint256(0), uint256(0)]);
        vm.stopPrank();

        uint256 userDollarV3 = dollarToken.balanceOf(user) - dollarTokenPreBal;
        uint256 userLPV3 = curve3Token.balanceOf(user);

        uint256 v3dollarBal = dollarToken.balanceOf(address(v3Metapool));
        uint256 v3curve3Bal = curve3Token.balanceOf(address(v3Metapool));

        console.log("Metapool LP Tokens withdrawn pre migration: ", v2Bal);
        console.log("Metapool LP Tokens withdrawn post migration: ", v3Bal);
        console.log(
            "UbiquityDollar Tokens withdrawn pre migration: ",
            userDollarV2
        );
        console.log("Curve3 Tokens withdrawn pre migration: ", userLPV2);
        console.log(
            "UbiquityDollar Tokens withdrawn post migration: ",
            userDollarV3
        );
        console.log("Curve3 Tokens withdrawn post migration: ", userLPV3);
        console.log(
            "Curve Metapool V3 UbiquityDollar balance after withdrawal: ",
            v3dollarBal
        );
        console.log(
            "Curve Metapool V3 Curve3 balance after withdrawal: ",
            v3curve3Bal
        );
    }

    function migrate()
        internal
        returns (uint256 metaBalance, uint256 metaBalanceV3)
    {
        vm.startPrank(admin);
        metaBalance = v2Metapool.balanceOf(address(staking));
        staking.sendDust(admin, address(v2Metapool), metaBalance);

        v2Metapool.remove_liquidity(metaBalance, [uint256(0), uint256(0)]);

        uint256 curve3Bal = curve3Token.balanceOf(admin);
        uint256 dollarBal = dollarToken.balanceOf(admin);

        uint256 deposit;

        if (curve3Bal <= dollarBal) {
            deposit = curve3Bal;
        } else {
            deposit = dollarBal;
        }

        curve3Token.approve(address(v3Metapool), 0);
        curve3Token.approve(address(v3Metapool), deposit);

        dollarToken.approve(address(v3Metapool), 0);
        dollarToken.approve(address(v3Metapool), deposit);

        v3Metapool.add_liquidity([deposit, deposit], 0, address(staking));
        metaBalanceV3 = v3Metapool.balanceOf(address(staking));

        require(metaBalanceV3 > 0);

        manager.setStableSwapMetaPoolAddress(address(v3Metapool));

        vm.stopPrank();
    }
}
