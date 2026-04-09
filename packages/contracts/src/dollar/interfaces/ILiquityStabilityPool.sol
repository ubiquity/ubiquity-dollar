// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @notice Interface for the Liquity V1 Stability Pool
/// @dev See: https://github.com/liquity/dev/blob/main/packages/contracts/contracts/StabilityPool.sol
interface ILiquityStabilityPool {
    // --- Events ---

    event UserDepositChanged(address indexed _depositor, uint256 _newDeposit);
    event ETHGainWithdrawn(address indexed _depositor, uint256 _ETH, uint256 _LUSDLoss);
    event LQTYPaidToDepositor(address indexed _depositor, uint256 _LQTY);

    // --- Functions ---

    /// @notice Deposits LUSD into the Stability Pool
    /// @param _amount Amount of LUSD to deposit
    function provideToSP(uint256 _amount) external;

    /// @notice Deposits LUSD into the Stability Pool with front end tag
    /// @param _amount Amount of LUSD to deposit
    /// @param _frontEndTag Address of the front end to tag
    function provideToSP(uint256 _amount, address _frontEndTag) external;

    /// @notice Withdraws LUSD from the Stability Pool
    /// @param _amount Amount of LUSD to withdraw
    function withdrawFromSP(uint256 _amount) external;

    /// @notice Withdraws all LUSD from the Stability Pool
    function withdrawFromSP() external;

    /// @notice Gets the depositor's ETH gain
    /// @param _depositor Address of the depositor
    /// @return ETH gain for the depositor
    function getDepositorETHGain(address _depositor) external view returns (uint256);

    /// @notice Gets the depositor's LQTY gain
    /// @param _depositor Address of the depositor
    /// @return LQTY gain for the depositor
    function getDepositorLQTYGain(address _depositor) external view returns (uint256);

    /// @notice Gets the compounded LUSD deposit for a depositor
    /// @param _depositor Address of the depositor
    /// @return Compounded LUSD deposit amount
    function getCompoundedLUSDDeposit(address _depositor) external view returns (uint256);

    /// @notice Gets depositor info: deposit, ETH gain, LQTY gain
    /// @param _depositor Address of the depositor
    /// @return deposit, ETH gain, LQTY gain
    function getDepositorInfo(address _depositor) external view returns (uint256, uint256, uint256);
}
