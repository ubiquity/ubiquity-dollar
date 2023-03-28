// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {BancorPower} from "../core/BancorPower.sol";
import "abdk/ABDKMathQuad.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Constants.sol";

/**
 * @title Bancor formula
 * @dev Modified from the original
 * @notice forked from Bancor:
 * https://github.com/bancorprotocol/contracts
 *
 */
library LibBancorFormula {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    /**
     * @dev Given a token supply, reserve balance, weight and a deposit amount (in the reserve token),
     * calculates the target amount for a given conversion (in the main token)
     *
     * @dev _supply * ((1 + _tokensDeposited / _connectorBalance) ^ (_connectorWeight / 1000000) - 1)
     *
     * @param _tokensDeposited   amount of collateral tokens to deposit
     * @param _connectorWeight   connector weight, represented in ppm, 1 - 1,000,000
     * @param _supply          current Token supply
     * @param _connectorBalance   total connector balance
     * 
     * @return amount of Tokens minted
     */
    function _purchaseTargetAmount(
        uint256 _tokensDeposited,
        uint32 _connectorWeight,
        uint256 _supply,
        uint256 _connectorBalance
    ) internal view returns(uint256) {

        // validate input
        require(_connectorBalance > 0, "ERR_INVALID_SUPPLY");
        require(_connectorWeight > 0 && _connectorWeight <= MAX_WEIGHT, "ERR_INVALID_WEIGHT");
        
        // special case for 0 deposit amount
        if (_tokensDeposited == 0) {
            return 0;
        }
        // special case if the weight = 100%
        if (_connectorWeight == MAX_WEIGHT) {
            return (_supply * _tokensDeposited) / _connectorBalance;
        }

        bytes16 _one = uintToBytes16(ONE);

        bytes16 exponent = uint256(_connectorWeight).fromUInt().div(
            uint256(MAX_WEIGHT).fromUInt()
        );

        bytes16 connBal = _connectorBalance.fromUInt();
        bytes16 temp = _one.add(
            _tokensDeposited.fromUInt().div(connBal)
        );
        //Instead of calculating "base ^ exp", we calculate "e ^ (log(base) * exp)".
        bytes16 result = _supply.fromUInt().mul(
            (temp.ln().mul(exponent)).exp().sub(_one)
        );
        return result.toUInt();
    }

    /**
     * @notice Given a deposit (in the collateral token) Token supply of 0, calculates the return
     * for a given conversion (in the token)
     *
     * @dev _supply * ((1 + _tokensDeposited / _connectorBalance) ^ (_connectorWeight / 1000000) - 1)
     *
     * @param _tokensDeposited      amount of collateral tokens to deposit
     * @param _connectorWeight      connector weight, represented in ppm, 1 - 1,000,000
     * @param _baseX                constant x
     * @param _baseY                expected price
     * 
     * @return amount of Tokens minted
     */
    function _purchaseTargetAmountFromZero(
        uint256 _tokensDeposited,
        uint256 _connectorWeight,
        uint256 _baseX,
        uint256 _baseY
    ) internal view returns (uint256) {
        // (MAX_WEIGHT/reserveWeight -1)
        bytes16 _one = uintToBytes16(ONE);

        bytes16 exponent = uint256(MAX_WEIGHT).fromUInt().div(
            _connectorWeight.fromUInt()
        ).sub(_one);

        // Instead of calculating "x ^ exp", we calculate "e ^ (log(x) * exp)".
        // _baseY ^ (MAX_WEIGHT/reserveWeight -1)
        bytes16 denominator = (_baseY.fromUInt().ln().mul(exponent)).exp();

        // ( baseX * tokensDeposited  ^ (MAX_WEIGHT/reserveWeight -1) ) /  _baseY ^ (MAX_WEIGHT/reserveWeight -1)
        bytes16 res = _tokensDeposited.fromUInt().ln().mul(exponent).exp();
        bytes16 result = _baseX.fromUInt().mul(res).div(denominator);

        return result.toUInt();
    }

    function uintToBytes16(uint256 x) internal pure returns (bytes16 b) {
        require(x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, "Value too large for bytes16");
        b = bytes16(abi.encodePacked(x));
    }

}
