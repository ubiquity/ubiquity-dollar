// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../../src/dollar/BondingFormulas.sol";
import "../../src/dollar/BondingShareV2.sol";
import "../../src/dollar/libs/ABDKMathQuad.sol";

import "../helpers/LocalTestHelper.sol";

contract BondingFormulaTest is LocalTestHelper {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    BondingFormulas bondingFormula;

    function setUp() public {
        bondingFormula = new BondingFormulas();
    }

    function test_sharesForLP() public {
        BondingShareV2.Bond memory _bond = BondingShareV2.Bond({
            // address of the minter
            minter: address(0x11111),
            // lp amount deposited by the user
            lpFirstDeposited: 0,
            creationBlock: 100,
            // lp that were already there when created
            lpRewardDebt: 0,
            endBlock: 1000,
            // lp remaining for a user
            lpAmount: 100
        });

        uint256[2] memory _shareInfo = [uint256(100), uint256(100)];
        uint256 _amount = 10;

        assertEq(bondingFormula.sharesForLP(_bond, _shareInfo, _amount), 10);
    }

    function test_lpRewardsRemoveLiquidityNormalization(
        BondingShareV2.Bond memory _bond,
        uint256[2] memory _shareInfo,
        uint256 _amount
    ) public {
        assertEq(
            bondingFormula.lpRewardsRemoveLiquidityNormalization(
                _bond, _shareInfo, _amount
            ),
            _amount
        );
    }

    function test_lpRewardsAddLiquidityNormalization(
        BondingShareV2.Bond memory _bond,
        uint256[2] memory _shareInfo,
        uint256 _amount
    ) public {
        assertEq(
            bondingFormula.lpRewardsAddLiquidityNormalization(
                _bond, _shareInfo, _amount
            ),
            _amount
        );
    }

    function test_correctedAmountToWithdraw_returnAmount() public {
        uint256 _totalLpDeposited = 10000;
        uint256 _bondingLpBalance = 20000;
        uint256 _amount = 100;
        assertEq(
            bondingFormula.correctedAmountToWithdraw(
                _totalLpDeposited, _bondingLpBalance, _amount
            ),
            100
        );
    }

    function test_correctedAmountToWithdraw_calcSharedAmount() public {
        uint256 _totalLpDeposited = 10000;
        uint256 _bondingLpBalance = 5000;
        uint256 _amount = 100;
        assertEq(
            bondingFormula.correctedAmountToWithdraw(
                _totalLpDeposited, _bondingLpBalance, _amount
            ),
            50
        );
    }
}
