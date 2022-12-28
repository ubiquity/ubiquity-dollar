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
