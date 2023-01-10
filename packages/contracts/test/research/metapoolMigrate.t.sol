// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "src/dollar/core/UbiquityDollarManager.sol";
import "src/dollar/Staking.sol";
import "src/dollar/mocks/MockBondingShareV2.sol";
import "src/dollar/interfaces/IMetaPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "forge-std/Test.sol";

contract metapoolMigrate is Test {

    address admin = 0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd;
    UbiquityDollarManager manager = UbiquityDollarManager(0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98);
    Staking staking = Staking(payable(0xC251eCD9f1bD5230823F9A0F99a44A87Ddd4CA38));
    BondingShareV2 bonds = BondingShareV2(0x2dA07859613C14F6f05c97eFE37B9B4F212b5eF5);
    IERC20 uAD = IERC20(0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6);
    IERC20 USD3CRV = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
    IMetaPool v2Metapool = IMetaPool(0x20955CB69Ae1515962177D164dfC9522feef567E);
    IMetaPool v3Metapool = IMetaPool(0x9558b18f021FC3cBa1c9B777603829A42244818b);

    uint256 mainnet;
    uint256 snapshot;

    function setUp() public {
        mainnet = vm.createSelectFork(vm.envString("RPC_URL"));
        snapshot = vm.snapshot();
    }

    function testMigrateCompare() public {
        vm.startPrank(admin);

        uint256 v2uADBal = uAD.balanceOf(address(v2Metapool));
        uint256 v23CRVBal = USD3CRV.balanceOf(address(v2Metapool));

        uint256 v2LP = v2Metapool.balanceOf(address(staking)) + v2Metapool.balanceOf(admin);

        uint256 metaBalance = v2Metapool.balanceOf(address(staking));
        staking.sendDust(admin, address(v2Metapool), metaBalance);

        v2Metapool.remove_liquidity(metaBalance,[uint256(0), uint256(0)]);

        uint256 usd3Bal = USD3CRV.balanceOf(admin);
        uint256 uADBal = uAD.balanceOf(admin);

        uint256 deposit;

        if(usd3Bal <= uADBal){
            deposit = usd3Bal;
        } else {
            deposit = uADBal;
        }

        USD3CRV.approve(address(v3Metapool), 0);
        USD3CRV.approve(address(v3Metapool), deposit);

        uAD.approve(address(v3Metapool), 0);
        uAD.approve(address(v3Metapool), deposit);

        v3Metapool.add_liquidity([deposit, deposit], 0, address(staking));
        uint256 metaBalanceV3 = v3Metapool.balanceOf(address(staking));

        require(metaBalanceV3 > 0);

        manager.setStableSwapMetaPoolAddress(address(v3Metapool));

        uint256 treasuryLP = v2Metapool.balanceOf(admin);
        v2Metapool.remove_liquidity(treasuryLP,[uint256(0), uint256(0)]);

        usd3Bal = USD3CRV.balanceOf(admin);
        uADBal = uAD.balanceOf(admin);

        USD3CRV.approve(address(v3Metapool), 0);
        USD3CRV.approve(address(v3Metapool), usd3Bal);

        uAD.approve(address(v3Metapool), 0);
        uAD.approve(address(v3Metapool), uADBal);

        v3Metapool.add_liquidity([uADBal, usd3Bal], 0, admin);

        uint256 v3LP = v3Metapool.balanceOf(address(staking)) + v3Metapool.balanceOf(admin);
        uint256 v3uADBal = uAD.balanceOf(address(v3Metapool));
        uint256 v33CRVBal = USD3CRV.balanceOf(address(v3Metapool));

        console.log("V2 LP Tokens: ", metaBalance);
        console.log("V3 LP Tokens: ", metaBalanceV3);
        console.log("V2 total LP: ", v2LP);
        console.log("V3 total LP: ", v3LP);
        console.log("V2 uAD Bal: ", v2uADBal);
        console.log("V2 3CRV Bal: ", v23CRVBal);
        console.log("V3 uAD Bal: ", v3uADBal);
        console.log("V3 3CRV Bal: ", v33CRVBal);

        vm.stopPrank();
    }

    function testV2WithdrawVsV3() public {
        address user = 0x4007CE2083c7F3E18097aeB3A39bb8eC149a341d;
        uint256[] memory tokens =bonds.holderTokens(user);


        BondingShareV2.Bond memory bond =bonds.getBond(tokens[0]);
        uint256 withdraw = bond.lpAmount;

        vm.roll(block.number + 10483200);

        vm.prank(user);
        staking.removeLiquidity(withdraw, tokens[0]);

        uint256 v2Bal = v2Metapool.balanceOf(user);

        vm.revertTo(snapshot);

        vm.startPrank(admin);
        uint256 metaBalance = v2Metapool.balanceOf(address(staking));
        staking.sendDust(admin, address(v2Metapool), metaBalance);

        v2Metapool.remove_liquidity(metaBalance,[uint256(0), uint256(0)]);

        uint256 usd3Bal = USD3CRV.balanceOf(admin);
        uint256 uADBal = uAD.balanceOf(admin);

        uint256 deposit;

        if(usd3Bal <= uADBal){
            deposit = usd3Bal;
        } else {
            deposit = uADBal;
        }

        USD3CRV.approve(address(v3Metapool), 0);
        USD3CRV.approve(address(v3Metapool), deposit);

        uAD.approve(address(v3Metapool), 0);
        uAD.approve(address(v3Metapool), deposit);

        v3Metapool.add_liquidity([deposit, deposit], 0, address(staking));
        uint256 metaBalanceV3 = v3Metapool.balanceOf(address(staking));

        require(metaBalanceV3 > 0);

        manager.setStableSwapMetaPoolAddress(address(v3Metapool));
        vm.stopPrank();

        vm.roll(block.number + 10483200);
        BondingShareV2.Bond memory bondV3 =bonds.getBond(tokens[0]);
        uint256 withdrawV3 = bondV3.lpAmount;
        vm.prank(user);
        staking.removeLiquidity(withdrawV3, tokens[0]);

        uint256 v3Bal = v3Metapool.balanceOf(user);

        console.log("V2 Withdraw: ", v2Bal);
        console.log("V3 Withdraw: ", v3Bal);

    }

}