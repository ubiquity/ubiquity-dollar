// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../../src/dollar/BondingFormulas.sol";
import "../../src/dollar/BondingShareV2.sol";
import "../../src/dollar/libs/ABDKMathQuad.sol";

import "../helpers/TestHelper.sol";

contract BondingFormulaTest is TestHelper {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    BondingFormulas bondingFormula;


    function setUp() public {
        bondingFormula = new BondingFormulas();
    }

    function test_BondingFormulas_sharesForLP(
        BondingShareV2.Bond memory _bond,
        uint256[2] memory _shareInfo,
        uint256 _amount
    ) public {
        bytes16 a = _shareInfo[0].fromUInt(); // shares amount
        bytes16 v = _amount.fromUInt();
        bytes16 t = _bond.lpAmount.fromUInt();
        uint256 _uLP = a.mul(v).div(t).toUInt();

        assertEq(bondingFormula.sharesForLP(_bond, _shareInfo, _amount), _uLP);
    }

    function test_BondingFormulas_lpRewardsRemoveLiquidityNormalization() public {}

    function test_BondingFormulas_lpRewardsAddLiquidityNormalization() public {}
}
