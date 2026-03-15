// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

/**
 * @notice Stability Pool facet interface
 * @notice Manages LUSD deposits into Liquity V1 Stability Pool,
 *         enabling yield generation on protocol-held LUSD collateral.
 *         ETH and LQTY gains are harvested for buybacks/compounding.
 */
interface IStabilityPoolFacet {
    //=====================
    // Events
    //=====================

    /// @notice Emitted when LUSD is deposited to the Liquity Stability Pool
    event DepositedToStabilityPool(uint256 amount);

    /// @notice Emitted when LUSD is withdrawn from the Liquity Stability Pool
    event WithdrawnFromStabilityPool(uint256 amount);

    /// @notice Emitted when ETH/LQTY gains are harvested
    event GainsHarvested(
        uint256 ethGain,
        uint256 lqtyGain,
        address treasury
    );

    /// @notice Emitted when the Stability Pool address is configured
    event StabilityPoolAddressSet(address stabilityPool);

    /// @notice Emitted when the LUSD token address is configured
    event LusdTokenAddressSet(address lusdToken);

    /// @notice Emitted when the LQTY token address is configured
    event LqtyTokenAddressSet(address lqtyToken);

    /// @notice Emitted when the protocol treasury address is configured
    event ProtocolTreasurySet(address treasury);

    /// @notice Emitted when the frontend tag is updated
    event FrontEndTagSet(address frontEndTag);

    //=====================
    // Views
    //=====================

    /**
     * @notice Returns the current compounded LUSD balance in the Stability Pool
     * @return Current LUSD deposit (after liquidation absorptions)
     */
    function getPoolBalance() external view returns (uint256);

    /**
     * @notice Returns the total principal deposited (before liquidation losses)
     * @return Total LUSD principal deposited to pool
     */
    function getTotalPrincipal() external view returns (uint256);

    /**
     * @notice Returns the pending ETH gain from liquidations
     * @return ETH gain accrued by the diamond
     */
    function getETHGain() external view returns (uint256);

    /**
     * @notice Returns the pending LQTY reward gain
     * @return LQTY gain accrued by the diamond
     */
    function getLQTYGain() external view returns (uint256);

    //====================
    // Public functions
    //====================

    /**
     * @notice Deposits LUSD into the Liquity Stability Pool
     * @dev Piggybacked on mint operations for gas efficiency.
     *      Transfers LUSD from msg.sender (or the diamond's own balance) to the pool.
     * @param amount Amount of LUSD to deposit
     */
    function depositToStabilityPool(uint256 amount) external;

    /**
     * @notice Withdraws LUSD from the Liquity Stability Pool
     * @dev Piggybacked on redeem operations. Also triggers harvest of pending gains.
     * @param amount Amount of LUSD to withdraw
     */
    function withdrawFromStabilityPool(uint256 amount) external;

    /**
     * @notice Harvests ETH and LQTY gains, sending them to the protocol treasury
     * @dev Can be called independently or piggybacked on redeems.
     *      Withdraws 0 from SP to trigger gain collection without reducing deposit.
     */
    function harvestGains() external;

    //========================
    // Restricted functions
    //========================

    /**
     * @notice Sets the Liquity Stability Pool contract address
     * @param stabilityPool Address of the Liquity Stability Pool
     */
    function setStabilityPoolAddress(address stabilityPool) external;

    /**
     * @notice Sets the LUSD token address
     * @param lusdToken Address of the LUSD ERC20 token
     */
    function setLusdTokenAddress(address lusdToken) external;

    /**
     * @notice Sets the LQTY token address
     * @param lqtyToken Address of the LQTY ERC20 token
     */
    function setLqtyTokenAddress(address lqtyToken) external;

    /**
     * @notice Sets the protocol treasury address for harvested gains
     * @param treasury Address of the protocol treasury
     */
    function setProtocolTreasury(address treasury) external;

    /**
     * @notice Sets the frontend tag used for Liquity frontend kickback rewards
     * @param frontEndTag Address of the frontend operator
     */
    function setFrontEndTag(address frontEndTag) external;
}
