// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IERC1155Ubiquity.sol";

/// @title ERC1155 Ubiquity preset interface
/// @author Ubiquity DAO
interface IStakingToken is IERC1155Ubiquity {
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

    function getStake(uint256 id) external view returns (Stake memory);
}
