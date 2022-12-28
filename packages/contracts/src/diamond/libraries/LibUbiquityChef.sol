// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../dollar/interfaces/IERC20Ubiquity.sol";
import "../../dollar/interfaces/ITWAPOracleDollar3pool.sol";
import "../../dollar/StakingShare.sol";
import "../../dollar/interfaces/IUbiquityFormulas.sol";
import "../../dollar/interfaces/IERC1155Ubiquity.sol";
import "./LibAppStorage.sol";
import {LibTWAPOracle} from "./LibTWAPOracle.sol";
import {LibStakingFormulas} from "./LibStakingFormulas.sol";
import "forge-std/console.sol";

library LibUbiquityChef {
    using SafeERC20 for IERC20Ubiquity;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct StakingShareInfo {
        uint256 amount; // staking rights.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of Governance Tokens
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accGovernancePerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accGovernancePerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.

    struct PoolInfo {
        uint256 lastRewardBlock; // Last block number that Governance Token distribution occurs.
        uint256 accGovernancePerShare; // Accumulated Governance Tokens per share, times 1e12. See below.
    }

    struct ChefStorage {
        // Governance Tokens created per block.
        uint256 governancePerBlock;
        // Bonus multiplier for early Governance Token makers.
        uint256 governanceMultiplier;
        uint256 minPriceDiffToUpdateMultiplier;
        uint256 lastPrice;
        uint256 governanceDivider;
        // Info of each pool.
        PoolInfo pool;
        // Info of each user that stakes LP tokens.
        mapping(uint256 => StakingShareInfo) ssInfo;
        uint256 totalShares;
    }

    bytes32 public constant UBIQUITY_CHEF_STORAGE_POSITION =
        keccak256("diamond.standard.ubiquity.chef.storage");

    function chefStorage() internal pure returns (ChefStorage storage ds) {
        bytes32 position = UBIQUITY_CHEF_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event Deposit(
        address indexed user,
        uint256 amount,
        uint256 indexed stakingShareId
    );

    event Withdraw(
        address indexed user,
        uint256 amount,
        uint256 indexed stakingShareId
    );

    event GovernancePerBlockModified(uint256 indexed governancePerBlock);

    event MinPriceDiffToUpdateMultiplierModified(
        uint256 indexed minPriceDiffToUpdateMultiplier
    );

    function initialize(
        address[] memory _tos,
        uint256[] memory _amounts,
        uint256[] memory _stakingShareIDs
    ) internal {
        ChefStorage storage cs = chefStorage();
        cs.pool.lastRewardBlock = block.number;
        cs.pool.accGovernancePerShare = 0; // uint256(1e12);
        cs.governanceDivider = 5; // 100 / 5 = 20% extra minted Governance Tokens for treasury
        cs.minPriceDiffToUpdateMultiplier = 1e15;
        cs.lastPrice = 1e18;
        console.log("initialize 1");
        _updateGovernanceMultiplier();

        uint256 lgt = _tos.length;
        console.log("initialize 2 lgt:%s", lgt);
        require(lgt == _amounts.length, "_amounts array not same length");
        require(
            lgt == _stakingShareIDs.length,
            "_stakingShareIDs array not same length"
        );

        for (uint256 i = 0; i < lgt; ++i) {
            deposit(_tos[i], _amounts[i], _stakingShareIDs[i]);
        }
    }

    function setGovernancePerBlock(uint256 _governancePerBlock) internal {
        chefStorage().governancePerBlock = _governancePerBlock;
        emit GovernancePerBlockModified(_governancePerBlock);
    }

    // the bigger governanceDivider is the less extra Governance Tokens will be minted for the treasury
    function setGovernanceShareForTreasury(uint256 _governanceDivider)
        internal
    {
        chefStorage().governanceDivider = _governanceDivider;
    }

    function setMinPriceDiffToUpdateMultiplier(
        uint256 _minPriceDiffToUpdateMultiplier
    ) internal {
        chefStorage()
            .minPriceDiffToUpdateMultiplier = _minPriceDiffToUpdateMultiplier;
        emit MinPriceDiffToUpdateMultiplierModified(
            _minPriceDiffToUpdateMultiplier
        );
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(
        address to,
        uint256 _amount,
        uint256 _stakingShareID
    ) internal {
        ChefStorage storage cs = chefStorage();
        StakingShareInfo storage ss = cs.ssInfo[_stakingShareID];
        require(ss.amount >= _amount, "MC: amount too high");
        _updatePool();
        uint256 pending = ((ss.amount * cs.pool.accGovernancePerShare) / 1e12) -
            ss.rewardDebt;
        // send Governance Tokens to Staking Share holder

        _safeGovernanceTransfer(to, pending);
        ss.amount -= _amount;
        ss.rewardDebt = (ss.amount * cs.pool.accGovernancePerShare) / 1e12;
        cs.totalShares -= _amount;
        emit Withdraw(to, _amount, _stakingShareID);
    }

    /// @dev get pending Governance Token rewards from MasterChef.
    /// @return amount of pending rewards transferred to msg.sender
    /// @notice only send pending rewards
    function getRewards(uint256 stakingShareID) internal returns (uint256) {
        require(
            IERC1155Ubiquity(LibAppStorage.appStorage().stakingShareAddress)
                .balanceOf(msg.sender, stakingShareID) == 1,
            "MS: caller is not owner"
        );

        // calculate user reward
        ChefStorage storage cs = chefStorage();
        StakingShareInfo storage user = cs.ssInfo[stakingShareID];
        _updatePool();
        uint256 pending = ((user.amount * cs.pool.accGovernancePerShare) /
            1e12) - user.rewardDebt;
        _safeGovernanceTransfer(msg.sender, pending);
        user.rewardDebt = (user.amount * cs.pool.accGovernancePerShare) / 1e12;
        return pending;
    }

    function getStakingShareInfo(uint256 _id)
        internal
        view
        returns (uint256[2] memory)
    {
        StakingShareInfo memory ss = chefStorage().ssInfo[_id];
        return [ss.amount, ss.rewardDebt];
    }

    function totalShares() internal view returns (uint256) {
        return chefStorage().totalShares;
    }

    // View function to see pending Governance Tokens on frontend.
    function pendingGovernance(uint256 stakingShareID)
        internal
        view
        returns (uint256)
    {
        ChefStorage storage cs = chefStorage();
        StakingShareInfo storage user = cs.ssInfo[stakingShareID];
        uint256 accGovernancePerShare = cs.pool.accGovernancePerShare;

        if (block.number > cs.pool.lastRewardBlock && cs.totalShares != 0) {
            uint256 multiplier = _getMultiplier();
            uint256 governanceReward = (multiplier * cs.governancePerBlock) /
                1e18;
            accGovernancePerShare =
                accGovernancePerShare +
                ((governanceReward * 1e12) / cs.totalShares);
        }
        return (user.amount * accGovernancePerShare) / 1e12 - user.rewardDebt;
    }

    // _Deposit LP tokens to MasterChef for Governance Token allocation.
    function deposit(
        address to,
        uint256 _amount,
        uint256 _stakingShareID
    ) internal {
        ChefStorage storage cs = chefStorage();
        StakingShareInfo storage ss = cs.ssInfo[_stakingShareID];
        _updatePool();
        if (ss.amount > 0) {
            uint256 pending = ((ss.amount * cs.pool.accGovernancePerShare) /
                1e12) - ss.rewardDebt;
            _safeGovernanceTransfer(to, pending);
        }
        ss.amount += _amount;
        ss.rewardDebt = (ss.amount * cs.pool.accGovernancePerShare) / 1e12;
        chefStorage().totalShares += _amount;
        emit Deposit(to, _amount, _stakingShareID);
    }

    // UPDATE Governance Token multiplier
    function _updateGovernanceMultiplier() internal {
        ChefStorage storage cs = chefStorage();
        // (1.05/(1+abs(1-TWAP_PRICE)))
        uint256 currentPrice = _getTwapPrice();
        console.log(
            "cur price:%s lastPrice:%s minPriceDiffToUpdateMultiplier:%s",
            currentPrice,
            cs.lastPrice,
            cs.minPriceDiffToUpdateMultiplier
        );
        bool isPriceDiffEnough = false;
        // a minimum price variation is needed to update the multiplier
        if (currentPrice > cs.lastPrice) {
            isPriceDiffEnough =
                currentPrice - cs.lastPrice > cs.minPriceDiffToUpdateMultiplier;
        } else {
            isPriceDiffEnough =
                cs.lastPrice - currentPrice > cs.minPriceDiffToUpdateMultiplier;
        }
        console.log("cisPriceDiffEnough:%s", isPriceDiffEnough);
        if (isPriceDiffEnough) {
            cs.governanceMultiplier = LibStakingFormulas.governanceMultiply(
                cs.governanceMultiplier,
                currentPrice
            );
            cs.lastPrice = currentPrice;
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function _updatePool() internal {
        ChefStorage storage cs = chefStorage();
        PoolInfo storage pool = cs.pool;
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        _updateGovernanceMultiplier();

        if (cs.totalShares == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        address governanceTokenAddress = LibAppStorage
            .appStorage()
            .governanceTokenAddress;
        address treasuryAddress = LibAppStorage.appStorage().treasuryAddress;
        uint256 multiplier = _getMultiplier();
        uint256 governanceReward = (multiplier * cs.governancePerBlock) / 1e18;
        IERC20Ubiquity(governanceTokenAddress).mint(
            address(this),
            governanceReward
        );
        // mint another x% for the treasury
        IERC20Ubiquity(governanceTokenAddress).mint(
            treasuryAddress,
            governanceReward / cs.governanceDivider
        );
        pool.accGovernancePerShare =
            pool.accGovernancePerShare +
            ((governanceReward * 1e12) / cs.totalShares);
        pool.lastRewardBlock = block.number;
    }

    // Safe Governance Token transfer function, just in case if rounding
    // error causes pool to not have enough Governance Tokens.
    function _safeGovernanceTransfer(address _to, uint256 _amount) internal {
        IERC20Ubiquity governanceToken = IERC20Ubiquity(
            LibAppStorage.appStorage().governanceTokenAddress
        );
        uint256 governanceBalance = governanceToken.balanceOf(address(this));
        if (_amount > governanceBalance) {
            governanceToken.safeTransfer(_to, governanceBalance);
        } else {
            governanceToken.safeTransfer(_to, _amount);
        }
    }

    function _getMultiplier() internal view returns (uint256) {
        uint256 lastRewardBlock = chefStorage().pool.lastRewardBlock;
        uint256 governanceMultiplier = chefStorage().governanceMultiplier;
        return (block.number - lastRewardBlock) * governanceMultiplier;
    }

    function _getTwapPrice() internal view returns (uint256) {
        return LibTWAPOracle.consult(address(this));
    }
}
