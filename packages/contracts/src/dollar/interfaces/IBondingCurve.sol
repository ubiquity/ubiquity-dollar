// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @notice Interface based on Bancor formula
 * @notice Inspired from Bancor protocol https://github.com/bancorprotocol/contracts
 * @notice Used on UbiquiStick NFT minting
 */
interface IBondingCurve {
    /**
     * @notice Sets bonding curve params
     * @param _connectorWeight Connector weight
     * @param _baseY Base Y
     */
    function setParams(uint32 _connectorWeight, uint256 _baseY) external;

    /**
     * @notice Returns `connectorWeight` value
     * @return Connector weight value
     */
    function connectorWeight() external returns (uint32);

    /**
     * @notice Returns `baseY` value
     * @return Base Y value
     */
    function baseY() external returns (uint256);

    /**
     * @notice Returns total balance of deposited collateral
     * @return Amount of deposited collateral
     */
    function poolBalance() external returns (uint256);

    /**
     * @notice Deposits collateral tokens in exchange for UbiquiStick NFT
     * @param _collateralDeposited Amount of collateral
     * @param _recipient Address to receive the NFT
     */
    function deposit(uint256 _collateralDeposited, address _recipient) external;

    /**
     * @notice Withdraws collateral tokens to treasury
     * @param _amount Amount of collateral tokens to withdraw
     */
    function withdraw(uint256 _amount) external;
}
