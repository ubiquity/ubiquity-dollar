// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {LibChef} from "../libraries/LibChef.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

contract ChefFacet is Modifiers {
    function setGovernancePerBlock(
        uint256 _governancePerBlock
    ) external onlyTokenManager {
        LibChef.setGovernancePerBlock(_governancePerBlock);
    }

    // the bigger governanceDivider is the less extra Governance Tokens will be minted for the treasury
    function setGovernanceShareForTreasury(
        uint256 _governanceDivider
    ) external onlyTokenManager {
        LibChef.setGovernanceShareForTreasury(_governanceDivider);
    }

    function setMinPriceDiffToUpdateMultiplier(
        uint256 _minPriceDiffToUpdateMultiplier
    ) external onlyTokenManager {
        LibChef.setMinPriceDiffToUpdateMultiplier(
            _minPriceDiffToUpdateMultiplier
        );
    }

    /// @dev get pending Governance Token rewards from MasterChef.
    /// @return amount of pending rewards transferred to msg.sender
    /// @notice only send pending rewards
    function getRewards(uint256 stakingShareID) external returns (uint256) {
        return LibChef.getRewards(stakingShareID);
    }

    /**
     * @dev get the governance Per Block.
     */
    function governancePerBlock() external view returns (uint256) {
        return LibChef.governancePerBlock();
    }

    /**
     * @dev get the governance divider.
     */
    function governanceDivider() external view returns (uint256) {
        return LibChef.governanceDivider();
    }

    /**
     * @dev get the pool information.
     */
    function pool() external view returns (uint256, uint256) {
        LibChef.PoolInfo memory _pool = LibChef.pool();

        return (_pool.lastRewardBlock, _pool.accGovernancePerShare);
    }

    /**
     * @dev get the minimum price difference to update the multiplier.
     */
    function minPriceDiffToUpdateMultiplier() external view returns (uint256) {
        return LibChef.minPriceDiffToUpdateMultiplier();
    }

    // View function to see pending Governance Tokens on frontend.
    function pendingGovernance(
        uint256 stakingShareID
    ) external view returns (uint256) {
        return LibChef.pendingGovernance(stakingShareID);
    }

    /**
     * @dev get the amount of shares and the reward debt of a staking share .
     */
    function getStakingShareInfo(
        uint256 _id
    ) external view returns (uint256[2] memory) {
        return LibChef.getStakingShareInfo(_id);
    }

    /**
     * @dev Total amount of shares .
     */
    function totalShares() external view returns (uint256) {
        return LibChef.totalShares();
    }
}
