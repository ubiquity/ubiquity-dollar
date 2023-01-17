// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibUbiquityChef} from "../libraries/LibUbiquityChef.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

contract UbiquityChefFacet is Modifiers {
    function setGovernancePerBlock(uint256 _governancePerBlock)
        external
        onlyTokenManager
    {
        LibUbiquityChef.setGovernancePerBlock(_governancePerBlock);
    }

    // the bigger governanceDivider is the less extra Governance Tokens will be minted for the treasury
    function setGovernanceShareForTreasury(uint256 _governanceDivider)
        external
        onlyTokenManager
    {
        LibUbiquityChef.setGovernanceShareForTreasury(_governanceDivider);
    }

    function setMinPriceDiffToUpdateMultiplier(
        uint256 _minPriceDiffToUpdateMultiplier
    ) external onlyTokenManager {
        LibUbiquityChef.setMinPriceDiffToUpdateMultiplier(
            _minPriceDiffToUpdateMultiplier
        );
    }

    /// @dev get pending Governance Token rewards from MasterChef.
    /// @return amount of pending rewards transferred to msg.sender
    /// @notice only send pending rewards
    function getRewards(uint256 stakingShareID) external returns (uint256) {
        return LibUbiquityChef.getRewards(stakingShareID);
    }

    /**
     * @dev get the governance Per Block.
     */
    function governancePerBlock() external view returns (uint256) {
        return LibUbiquityChef.governancePerBlock();
    }

    /**
     * @dev get the governance divider.
     */
    function governanceDivider() external view returns (uint256) {
        return LibUbiquityChef.governanceDivider();
    }

    /**
     * @dev get the pool information.
     */
    function pool() external view returns (uint256, uint256) {
        LibUbiquityChef.PoolInfo memory _pool = LibUbiquityChef.pool();

        return (_pool.lastRewardBlock, _pool.accGovernancePerShare);
    }

    /**
     * @dev get the minimum price differrence to update the multiplier.
     */
    function minPriceDiffToUpdateMultiplier() external view returns (uint256) {
        return LibUbiquityChef.minPriceDiffToUpdateMultiplier();
    }

    // View function to see pending Governance Tokens on frontend.
    function pendingGovernance(uint256 stakingShareID)
        external
        view
        returns (uint256)
    {
        return LibUbiquityChef.pendingGovernance(stakingShareID);
    }

    /**
     * @dev get the amount of shares and the reward debt of a staking share .
     */
    function getStakingShareInfo(uint256 _id)
        external
        view
        returns (uint256[2] memory)
    {
        return LibUbiquityChef.getStakingShareInfo(_id);
    }

    /**
     * @dev Total amount of shares .
     */
    function totalShares() external view returns (uint256) {
        return LibUbiquityChef.totalShares();
    }
}
