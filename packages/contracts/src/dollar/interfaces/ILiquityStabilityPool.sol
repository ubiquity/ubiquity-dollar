// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

/**
 * @notice Liquity V1 Stability Pool interface
 * @dev Mainnet deployment: 0x66017D22b0f8556afDd19e1e5b5f1cbD89a6C337
 */
interface ILiquityStabilityPool {
    /**
     * @notice Deposits LUSD to the Stability Pool
     * @param _amount Amount of LUSD to deposit
     * @param _frontEndTag Frontend operator address for kickback rate (use address(0) for no frontend)
     */
    function provideToSP(uint256 _amount, address _frontEndTag) external;

    /**
     * @notice Withdraws LUSD from the Stability Pool
     * @param _amount Amount of LUSD to withdraw. Use type(uint256).max to withdraw entire deposit.
     */
    function withdrawFromSP(uint256 _amount) external;

    /**
     * @notice Returns the ETH gain for a given depositor
     * @param _depositor Address of the depositor
     * @return ETH gain accrued by the depositor
     */
    function getDepositorETHGain(
        address _depositor
    ) external view returns (uint256);

    /**
     * @notice Returns the LQTY gain for a given depositor
     * @param _depositor Address of the depositor
     * @return LQTY gain accrued by the depositor
     */
    function getDepositorLQTYGain(
        address _depositor
    ) external view returns (uint256);

    /**
     * @notice Returns the compounded LUSD deposit for a given depositor.
     *         The compounded deposit reflects the principal minus any losses from
     *         liquidation absorptions.
     * @param _depositor Address of the depositor
     * @return Compounded LUSD deposit remaining
     */
    function getCompoundedLUSDDeposit(
        address _depositor
    ) external view returns (uint256);
}
