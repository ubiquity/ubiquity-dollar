// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LibChef} from "../libraries/LibChef.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

/**
 * @notice Contract facet for staking Dollar-3CRV LP tokens for Governance tokens reward
 */
contract ChefFacet is Modifiers {
    /**
     * @notice Sets amount of Governance tokens minted each block
     * @param _governancePerBlock Amount of Governance tokens minted each block
     */
    function setGovernancePerBlock(
        uint256 _governancePerBlock
    ) external onlyTokenManager {
        LibChef.setGovernancePerBlock(_governancePerBlock);
    }

    /**
     * @notice Sets Governance token divider param. The bigger `_governanceDivider` the less extra
     * Governance tokens will be minted for the treasury.
     * @notice Example: if `_governanceDivider = 5` then `100 / 5 = 20%` extra minted Governance tokens for treasury
     * @param _governanceDivider Governance divider param value
     */
    function setGovernanceShareForTreasury(
        uint256 _governanceDivider
    ) external onlyTokenManager {
        LibChef.setGovernanceShareForTreasury(_governanceDivider);
    }

    /**
     * @notice Sets min price difference between the old and the new Dollar prices
     * @param _minPriceDiffToUpdateMultiplier Min price diff to update governance multiplier
     */
    function setMinPriceDiffToUpdateMultiplier(
        uint256 _minPriceDiffToUpdateMultiplier
    ) external onlyTokenManager {
        LibChef.setMinPriceDiffToUpdateMultiplier(
            _minPriceDiffToUpdateMultiplier
        );
    }

    /**
     * @notice Withdraws pending Governance token rewards
     * @param stakingShareID Staking share id
     * @return Reward amount transferred to `msg.sender`
     */
    function getRewards(uint256 stakingShareID) external returns (uint256) {
        return LibChef.getRewards(stakingShareID);
    }

    /**
     * @notice Returns governance multiplier
     * @return Governance multiplier
     */
    function governanceMultiplier() external view returns (uint256) {
        return LibChef._getGovernanceMultiplier();
    }

    /**
     * @notice Returns amount of Governance tokens minted each block
     * @return Amount of Governance tokens minted each block
     */
    function governancePerBlock() external view returns (uint256) {
        return LibChef.governancePerBlock();
    }

    /**
     * @notice Returns governance divider param
     * @notice Example: if `_governanceDivider = 5` then `100 / 5 = 20%` extra minted Governance tokens for treasury
     * @return Governance divider param value
     */
    function governanceDivider() external view returns (uint256) {
        return LibChef.governanceDivider();
    }

    /**
     * @notice Returns pool info
     * @return Last block number when Governance tokens distribution occurred
     * @return Accumulated Governance tokens per share, times 1e12
     */
    function pool() external view returns (uint256, uint256) {
        LibChef.PoolInfo memory _pool = LibChef.pool();

        return (_pool.lastRewardBlock, _pool.accGovernancePerShare);
    }

    /**
     * @notice Returns min price difference between the old and the new Dollar prices
     * required to update the governance multiplier
     * @return Min Dollar price diff to update the governance multiplier
     */
    function minPriceDiffToUpdateMultiplier() external view returns (uint256) {
        return LibChef.minPriceDiffToUpdateMultiplier();
    }

    /**
     * @notice Returns amount of pending reward Governance tokens
     * @param stakingShareID Staking share id
     * @return Amount of pending reward Governance tokens
     */
    function pendingGovernance(
        uint256 stakingShareID
    ) external view returns (uint256) {
        return LibChef.pendingGovernance(stakingShareID);
    }

    /**
     * @notice Returns staking share info
     * @param _id Staking share id
     * @return Array of amount of shares and reward debt
     */
    function getStakingShareInfo(
        uint256 _id
    ) external view returns (uint256[2] memory) {
        return LibChef.getStakingShareInfo(_id);
    }

    /**
     * @notice Total amount of Dollar-3CRV LP tokens deposited to the Staking contract
     * @return Total amount of deposited LP tokens
     */
    function totalShares() external view returns (uint256) {
        return LibChef.totalShares();
    }
}
