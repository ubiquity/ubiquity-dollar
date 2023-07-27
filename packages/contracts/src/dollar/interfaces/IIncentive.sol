// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @notice Incentive contract interface
 * @notice Called by Ubiquity Dollar token contract when transferring with an incentivized address.
 * Dollar admin can set an incentive contract for a partner in order to, for example, mint partner's
 * project tokens on Dollars transfers. Incentive contracts can be set for the following transfer operations:
 * - EOA => contract
 * - contract => EOA
 * - contract => contract
 * - any transfer incentive contract
 * @dev Should be appointed as a Minter or Burner as needed
 */
interface IIncentive {
    /**
     * @notice Applies incentives on transfer
     * @param sender the sender address of Ubiquity Dollar
     * @param receiver the receiver address of Ubiquity Dollar
     * @param operator the operator (msg.sender) of the transfer
     * @param amount the amount of Ubiquity Dollar transferred
     */
    function incentivize(
        address sender,
        address receiver,
        address operator,
        uint256 amount
    ) external;
}
