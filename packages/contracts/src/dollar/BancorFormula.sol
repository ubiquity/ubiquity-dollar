// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

// import "./interfaces/IBancorFormula.sol";
import "./libs/BancorPower.sol";
import "./libs/ABDKMathQuad.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Bancor formula by Bancor
 * @dev Modified from the original by Slava Balasanov
 * @notice forked from :
 * https://github.com/bancorprotocol/contracts
 *
 */
contract BancorFormula is BancorPower {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    bytes16 private immutable ONE = (uint256(1)).fromUInt();
    uint32 private constant MAX_WEIGHT = 1000000;
    uint32 private immutable EULER = 0;

    function _calculatePurchasePrice(
        uint256 _maxPrice,
        uint256 _growthRate,
        uint256 _inflectionPoint,
        uint256 _tokenID
    ) internal view returns(uint256) {

        bytes16 res = _tokenID.fromUInt().sub(_inflectionPoint.fromUInt());

    }

    /**
     * @dev given a token supply, connector balance, weight and a deposit amount (in the connector token),
     * calculates the return for a given conversion (in the main token)
     *
     * Formula:
     * Return = _supply * ((1 + _depositAmount / _connectorBalance) ^ (_connectorWeight / 1000000) - 1)
     *
     * @param _supply              token total supply
     * @param _connectorBalance    total connector balance
     * @param _connectorWeight     connector weight, represented in ppm, 1-1000000
     * @param _depositAmount       deposit amount, in connector token
     *
     *  @return purchase return amount
     */
    function _calculatePurchaseReturn(
        uint256 _supply,
        uint256 _connectorBalance,
        uint32 _connectorWeight,
        uint256 _depositAmount
    ) internal view returns (uint256) {
        // validate input
        require(
            _connectorBalance > 0 && _connectorWeight > 0
                && _connectorWeight <= MAX_WEIGHT
        );

        // special case for 0 deposit amount
        if (_depositAmount == 0) {
            return 0;
        }

        // special case if the weight = 100%
        if (_connectorWeight == MAX_WEIGHT) {
            return (_supply * _depositAmount) / _connectorBalance;
        }

        bytes16 exponent = uint256(_connectorWeight).fromUInt().div(
            uint256(MAX_WEIGHT).fromUInt()
        );
        bytes16 part1 =
            ONE.add(_depositAmount.fromUInt().div(_connectorBalance.fromUInt()));

        //Instead of calculating "base ^ exp", we calculate "e ^ (log(base) * exp)".
        bytes16 res =
            _supply.fromUInt().mul((part1.ln().mul(exponent)).exp().sub(ONE));
        return res.toUInt();
    }

    /// @notice Given a deposit (in the collateral token) Token supply of 0, constant x and
    ///         constant y, calculates the return for a given conversion (in the Token)
    ///         Forked from Modified Bancor Zero by Carl Farterson.
    /// @dev  [tokensDeposited / (connectorWeight * baseX * baseY) / baseX ^ (MAX_WEIGHT/connectorWeight)] ^ connectorWeight
    /// @dev  _baseX and _baseY are needed as Bancor formula breaks from a divide-by-0 when supply=0
    /// @param _tokensDeposited     amount of collateral tokens to deposit
    /// @param _baseX               constant x (arbitrary point in supply)
    /// @param _baseY               constant y (expected price at the arbitrary point in supply)
    /// @return amount of Tokens minted
    function _calculatePurchaseReturnFromZero(
        uint256 _tokensDeposited,
        uint256 _connectorWeight,
        uint256 _baseX,
        uint256 _baseY
    ) internal view returns (uint256) {
        // (MAX_WEIGHT/reserveWeight -1)
        bytes16 exponent = uint256(MAX_WEIGHT).fromUInt().div(
            _connectorWeight.fromUInt()
        ).sub(ONE);

        // Instead of calculating "x ^ exp", we calculate "e ^ (log(x) * exp)".
        // _baseY ^ (MAX_WEIGHT/reserveWeight -1)
        bytes16 denominator = (_baseY.fromUInt().ln().mul(exponent)).exp();

        // ( baseX * tokensDeposited  ^ (MAX_WEIGHT/reserveWeight -1) ) /  _baseY ^ (MAX_WEIGHT/reserveWeight -1)
        bytes16 res = _baseX.fromUInt().mul(
            _tokensDeposited.fromUInt().ln().mul(exponent).exp()
        ).div(denominator);

        return res.toUInt();
    }

    /// @notice Given an amount of Tokens to burn, connector weight, supply and collateral pooled,
    ///     calculates the return for a given conversion (in the collateral token)
    /// @dev _connectorBalance * (1 - (1 - _TokensBurned/_supply) ^ (1 / (_connectorWeight / 1000000)))
    /// @param _sellAmount        amount of Tokens to burn
    /// @param _connectorWeight     connector weight, represented in ppm, 1 - 1,000,000
    /// @param _supply              current Token supply
    /// @param _connectorBalance    total connector balance
    /// @return amount of collateral tokens received
    function _calculateSaleReturn(
        uint256 _sellAmount,
        uint32 _connectorWeight,
        uint256 _supply,
        uint256 _connectorBalance
    ) internal view returns (uint256) {
        // validate input
        require(
            _supply > 0 && _connectorBalance > 0 && _connectorWeight > 0
                && _connectorWeight <= MAX_WEIGHT && _sellAmount <= _supply
        );

        // special case for 0 sell amount
        if (_sellAmount == 0) {
            return 0;
        }
        // special case for selling the entire supply
        if (_sellAmount == _supply) {
            return _connectorBalance;
        }
        // special case if the weight = 100%
        if (_connectorWeight == MAX_WEIGHT) {
            return (_connectorBalance * _sellAmount) / _supply;
        }

        // 1 / (connectorWeight/MAX_WEIGHT)
        bytes16 exponent = ONE.div(
            uint256(_connectorWeight).fromUInt().div(
                uint256(MAX_WEIGHT).fromUInt()
            )
        );

        // 1 - (TokensBurned / supply)
        bytes16 s = ONE.sub(_sellAmount.fromUInt().div(_supply.fromUInt()));

        // Instead of calculating "s ^ exp", we calculate "e ^ (log(s) * exp)".
        // connectorBalance - ( connectorBalance * s ^ exp))
        bytes16 res = _connectorBalance.fromUInt().sub(
            _connectorBalance.fromUInt().mul(s.ln().mul(exponent).exp())
        );
        return res.toUInt();
    }
}
