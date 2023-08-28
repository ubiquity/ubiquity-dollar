// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LibBondingCurve} from "../libraries/LibBondingCurve.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

import {IBondingCurve} from "../../dollar/interfaces/IBondingCurve.sol";

/**
 * @notice Bonding curve contract based on Bancor formula
 * @notice Inspired from Bancor protocol https://github.com/bancorprotocol/contracts
 * @notice Used on UbiquiStick NFT minting
 */
contract BondingCurveFacet is Modifiers, IBondingCurve {
    /**
     * @notice Sets bonding curve params
     * @param _connectorWeight Connector weight
     * @param _baseY Base Y
     */
    function setParams(
        uint32 _connectorWeight,
        uint256 _baseY
    ) external onlyAdmin {
        LibBondingCurve.setParams(_connectorWeight, _baseY);
    }

    /**
     * @notice Returns `connectorWeight` value
     * @return Connector weight value
     */
    function connectorWeight() external view returns (uint32) {
        return LibBondingCurve.connectorWeight();
    }

    /**
     * @notice Returns `baseY` value
     * @return Base Y value
     */
    function baseY() external view returns (uint256) {
        return LibBondingCurve.baseY();
    }

    /**
     * @notice Returns total balance of deposited collateral
     * @return Amount of deposited collateral
     */
    function poolBalance() external view returns (uint256) {
        return LibBondingCurve.poolBalance();
    }

    /**
     * @notice Deposits collateral tokens in exchange for UbiquiStick NFT
     * @param _collateralDeposited Amount of collateral
     * @param _recipient Address to receive the NFT
     */
    function deposit(
        uint256 _collateralDeposited,
        address _recipient
    ) external {
        LibBondingCurve.deposit(_collateralDeposited, _recipient);
    }

    /**
     * @notice Returns number of NFTs a `_recipient` holds
     * @param _recipient User address
     * @return Amount of NFTs for `_recipient`
     */
    function getShare(address _recipient) external view returns (uint256) {
        return LibBondingCurve.getShare(_recipient);
    }

    /**
     * @notice Withdraws collateral tokens to treasury
     * @param _amount Amount of collateral tokens to withdraw
     */
    function withdraw(uint256 _amount) external onlyAdmin whenNotPaused {
        LibBondingCurve.withdraw(_amount);
    }

    /**
     * @notice Given a token supply, reserve balance, weight and a deposit amount (in the reserve token),
     * calculates the target amount for a given conversion (in the main token)
     *
     * @notice `_supply * ((1 + _tokensDeposited / _connectorBalance) ^ (_connectorWeight / 1000000) - 1)`
     *
     * @param _tokensDeposited Amount of collateral tokens to deposit
     * @param _connectorWeight Connector weight, represented in ppm, 1 - 1,000,000
     * @param _supply Current token supply
     * @param _connectorBalance Total connector balance
     * @return Amount of tokens minted
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
     * @notice Given a deposit (in the collateral token) token supply of 0, calculates the return
     * for a given conversion (in the token)
     *
     * @notice `_supply * ((1 + _tokensDeposited / _connectorBalance) ^ (_connectorWeight / 1000000) - 1)`
     *
     * @param _tokensDeposited Amount of collateral tokens to deposit
     * @param _connectorWeight Connector weight, represented in ppm, 1 - 1,000,000
     * @param _baseX Constant x
     * @param _baseY Expected price
     * @return Amount of tokens minted
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
