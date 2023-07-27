// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IERC1155Ubiquity.sol";

/// @notice Interface representing a staking share in the form of ERC1155 token
interface IStakingShare is IERC1155Ubiquity {
    /// @notice Stake struct
    struct Stake {
        // address of the minter
        address minter;
        // lp amount deposited by the user
        uint256 lpFirstDeposited;
        uint256 creationBlock;
        // lp that were already there when created
        uint256 lpRewardDebt;
        uint256 endBlock;
        // lp remaining for a user
        uint256 lpAmount;
    }

    /**
     * @notice Returns stake info by stake `id`
     * @param id Stake id
     * @return Stake info
     */
    function getStake(uint256 id) external view returns (Stake memory);
}
