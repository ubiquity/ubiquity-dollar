// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../dollar/interfaces/IERC20Ubiquity.sol";
import "../../dollar/interfaces/ITWAPOracleDollar3pool.sol";
import "../../dollar/interfaces/IUbiquityFormulas.sol";
import "../../dollar/interfaces/IERC1155Ubiquity.sol";
import "./LibAppStorage.sol";
import {LibTWAPOracle} from "./LibTWAPOracle.sol";
import {LibStakingFormulas} from "./LibStakingFormulas.sol";

/**
 * @notice Library for staking Dollar-3CRV LP tokens for Governance tokens reward
 */
library LibChef {
    using SafeERC20 for IERC20Ubiquity;
    using SafeERC20 for IERC20;

    /// @notice User's staking share info
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

    /// @notice Pool info
    struct PoolInfo {
        uint256 lastRewardBlock; // Last block number that Governance Token distribution occurs.
        uint256 accGovernancePerShare; // Accumulated Governance Tokens per share, times 1e12. See below.
    }

    /// @notice Struct used as a storage for the current library
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

    /// @notice Storage slot used to store data for this library
    bytes32 constant UBIQUITY_CHEF_STORAGE_POSITION =
        bytes32(
            uint256(keccak256("diamond.standard.ubiquity.chef.storage")) - 1
        );

    /**
     * @notice Returns struct used as a storage for this library
     * @return ds Struct used as a storage
     */
    function chefStorage() internal pure returns (ChefStorage storage ds) {
        bytes32 position = UBIQUITY_CHEF_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice Emitted when Dollar-3CRV LP tokens are deposited to the contract
    event Deposit(
        address indexed user,
        uint256 amount,
        uint256 indexed stakingShareId
    );

    /// @notice Emitted when Dollar-3CRV LP tokens are withdrawn from the contract
    event Withdraw(
        address indexed user,
        uint256 amount,
        uint256 indexed stakingShareId
    );

    /// @notice Emitted when amount of Governance tokens minted per block is updated
    event GovernancePerBlockModified(uint256 indexed governancePerBlock);

    /// @notice Emitted when min Dollar price diff for governance multiplier change is updated
    event MinPriceDiffToUpdateMultiplierModified(
        uint256 indexed minPriceDiffToUpdateMultiplier
    );

    /**
     * @notice Initializes staking
     * @param _tos Array of addresses for initial deposits
     * @param _amounts Array of LP amounts for initial deposits
     * @param _stakingShareIDs Array of staking share IDs for initial deposits
     * @param _governancePerBlock Amount of Governance tokens minted each block
     */
    function initialize(
        address[] memory _tos,
        uint256[] memory _amounts,
        uint256[] memory _stakingShareIDs,
        uint256 _governancePerBlock
    ) internal {
        ChefStorage storage cs = chefStorage();
        cs.pool.lastRewardBlock = block.number;
        cs.pool.accGovernancePerShare = 0; // uint256(1e12);
        cs.governanceDivider = 5; // 100 / 5 = 20% extra minted Governance Tokens for treasury
        cs.minPriceDiffToUpdateMultiplier = 1e15;
        cs.lastPrice = 1e18;
        cs.governanceMultiplier = 1e18;
        cs.governancePerBlock = _governancePerBlock;
        uint256 lgt = _tos.length;
        require(lgt == _amounts.length, "_amounts array not same length");
        require(
            lgt == _stakingShareIDs.length,
            "_stakingShareIDs array not same length"
        );

        for (uint256 i = 0; i < lgt; ++i) {
            deposit(_tos[i], _amounts[i], _stakingShareIDs[i]);
        }
    }

    /**
     * @notice Sets amount of Governance tokens minted each block
     * @param _governancePerBlock Amount of Governance tokens minted each block
     */
    function setGovernancePerBlock(uint256 _governancePerBlock) internal {
        chefStorage().governancePerBlock = _governancePerBlock;
        emit GovernancePerBlockModified(_governancePerBlock);
    }

    /**
     * @notice Returns amount of Governance tokens minted each block
     * @return Amount of Governance tokens minted each block
     */
    function governancePerBlock() internal view returns (uint256) {
        return chefStorage().governancePerBlock;
    }

    /**
     * @notice Returns governance divider param
     * @notice Example: if `_governanceDivider = 5` then `100 / 5 = 20%` extra minted Governance tokens for treasury
     * @return Governance divider param value
     */
    function governanceDivider() internal view returns (uint256) {
        return chefStorage().governanceDivider;
    }

    /**
     * @notice Returns pool info
     * @return Pool info:
     * - last block number when Governance tokens distribution occurred
     * - Governance tokens per share, times 1e12
     */
    function pool() internal view returns (PoolInfo memory) {
        return chefStorage().pool;
    }

    /**
     * @notice Returns min price difference between the old and the new Dollar prices
     * required to update the governance multiplier
     * @return Min Dollar price diff to update the governance multiplier
     */
    function minPriceDiffToUpdateMultiplier() internal view returns (uint256) {
        return chefStorage().minPriceDiffToUpdateMultiplier;
    }

    /**
     * @notice Sets Governance token divider param. The bigger `_governanceDivider` the less extra
     * Governance tokens will be minted for the treasury.
     * @notice Example: if `_governanceDivider = 5` then `100 / 5 = 20%` extra minted Governance tokens for treasury
     * @param _governanceDivider Governance divider param value
     */
    function setGovernanceShareForTreasury(
        uint256 _governanceDivider
    ) internal {
        chefStorage().governanceDivider = _governanceDivider;
    }

    /**
     * @notice Sets min price difference between the old and the new Dollar prices
     * @param _minPriceDiffToUpdateMultiplier Min price diff to update governance multiplier
     */
    function setMinPriceDiffToUpdateMultiplier(
        uint256 _minPriceDiffToUpdateMultiplier
    ) internal {
        chefStorage()
            .minPriceDiffToUpdateMultiplier = _minPriceDiffToUpdateMultiplier;
        emit MinPriceDiffToUpdateMultiplierModified(
            _minPriceDiffToUpdateMultiplier
        );
    }

    /**
     * @notice Withdraws Dollar-3CRV LP tokens from staking
     * @param to Address where to transfer pending Governance token rewards
     * @param _amount Amount of LP tokens to withdraw
     * @param _stakingShareID Staking share id
     */
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

    /**
     * @notice Withdraws pending Governance token rewards
     * @param stakingShareID Staking share id
     * @return Reward amount transferred to `msg.sender`
     */
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

    /**
     * @notice Returns staking share info
     * @param _id Staking share id
     * @return Array of amount of shares and reward debt
     */
    function getStakingShareInfo(
        uint256 _id
    ) internal view returns (uint256[2] memory) {
        StakingShareInfo memory ss = chefStorage().ssInfo[_id];
        return [ss.amount, ss.rewardDebt];
    }

    /**
     * @notice Total amount of Dollar-3CRV LP tokens deposited to the Staking contract
     * @return Total amount of deposited LP tokens
     */
    function totalShares() internal view returns (uint256) {
        return chefStorage().totalShares;
    }

    /**
     * @notice Returns amount of pending reward Governance tokens
     * @param stakingShareID Staking share id
     * @return Amount of pending reward Governance tokens
     */
    function pendingGovernance(
        uint256 stakingShareID
    ) internal view returns (uint256) {
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

    /**
     * @notice Deposits Dollar-3CRV LP tokens to staking for Governance tokens allocation
     * @param to Address where to transfer pending Governance token rewards
     * @param _amount Amount of LP tokens to deposit
     * @param _stakingShareID Staking share id
     */
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

    /**
     * @notice Updates Governance token multiplier if Dollar price diff > `minPriceDiffToUpdateMultiplier`
     */
    function _updateGovernanceMultiplier() internal {
        ChefStorage storage cs = chefStorage();
        // (1.05/(1+abs(1-TWAP_PRICE)))
        uint256 currentPrice = LibTWAPOracle.getTwapPrice();
        bool isPriceDiffEnough = false;
        // a minimum price variation is needed to update the multiplier
        if (currentPrice > cs.lastPrice) {
            isPriceDiffEnough =
                currentPrice - cs.lastPrice > cs.minPriceDiffToUpdateMultiplier;
        } else {
            isPriceDiffEnough =
                cs.lastPrice - currentPrice > cs.minPriceDiffToUpdateMultiplier;
        }
        if (isPriceDiffEnough) {
            cs.governanceMultiplier = LibStakingFormulas.governanceMultiply(
                cs.governanceMultiplier,
                currentPrice
            );
            cs.lastPrice = currentPrice;
        }
    }

    /**
     * @notice Updates reward variables of the given pool to be up-to-date
     */
    function _updatePool() internal {
        ChefStorage storage cs = chefStorage();
        PoolInfo storage _pool = cs.pool;
        if (block.number <= _pool.lastRewardBlock) {
            return;
        }
        _updateGovernanceMultiplier();

        if (cs.totalShares == 0) {
            _pool.lastRewardBlock = block.number;
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
        _pool.accGovernancePerShare =
            _pool.accGovernancePerShare +
            ((governanceReward * 1e12) / cs.totalShares);
        _pool.lastRewardBlock = block.number;
    }

    /**
     * @notice Safe Governance Token transfer function, just in case if rounding
     * error causes pool not to have enough Governance tokens
     * @param _to Address where to transfer Governance tokens
     * @param _amount Amount of Governance tokens to transfer
     */
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

    /**
     * @notice Returns Governance token bonus multiplier based on number of passed blocks
     * @return Governance token bonus multiplier
     */
    function _getMultiplier() internal view returns (uint256) {
        uint256 lastRewardBlock = chefStorage().pool.lastRewardBlock;
        uint256 governanceMultiplier = chefStorage().governanceMultiplier;
        return (block.number - lastRewardBlock) * governanceMultiplier;
    }

    /**
     * @notice Returns governance multiplier
     * @return Governance multiplier
     */
    function _getGovernanceMultiplier() internal view returns (uint256) {
        return chefStorage().governanceMultiplier;
    }
}
