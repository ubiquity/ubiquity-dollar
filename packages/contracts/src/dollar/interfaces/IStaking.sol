// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LibStaking} from "../libraries/LibStaking.sol";

/**
 * @notice Ubiquity staking interface
 * @dev Derived from https://github.com/sushi-labs/sushiswap/blob/271458b558afa6fdfd3e46b8eef5ee6618b60f9d/contracts/MasterChef.sol
 */
interface IStaking {
    //=====================
    // Views
    //=====================

    /**
     * @notice View function to see pending Governance tokens on frontend
     * @param poolId Pool id
     * @param user User address
     * @return Staking rewards amount
     */
    function getPendingStakingRewards(
        uint256 poolId,
        address user
    ) external view returns (uint256);

    /**
     * @notice Returns reward multiplier over the given `from` to `to` blocks
     * @param from From block number
     * @param to To block number
     * @return Reward multiplier
     */
    function getStakingMultiplier(
        uint256 from,
        uint256 to
    ) external view returns (uint256);

    /**
     * @notice Returns staking settings
     * @return Returns:
     * - Reward token address
     * - Bonus end block
     * - Governance token bonus multiplier
     * - Governance tokens minted per block
     * - Governance token divider for treasury
     * - Total available reward amount
     * - Total allocation points across all staking pools
     * - Start block when staking starts
     */
    function getStakingSettings()
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    /**
     * @notice View function to see user's staking info
     * @param poolId Pool id
     * @param user User address
     * @return User's staking info
     */
    function getStakingUserInfo(
        uint256 poolId,
        address user
    ) external view returns (LibStaking.UserInfo memory);

    /**
     * @notice View function to see pool's staking info
     * @param poolId Pool id
     * @return Pool's staking info
     */
    function getStakingPoolInfo(
        uint256 poolId
    ) external view returns (LibStaking.PoolInfo memory);

    /**
     * @notice Returns total staking pools length
     * @return Pools length
     */
    function getStakingPoolsLength() external view returns (uint256);

    //==================
    // Public methods
    //==================

    /**
     * @notice Updates reward variables for all pools
     */
    function massUpdateStakingPools() external;

    /**
     * @notice Stakes LP tokens to the staking contract for Governance tokens allocation
     * @param poolId Pool id
     * @param amount Amount of LP tokens to stake
     */
    function stake(uint256 poolId, uint256 amount) external;

    /**
     * @notice Unstakes LP tokens from the staking contract
     * @param poolId Pool id
     * @param amount Amount of LP tokens to unstake
     */
    function unstake(uint256 poolId, uint256 amount) external;

    /**
     * @notice Updates reward variables of the given pool to be up-to-date
     * @param poolId Pool id
     */
    function updateStakingPool(uint256 poolId) external;

    //======================
    // Restricted methods
    //======================

    /**
     * @notice Adds a new staking pool
     * @notice The following LP tokens with "weird" ERC20 behavior are not supported:
     * - Fee on Transfer: https://github.com/d-xo/weird-erc20?tab=readme-ov-file#fee-on-transfer
     * - Rebasing: https://github.com/d-xo/weird-erc20?tab=readme-ov-file#balance-modifications-outside-of-transfers-rebasingairdrops
     * - Pausable Tokens: https://github.com/d-xo/weird-erc20?tab=readme-ov-file#pausable-tokens
     * - Transfer of less than amount: https://github.com/d-xo/weird-erc20?tab=readme-ov-file#transfer-of-less-than-amount
     * @param allocationPoints Allocation points
     * @param lpToken LP token
     */
    function createStakingPool(
        uint256 allocationPoints,
        IERC20 lpToken
    ) external;

    /**
     * @notice Sets last block number when Governance bonus emissions end
     * @param newGovernanceBonusEndBlock Block number when Governance bonus emissions end
     */
    function setGovernanceBonusEndBlock(
        uint256 newGovernanceBonusEndBlock
    ) external;

    /**
     * @notice Sets bonus multiplier for early Governance token makers
     * @param newGovernanceBonusMultiplier New governance bonus multiplier
     */
    function setGovernanceBonusMultiplier(
        uint256 newGovernanceBonusMultiplier
    ) external;

    /**
     * @notice Sets Governance tokens reward per block
     * @dev If `newGovernancePerBlock < 0.0001 ether` users may end up getting 0 rewards 
     * if staked amount > 1_000_000_000e18
     * @param newGovernancePerBlock New amount of Governance tokens minted each block
     */
    function setGovernancePerBlock(uint256 newGovernancePerBlock) external;

    /**
     * @notice Sets Governance token divider param for treasury. The bigger `governanceTreasuryDivider` the less extra
     * Governance tokens will be minted for the treasury.
     * @notice Example: if `governanceTreasuryDivider = 5` then `100 / 5 = 20%` extra minted Governance tokens for treasury
     * @notice Set `governanceTreasuryDivider` to 0 if you want to disable minting rewards to the treasury
     * @param newGovernanceTreasuryDivider New governance divider param value
     */
    function setGovernanceTreasuryDivider(
        uint256 newGovernanceTreasuryDivider
    ) external;

    /**
     * @notice Sets staking reward token
     * @notice The following reward tokens with "weird" ERC20 behavior are not supported:
     * - Rebasing: https://github.com/d-xo/weird-erc20?tab=readme-ov-file#balance-modifications-outside-of-transfers-rebasingairdrops
     * - Pausable Tokens: https://github.com/d-xo/weird-erc20?tab=readme-ov-file#pausable-tokens
     * - Transfer of less than amount: https://github.com/d-xo/weird-erc20?tab=readme-ov-file#transfer-of-less-than-amount
     * @param newRewardToken New reward token address
     */
    function setStakingRewardToken(address newRewardToken) external;

    /**
     * @notice Sets start block when staking should be active
     * @param newStartBlock Block number when staking should be active
     */
    function setStakingStartBlock(uint256 newStartBlock) external;

    /**
     * @notice Updates the given pool's Governance token allocation points
     * @param poolId Pool id
     * @param allocationPoints New allocation points
     */
    function updateStakingPool(
        uint256 poolId,
        uint256 allocationPoints
    ) external;
}
