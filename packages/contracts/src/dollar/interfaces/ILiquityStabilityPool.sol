// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title ILiquityStabilityPool
 * @notice Interface for Liquity V1 Stability Pool (0x66017D22b0f8556afDd19e1e5b5f1cbD89a6C337)
 * @dev Used to deposit LUSD and earn ETH/LQTY rewards from liquidations
 */
interface ILiquityStabilityPool {
    /**
     * @notice Deposits LUSD into the Stability Pool
     * @param _amount Amount of LUSD to deposit
     * @param _frontEndTag Frontend operator address for kickback rate (use address(0) if none)
     */
    function provideToSP(uint256 _amount, address _frontEndTag) external;

    /**
     * @notice Withdraws LUSD from the Stability Pool
     * @param _amount Amount of LUSD to withdraw (0 = claim rewards only)
     */
    function withdrawFromSP(uint256 _amount) external;

    /**
     * @notice Returns the user's compounded LUSD deposit
     * @param _depositor Address of the depositor
     * @return Compounded LUSD deposit amount
     */
    function getCompoundedLUSDDeposit(
        address _depositor
    ) external view returns (uint256);

    /**
     * @notice Returns the depositor's accumulated ETH gain
     * @param _depositor Address of the depositor
     * @return ETH gain amount
     */
    function getDepositorETHGain(
        address _depositor
    ) external view returns (uint256);

    /**
     * @notice Returns the depositor's accumulated LQTY gain
     * @param _depositor Address of the depositor
     * @return LQTY gain amount
     */
    function getDepositorLQTYGain(
        address _depositor
    ) external view returns (uint256);
}
