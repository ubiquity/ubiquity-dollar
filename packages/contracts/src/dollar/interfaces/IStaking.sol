// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @notice Staking interface
interface IStaking {
    /**
     * @notice Deposits UbiquityDollar-3CRV LP tokens for a duration to receive staking shares
     * @notice Weeks act as a multiplier for the amount of staking shares to be received
     * @param _lpsAmount Amount of LP tokens to send
     * @param _weeks Number of weeks during which LP tokens will be held
     * @return _id Staking share id
     */
    function deposit(
        uint256 _lpsAmount,
        uint256 _weeks
    ) external returns (uint256 _id);

    /**
     * @notice Adds an amount of UbiquityDollar-3CRV LP tokens
     * @notice Staking shares are ERC1155 (aka NFT) because they have an expiration date
     * @param _amount Amount of LP token to deposit
     * @param _id Staking share id
     * @param _weeks Number of weeks during which LP tokens will be held
     */
    function addLiquidity(
        uint256 _amount,
        uint256 _id,
        uint256 _weeks
    ) external;

    /**
     * @notice Removes an amount of UbiquityDollar-3CRV LP tokens
     * @notice Staking shares are ERC1155 (aka NFT) because they have an expiration date
     * @param _amount Amount of LP token deposited when `_id` was created to be withdrawn
     * @param _id Staking share id
     */
    function removeLiquidity(uint256 _amount, uint256 _id) external;
}
