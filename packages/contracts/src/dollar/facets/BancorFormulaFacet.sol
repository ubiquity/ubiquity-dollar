// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {LibBancorFormula} from "../libraries/LibBancorFormula.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

/**
 * @title Bancor formula
 * @dev Modified from the original
 * @notice forked from Bancor:
 * https://github.com/bancorprotocol/contracts
 *
 */
contract BancorFormulaFacet is Modifiers {
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
    ) external returns(uint256) {
        return LibBancorFormula._purchaseTargetAmount(
            _tokensDeposited,
            _connectorWeight,
            _supply,
            _connectorBalance
        );
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
    ) external returns (uint256) {
        return LibBancorFormula._purchaseTargetAmountFromZero(
            _tokensDeposited,
            _connectorWeight,
            _baseX,
            _baseY
        );
    }

}
