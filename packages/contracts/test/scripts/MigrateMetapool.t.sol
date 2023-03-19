// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

//cspell:ignore BondingShareV2
/*  TO BE DONE WITH THE DIAMOND 

import {UbiquityDollarManager} from "src/dollar/core/UbiquityDollarManager.sol";
import {Staking} from "src/dollar/Staking.sol";
import {MockBondingShareV2} from "src/dollar/mocks/MockBondingShareV2.sol";
import {IMetaPool} from "src/dollar/interfaces/IMetaPool.sol";
 import {TWAPOracleDollar3pool} from "src/dollar/core/TWAPOracleDollar3pool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "forge-std/Test.sol";

contract MigrateMetapool is Test {
    /// Ubiquity Admin EOA public address
    address admin = 0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd;
    UbiquityDollarManager manager =
        UbiquityDollarManager(0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98);
    Staking staking =
        Staking(payable(0xC251eCD9f1bD5230823F9A0F99a44A87Ddd4CA38));
    MockBondingShareV2 bonds =
        MockBondingShareV2(0x2dA07859613C14F6f05c97eFE37B9B4F212b5eF5);
    /// Ubiquity Dollar Token (Dollar)
    IERC20 dollarToken = IERC20(0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6);
    /// Curve3 LP Token (3CRV)
    IERC20 curve3Token = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
    /// Curve Metapool V2 Dollar:3CRV

    IMetaPool v2Metapool =
        IMetaPool(0x20955CB69Ae1515962177D164dfC9522feef567E);
    /// Curve Metapool V3 Dollar:3CRV
    IMetaPool v3Metapool =
        IMetaPool(0x9558b18f021FC3cBa1c9B777603829A42244818b);

    TWAPOracleDollar3pool twapOracle;

    /// Forge Test Fork Identifier
    uint256 mainnet;
    /// Forge Snapshot selector
    uint256 snapshot;

    function setUp() public {
        
          //  Forking mainnet to run the tests and then taking a snapshot of the state so we can later revert to the snapshot for comparing states after two different logic runs.
          //  Fork URL currently hardcoded due to current limits of Github Actions
        
        mainnet = vm.createSelectFork("https://eth.ubq.fi/v1/mainnet");
        snapshot = vm.snapshot();
    }

    function testMigrateCompare() public {
        /// Ubiquity Dollar balance of V2 Metapool before migration
        uint256 v2DollarPreBalance = dollarToken.balanceOf(address(v2Metapool));
        /// Curve3 LP Balance of V2 Metapool before migration
        uint256 v2Curve3PreBalance = curve3Token.balanceOf(address(v2Metapool));
        /// Total amount of V2 Metapool LP tokens before migration
        uint256 v2LP = v2Metapool.totalSupply();

        (
            uint256 metaBalance,
            uint256 metaBalanceV3,
            uint256 lpMinted
        ) = _migrate();

        /// Total amount of V3 Metapool LP tokens after migration
        uint256 v3LP = v3Metapool.totalSupply();
        /// Ubiquity Dollar balance of V3 Metapool after migration
        uint256 v3DollarBalance = dollarToken.balanceOf(address(v3Metapool));
        /// Curve3 LP balance of V3 Metapool after migration
        uint256 v3Curve3Balance = curve3Token.balanceOf(address(v3Metapool));
        /// Curve3 LP Balance of V2 Metapool after Migration
        uint256 v2Curve3PostBalance = curve3Token.balanceOf(
            address(v2Metapool)
        );
        /// Ubiquity Dollar balance of V2 Metapool after Migration
        uint256 v2DollarPostBalance = dollarToken.balanceOf(
            address(v2Metapool)
        );

        console.log("LP Tokens in Staking before migration: ", metaBalance);
        console.log("LP Tokens in Staking after migration: ", metaBalanceV3);
        console.log("Total LP Tokens Curve Metapool V2: ", v2LP);
        console.log("Total LP Tokens Curve Metapool V3: ", v3LP);
        console.log(
            "Amount of Ubiquity Dollar Tokens in Curve Metapool V2: ",
            v2DollarPreBalance
        );
        console.log(
            "Amount of Ubiquity Dollar Tokens in Curve Metapool V2 after migration: ",
            v2DollarPostBalance
        );
        console.log(
            "Amount of Ubiquity Dollar Tokens in Curve Metapool V3: ",
            v3DollarBalance
        );
        console.log(
            "Amount of Curve3 Tokens in Curve Metapool V2 before migration: ",
            v2Curve3PreBalance
        );
        console.log(
            "Amount of Curve3 Tokens in Curve Metapool V2 after migration: ",
            v2Curve3PostBalance
        );
        console.log(
            "Amount of Curve3 Tokens in Curve Metapool V3 after migration: ",
            v3Curve3Balance
        );

        /// ensures all v3 LP tokens minted are deposited in Staking
        assertEq(lpMinted, metaBalanceV3);
       
            // Compares the amount of Curve3 LP tokens in V2 Metapool before migration
            // to the amount of Curve3 LP tokens in both Metapools after migration to
            // ensure no Curve3 LP tokens are lost during migration.
            // The Staking Contract holds the large majority of V2 LP tokens but there are some smaller holders
            // so we are unable to migrate all funds.
        

        assertEq(v2Curve3PreBalance, (v2Curve3PostBalance + v3Curve3Balance));

        /// Same as above but for Ubiquity Dollar Token
        assertEq(v2DollarPreBalance, (v2DollarPostBalance + v3DollarBalance));

        assertEq(
            keccak256(abi.encodePacked(manager.stableSwapMetaPoolAddress())),
            keccak256(abi.encodePacked(address(v3Metapool)))
        );
    }

    function testV2WithdrawVsV3() public {
        address user = 0x4007CE2083c7F3E18097aeB3A39bb8eC149a341d;
        uint256[] memory tokens = bonds.holderTokens(user);

        uint256 dollarTokenPreBalance = dollarToken.balanceOf(user);
        MockBondingShareV2.Bond memory bond = bonds.getBond(tokens[0]);
        uint256 withdraw = bond.lpAmount;

        vm.roll(block.number + 10483200);

        vm.startPrank(user);
        staking.removeLiquidity(withdraw, tokens[0]);
        uint256 v2Balance = v2Metapool.balanceOf(user);
        v2Metapool.remove_liquidity(v2Balance, [uint256(0), uint256(0)]);
        vm.stopPrank();

        uint256 userDollarV2 = dollarToken.balanceOf(user) -
            dollarTokenPreBalance;
        uint256 userCurve3V2 = curve3Token.balanceOf(user);

        vm.revertTo(snapshot);

        _migrate();

        vm.roll(block.number + 10483200);
        MockBondingShareV2.Bond memory bondV3 = bonds.getBond(tokens[0]);
        uint256 withdrawV3 = bondV3.lpAmount;
        vm.startPrank(user);
        staking.removeLiquidity(withdrawV3, tokens[0]);
        uint256 v3Balance = v3Metapool.balanceOf(user);

        v3Metapool.remove_liquidity(v3Balance, [uint256(0), uint256(0)]);
        vm.stopPrank();

        uint256 userDollarV3 = dollarToken.balanceOf(user) -
            dollarTokenPreBalance;
        uint256 userCurve3V3 = curve3Token.balanceOf(user);

        uint256 v3DollarBalance = dollarToken.balanceOf(address(v3Metapool));
        uint256 v3Curve3Balance = curve3Token.balanceOf(address(v3Metapool));

        console.log("Metapool LP Tokens withdrawn pre migration: ", v2Balance);
        console.log("Metapool LP Tokens withdrawn post migration: ", v3Balance);
        console.log(
            "Ubiquity Dollar Tokens withdrawn pre migration: ",
            userDollarV2
        );
        console.log("Curve3 Tokens withdrawn pre migration: ", userCurve3V2);
        console.log(
            "Ubiquity Dollar Tokens withdrawn post migration: ",
            userDollarV3
        );
        console.log("Curve3 Tokens withdrawn post migration: ", userCurve3V3);
        console.log(
            "Curve Metapool V3 Ubiquity Dollar balance after withdrawal: ",
            v3DollarBalance
        );
        console.log(
            "Curve Metapool V3 Curve3 balance after withdrawal: ",
            v3Curve3Balance
        );

        assertGe(v3Balance, v2Balance);
        assertLe(userDollarV3, userDollarV2);
        assertLe(userCurve3V3, userCurve3V2);
    }

    /// @dev internal function for migrating Curve Metapool LP Tokens contained in Staking from V2 to V3
    /// @return metaBalance Staking Contract V2 LP Balance before migration
    /// @return metaBalanceV3 Staking Contract V3 LP Balance after migration
    /// @return lpMinted amount of Metapool V3 LP tokens minted during migration
    function _migrate()
        internal
        returns (uint256 metaBalance, uint256 metaBalanceV3, uint256 lpMinted)
    {
        vm.startPrank(admin);

        uint256 dollarPreBalance = dollarToken.balanceOf(admin);

        metaBalance = v2Metapool.balanceOf(address(staking));
        staking.sendDust(admin, address(v2Metapool), metaBalance);

        v2Metapool.remove_liquidity(metaBalance, [uint256(0), uint256(0)]);

        uint256 curve3Balance = curve3Token.balanceOf(admin);
        uint256 dollarBalance = dollarToken.balanceOf(admin);

        uint256 deposit;

        if (curve3Balance <= dollarBalance) {
            deposit = curve3Balance;
        } else {
            deposit = dollarBalance;
        }

        curve3Token.approve(address(v3Metapool), 0);
        curve3Token.approve(address(v3Metapool), curve3Balance);

        dollarToken.approve(address(v3Metapool), 0);
        dollarToken.approve(address(v3Metapool), dollarBalance);

        lpMinted = v3Metapool.add_liquidity(
            [deposit, deposit],
            0,
            address(staking)
        );

        require(v3Metapool.balanceOf(address(staking)) > 0);

        twapOracle = new TWAPOracleDollar3pool(
            address(v3Metapool),
            address(dollarToken),
            address(curve3Token)
        );
        ///manager.setTwapOracleAddress(address(twapOracle));

        uint256 secondDeposit = dollarBalance - deposit - dollarPreBalance;

        lpMinted += v3Metapool.add_liquidity(
            [secondDeposit, uint256(0)],
            0,
            address(staking)
        );

        metaBalanceV3 = v3Metapool.balanceOf(address(staking));

        manager.setStableSwapMetaPoolAddress(address(v3Metapool));

        vm.stopPrank();
    }
}
 */
