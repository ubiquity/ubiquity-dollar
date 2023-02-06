// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title incentive contract interface
/// @notice Called by Ubiquity Dollar token contract when transferring with an incentivized address
/// @dev should be appointed as a Minter or Burner as needed
interface IIncentive {
    /// @notice apply incentives on transfer
    /// @param sender the sender address of Ubiquity Dollar
    /// @param receiver the receiver address of Ubiquity Dollar
    /// @param operator the operator (msg.sender) of the transfer
    /// @param amount the amount of Ubiquity Dollar transferred
    function incentivize(
        address sender,
        address receiver,
        address operator,
        uint256 amount
    ) external;
}
