// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISimpleBond.sol";
import "./interfaces/IUAR.sol";

/// @title Simple Bond
/// @author zapaz.eth
/// @notice SimpleBond is a simple Bond mecanism, allowing to sell tokens bonded and get rewards tokens
/// @notice The reward token is fully claimable only after the vesting period
/// @dev Bond is Ownable, access controled by onlyOwner
/// @dev Use SafeERC20
contract SimpleBond is ISimpleBond, Ownable, Pausable {
  using SafeERC20 for IERC20;

  struct Bond {
    address token;
    uint256 amount;
    uint256 rewards;
    uint256 claimed;
    uint256 block;
  }

  /// @notice Rewards token address
  address public immutable tokenRewards;

  /// @notice Rewards ratio for token bonded
  /// @dev rewardsRatio is per billion of token bonded
  mapping(address => uint256) public rewardsRatio;

  /// @notice Vesting period
  /// @dev defined in number of block
  uint256 public vestingBlocks;

  /// @notice Bonds for each address
  /// @dev bond index starts at 0 for each address
  mapping(address => Bond[]) public bonds;

  /// @notice Total rewards
  uint256 public totalRewards;

  /// @notice Total rewards claimed
  uint256 public totalClaimedRewards;

  /// @notice Treasury address
  address public treasury;

  /// NFT stick address
  address public sticker;

  /// @notice onlySticker : no NFT stick address defined OR sender has at least one NFT Stick
  modifier onlySticker() {
    require(sticker == address(0) || IERC721(sticker).balanceOf(msg.sender) > 0, "Not NFT Stick owner");
    _;
  }

  /// @notice Set sticker
  /// @param sticker_ sticker boolean
  function setSticker(address sticker_) public override onlyOwner {
    sticker = sticker_;
  }

  /// Simple Bond constructor
  /// @param tokenRewards_ Rewards token address
  /// @param vestingBlocks_ Vesting duration in blocks
  constructor(
    address tokenRewards_,
    uint256 vestingBlocks_,
    address treasury_
  ) {
    require(tokenRewards_ != address(0), "Invalid Reward token");
    tokenRewards = tokenRewards_;
    setVestingBlocks(vestingBlocks_);
    setTreasury(treasury_);
  }

  /// @notice Set Rewards for specific Token
  /// @param token token address
  /// @param tokenRewardsRatio rewardsRatio for this token
  function setRewards(address token, uint256 tokenRewardsRatio) public override onlyOwner {
    require(token != address(0), "Invalid Reward token");
    rewardsRatio[token] = tokenRewardsRatio;

    emit LogSetRewards(token, tokenRewardsRatio);
  }

  /// @notice Set vesting duration
  /// @param vestingBlocks_ vesting duration in blocks
  function setVestingBlocks(uint256 vestingBlocks_) public override onlyOwner {
    require(vestingBlocks_ > 0, "Invalid Vesting blocks number");
    vestingBlocks = vestingBlocks_;
  }

  /// @notice Set treasury address
  /// @param treasury_ treasury address
  function setTreasury(address treasury_) public override onlyOwner {
    require(treasury_ != address(0), "Invalid Treasury address");
    treasury = treasury_;
  }

  /// @notice Pause Bonding and Claiming
  function pause() public override onlyOwner {
    _pause();
  }

  /// @notice Unpause Bonding and Claiming
  function unpause() public override onlyOwner {
    _unpause();
  }

  /// @notice Bond tokens
  /// @param token bonded token address
  /// @param amount amount of token to bond
  /// @return bondId Bond id
  function bond(address token, uint256 amount) public override whenNotPaused onlySticker returns (uint256 bondId) {
    require(rewardsRatio[token] > 0, "Token not allowed");

    // @dev throws if not enough allowance or tokens for address
    // @dev must set token allowance for this smartcontract previously
    IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

    Bond memory bnd;
    bnd.token = token;
    bnd.amount = amount;
    bnd.block = block.number;

    uint256 rewards = (amount * rewardsRatio[token]) / 1_000_000_000;
    bnd.rewards = rewards;
    totalRewards += rewards;

    bondId = bonds[msg.sender].length;
    bonds[msg.sender].push(bnd);

    emit LogBond(msg.sender, bnd.token, bnd.amount, bnd.rewards, bnd.block, bondId);
  }

  /// @notice Claim all rewards
  /// @return claimed Rewards claimed succesfully
  function claim() public override whenNotPaused returns (uint256 claimed) {
    for (uint256 index = 0; (index < bonds[msg.sender].length); index += 1) {
      claimed += claimBond(index);
    }
  }

  /// @notice Claim bond rewards
  /// @return claimed Rewards claimed succesfully
  function claimBond(uint256 index) public override whenNotPaused returns (uint256 claimed) {
    Bond storage bnd = bonds[msg.sender][index];
    uint256 claimAmount = _bondClaimableRewards(bnd);

    if (claimAmount > 0) {
      bnd.claimed += claimAmount;
      totalClaimedRewards += claimAmount;

      assert(bnd.claimed <= bnd.rewards);
      IUAR(tokenRewards).raiseCapital(claimAmount);
      IERC20(tokenRewards).safeTransferFrom(treasury, msg.sender, claimAmount);
    }

    emit LogClaim(msg.sender, index, claimed);
  }

  /// @notice Withdraw token from the smartcontract, only for owner
  /// @param  token token withdraw
  /// @param amount amount withdraw
  function withdraw(address token, uint256 amount) public override onlyOwner {
    IERC20(token).safeTransfer(treasury, amount);
  }

  /// @notice Bond rewards balance: amount and already claimed
  /// @return rewards Amount of rewards
  /// @return rewardsClaimed Amount of rewards already claimed
  /// @return rewardsClaimable Amount of still claimable rewards
  function rewardsOf(address addr)
    public
    view
    override
    returns (
      uint256 rewards,
      uint256 rewardsClaimed,
      uint256 rewardsClaimable
    )
  {
    for (uint256 index = 0; index < bonds[addr].length; index += 1) {
      (uint256 bondRewards, uint256 bondClaimedRewards, uint256 bondClaimableRewards) = rewardsBondOf(addr, index);
      rewards += bondRewards;
      rewardsClaimed += bondClaimedRewards;
      rewardsClaimable += bondClaimableRewards;
    }
  }

  /// @notice Bond rewards balance: amount and already claimed
  /// @return rewards Amount of rewards
  /// @return rewardsClaimed Amount of rewards already claimed
  /// @return rewardsClaimable Amount of still claimable rewards
  function rewardsBondOf(address addr, uint256 index)
    public
    view
    override
    returns (
      uint256 rewards,
      uint256 rewardsClaimed,
      uint256 rewardsClaimable
    )
  {
    Bond memory bnd = bonds[addr][index];
    rewards = bnd.rewards;
    rewardsClaimed = bnd.claimed;
    rewardsClaimable = _bondClaimableRewards(bnd);
  }

  /// @notice Get number of bonds for address
  /// @return number of bonds
  function bondsCount(address addr) public view override returns (uint256) {
    return bonds[addr].length;
  }

  /// @dev calculate claimable rewards during vesting period, or all claimable rewards after, minus already claimed
  function _bondClaimableRewards(Bond memory bnd) internal view returns (uint256 claimable) {
    assert(block.number >= bnd.block);

    uint256 blocks = block.number - bnd.block;
    uint256 totalClaimable;

    if (blocks < vestingBlocks) {
      totalClaimable = (bnd.rewards * blocks) / vestingBlocks;
    } else {
      totalClaimable = bnd.rewards;
    }

    assert(totalClaimable >= bnd.claimed);
    claimable = totalClaimable - bnd.claimed;
  }
}
