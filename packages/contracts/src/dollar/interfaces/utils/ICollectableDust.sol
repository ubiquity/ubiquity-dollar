// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @notice Interface for collecting dust (i.e. not part of a protocol) tokens sent to a contract
interface ICollectableDust {
    /// @notice Emitted when dust tokens are sent to the `_to` address
    event DustSent(address _to, address token, uint256 amount);

    /// @notice Emitted when token is added to a protocol
    event ProtocolTokenAdded(address _token);

    /// @notice Emitted when token is removed from a protocol
    event ProtocolTokenRemoved(address _token);

    /**
     * @notice Adds token address to a protocol
     * @param _token Token address to add
     */
    function addProtocolToken(address _token) external;

    /**
     * @notice Removes token address from a protocol
     * @param _token Token address to remove
     */
    function removeProtocolToken(address _token) external;

    /**
     * @notice Sends dust tokens (which are not part of a protocol) to the `_to` address
     * @param _to Tokens receiver address
     * @param _token Token address to send
     * @param _amount Amount of tokens to send
     */
    function sendDust(address _to, address _token, uint256 _amount) external;
}
