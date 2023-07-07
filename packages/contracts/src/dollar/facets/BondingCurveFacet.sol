// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {LibBondingCurve} from "../libraries/LibBondingCurve.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

import {IBondingCurve} from "../../dollar/interfaces/IBondingCurve.sol";

/**
 * @title Bonding Curve
 * @dev Bonding curve contract based on Bancor formula
 * Inspired from Bancor protocol
 * https://github.com/bancorprotocol/contracts
 */

contract BondingCurveFacet is Modifiers, IBondingCurve {
    function setParams(
        uint32 _connectorWeight,
        uint256 _baseY
    ) external onlyAdmin {
        LibBondingCurve.setParams(_connectorWeight, _baseY);
    }

    function connectorWeight() external view returns (uint32) {
        return LibBondingCurve.connectorWeight();
    }

    function baseY() external view returns (uint256) {
        return LibBondingCurve.baseY();
    }

    function poolBalance() external view returns (uint256) {
        return LibBondingCurve.poolBalance();
    }

    /// @notice
    /// @dev
    /// @param _collateralDeposited Amount of collateral
    /// @param _recipient An address to receive the NFT
    function deposit(
        uint256 _collateralDeposited,
        address _recipient
    ) external {
        LibBondingCurve.deposit(_collateralDeposited, _recipient);
    }

    function getShare(address _recipient) external view returns (uint256) {
        return LibBondingCurve.getShare(_recipient);
    }

    function withdraw(uint256 _amount) external onlyAdmin whenNotPaused {
        LibBondingCurve.withdraw(_amount);
    }

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
    function purchaseTargetAmount(
        uint256 _tokensDeposited,
        uint32 _connectorWeight,
        uint256 _supply,
        uint256 _connectorBalance
    ) external pure returns (uint256) {
        return
            LibBondingCurve.purchaseTargetAmount(
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
    function purchaseTargetAmountFromZero(
        uint256 _tokensDeposited,
        uint256 _connectorWeight,
        uint256 _baseX,
        uint256 _baseY
    ) external pure returns (uint256) {
        return
            LibBondingCurve.purchaseTargetAmountFromZero(
                _tokensDeposited,
                _connectorWeight,
                _baseX,
                _baseY
            );
    }
}
