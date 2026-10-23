// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IStabilityPool} from "../interfaces/IStabilityPool.sol";
import {AppStorage, LibAppStorage} from "./LibAppStorage.sol";

/// @notice Library for Stability Pool integration
/// @dev Manages LUSD deposits to Liquity V1 Stability Pool for yield generation
library LibStabilityPool {
    using SafeERC20 for IERC20;

    /// @notice Storage slot for stability pool data
    bytes32 constant STABILITY_POOL_STORAGE_POSITION =
        bytes32(
            uint256(keccak256("ubiquity.contracts.stability.pool.storage")) - 1
        ) & ~bytes32(uint256(0xff));

    /// @notice Storage struct for stability pool state
    struct StabilityPoolStorage {
        /// @notice Address of the Liquity V1 Stability Pool
        address stabilityPool;
        /// @notice Total principal deposited by the protocol
        uint256 totalPrincipalInPool;
        /// @notice Address of the LUSD token
        address lusdToken;
        /// @notice Address of the LQTY token
        address lqtyToken;
        /// @notice Protocol treasury to receive harvested rewards
        address treasury;
        /// @notice Minimum reward amount (in wei) to trigger auto-harvest during withdrawals
        uint256 rewardThreshold;
    }

    // --- Events ---

    event DepositedToPool(address indexed sender, uint256 amount);
    event WithdrawnFromPool(address indexed sender, uint256 amount);
    event RewardsHarvested(
        address indexed sender,
        uint256 ethReward,
        uint256 lqtyReward
    );
    event StabilityPoolAddressSet(address indexed stabilityPool);
    event RewardThresholdSet(uint256 threshold);
    event SpTreasuryAddressSet(address indexed treasury);

    // --- Storage Access ---

    function stabilityPoolStorage()
        internal
        pure
        returns (StabilityPoolStorage storage sps)
    {
        bytes32 position = STABILITY_POOL_STORAGE_POSITION;
        assembly {
            sps.slot := position
        }
    }

    // --- Internal Functions ---

    /// @notice Deposit LUSD to the Stability Pool
    /// @param amount Amount of LUSD to deposit
    function _depositToPool(uint256 amount) internal {
        StabilityPoolStorage storage sps = stabilityPoolStorage();
        require(sps.stabilityPool != address(0), "StabilityPool: not set");
        require(amount > 0, "StabilityPool: zero amount");

        // Transfer LUSD from caller to this contract (diamond)
        IERC20(sps.lusdToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        // Approve Stability Pool to spend LUSD
        IERC20(sps.lusdToken).safeIncreaseAllowance(
            sps.stabilityPool,
            amount
        );

        // Deposit to Stability Pool
        IStabilityPool(sps.stabilityPool).provideToSP(amount, address(0));

        // Update accounting
        sps.totalPrincipalInPool += amount;

        emit DepositedToPool(msg.sender, amount);
    }

    /// @notice Withdraw LUSD principal from the Stability Pool
    /// @param amount Amount of LUSD to withdraw
    function _withdrawFromPool(uint256 amount) internal {
        StabilityPoolStorage storage sps = stabilityPoolStorage();
        require(sps.stabilityPool != address(0), "StabilityPool: not set");
        require(amount > 0, "StabilityPool: zero amount");
        require(
            amount <= sps.totalPrincipalInPool,
            "StabilityPool: exceeds principal"
        );

        // Withdraw from Stability Pool
        IStabilityPool(sps.stabilityPool).withdrawFromSP(amount);

        // Update accounting
        sps.totalPrincipalInPool -= amount;

        // Transfer LUSD back to caller
        IERC20(sps.lusdToken).safeTransfer(msg.sender, amount);

        // Auto-harvest if rewards exceed threshold
        uint256 ethReward = IStabilityPool(sps.stabilityPool)
            .getDepositorETHGain(address(this));
        if (ethReward >= sps.rewardThreshold) {
            _harvestRewards();
        }

        emit WithdrawnFromPool(msg.sender, amount);
    }

    /// @notice Harvest ETH and LQTY rewards from the Stability Pool
    /// @dev Rewards are sent to the protocol treasury
    function _harvestRewards() internal {
        StabilityPoolStorage storage sps = stabilityPoolStorage();
        require(sps.stabilityPool != address(0), "StabilityPool: not set");
        require(sps.treasury != address(0), "StabilityPool: treasury not set");

        // Get pending rewards before claiming
        uint256 ethReward = IStabilityPool(sps.stabilityPool)
            .getDepositorETHGain(address(this));
        uint256 lqtyReward = IStabilityPool(sps.stabilityPool)
            .getDepositorLQTYGain(address(this));

        // Withdraw ETH gain to this contract (diamond)
        // provideToSP(0) triggers reward claims
        if (ethReward > 0 || lqtyReward > 0) {
            IStabilityPool(sps.stabilityPool).provideToSP(0, address(0));
        }

        // Transfer ETH rewards to treasury
        if (ethReward > 0) {
            (bool success, ) = sps.treasury.call{value: ethReward}("");
            require(success, "StabilityPool: ETH transfer failed");
        }

        // Transfer LQTY rewards to treasury
        if (lqtyReward > 0) {
            IERC20(sps.lqtyToken).safeTransfer(sps.treasury, lqtyReward);
        }

        emit RewardsHarvested(msg.sender, ethReward, lqtyReward);
    }

    /// @notice Get the compounded LUSD deposit amount
    function _getDepositedLUSD() internal view returns (uint256) {
        StabilityPoolStorage storage sps = stabilityPoolStorage();
        if (sps.stabilityPool == address(0)) return 0;
        return
            IStabilityPool(sps.stabilityPool).getCompoundedLUSDDeposit(
                address(this)
            );
    }

    /// @notice Get pending ETH reward
    function _getPendingETHReward() internal view returns (uint256) {
        StabilityPoolStorage storage sps = stabilityPoolStorage();
        if (sps.stabilityPool == address(0)) return 0;
        return
            IStabilityPool(sps.stabilityPool).getDepositorETHGain(
                address(this)
            );
    }

    /// @notice Get pending LQTY reward
    function _getPendingLQTYReward() internal view returns (uint256) {
        StabilityPoolStorage storage sps = stabilityPoolStorage();
        if (sps.stabilityPool == address(0)) return 0;
        return
            IStabilityPool(sps.stabilityPool).getDepositorLQTYGain(
                address(this)
            );
    }

    /// @notice Set the Stability Pool address
    function _setStabilityPoolAddress(address _stabilityPool) internal {
        require(_stabilityPool != address(0), "StabilityPool: zero address");
        StabilityPoolStorage storage sps = stabilityPoolStorage();
        sps.stabilityPool = _stabilityPool;
        sps.lusdToken = IStabilityPool(_stabilityPool).LUSD();
        sps.lqtyToken = IStabilityPool(_stabilityPool).lqtyToken();
        emit StabilityPoolAddressSet(_stabilityPool);
    }

    /// @notice Set the reward threshold for auto-harvest
    function _setRewardThreshold(uint256 _threshold) internal {
        StabilityPoolStorage storage sps = stabilityPoolStorage();
        sps.rewardThreshold = _threshold;
        emit RewardThresholdSet(_threshold);
    }

    /// @notice Set the treasury address
    function _setTreasuryAddress(address _treasury) internal {
        require(_treasury != address(0), "StabilityPool: zero address");
        StabilityPoolStorage storage sps = stabilityPoolStorage();
        sps.treasury = _treasury;
        emit SpTreasuryAddressSet(_treasury);
    }
}
