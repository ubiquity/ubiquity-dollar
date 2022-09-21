// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISimpleBond {
  event LogSetRewards(address token, uint256 rewardsRatio);

  event LogBond(address addr, address token, uint256 amount, uint256 rewards, uint256 block, uint256 bondId);

  event LogClaim(address addr, uint256 index, uint256 rewards);

  function setSticker(address sticker) external;

  function setRewards(address token, uint256 tokenRewardsRatio) external;

  function setTreasury(address treasury) external;

  function setVestingBlocks(uint256 vestingBlocks_) external;

  function pause() external;

  function unpause() external;

  function bond(address token, uint256 amount) external returns (uint256 bondId);

  function bondsCount(address token) external returns (uint256 bondNb);

  function claim() external returns (uint256 claimed);

  function claimBond(uint256 index) external returns (uint256 claimed);

  function withdraw(address token, uint256 amount) external;

  function rewardsOf(address addr)
    external
    view
    returns (
      uint256 rewards,
      uint256 rewardsClaimed,
      uint256 rewardsClaimable
    );

  function rewardsBondOf(address addr, uint256 index)
    external
    view
    returns (
      uint256 rewards,
      uint256 rewardsClaimed,
      uint256 rewardsClaimable
    );
}
