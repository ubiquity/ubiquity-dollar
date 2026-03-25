// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ILiquityStabilityPool} from "../interfaces/ILiquityStabilityPool.sol";

/**
 * @title LibStabilityPool
 * @notice Library for integrating Liquity V1 Stability Pool with the Ubiquity Dollar protocol
 * @notice Deposits LUSD collateral to the Stability Pool for yield generation (~6.28% APR)
 *         and harvests ETH/LQTY rewards for protocol-owned buybacks/compounding
 */
library LibStabilityPool {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /// @notice Storage slot used to store data for this library
    bytes32 constant STABILITY_POOL_STORAGE_POSITION =
        bytes32(
            uint256(
                keccak256("ubiquity.contracts.stability.pool.storage")
            ) - 1
        ) & ~bytes32(uint256(0xff));

    /// @notice Struct used as a storage for this library
    struct StabilityPoolStorage {
        /// @notice Address of the Liquity V1 Stability Pool contract
        address liquidityStabilityPoolAddress;
        /// @notice Address of the LUSD token
        address lusdTokenAddress;
        /// @notice Address of the LQTY token
        address lqtyTokenAddress;
        /// @notice Address of the protocol treasury that receives harvested rewards
        address protocolTreasury;
        /// @notice Total LUSD principal deposited in the Stability Pool
        uint256 totalPrincipalInPool;
        /// @notice Minimum ETH reward threshold (in wei) to trigger harvest during redeems
        uint256 harvestRewardThreshold;
        /// @notice Percentage of rewards to compound back as LUSD (the rest goes to buybacks), 1e6 = 100%
        uint256 compoundingPercentage;
        /// @notice Whether the stability pool integration is active
        bool isActive;
    }

    //===========
    // Events
    //===========

    /// @notice Emitted when LUSD is deposited to the Stability Pool
    event DepositedToStabilityPool(uint256 amount, uint256 newTotalPrincipal);
    /// @notice Emitted when LUSD is withdrawn from the Stability Pool
    event WithdrawnFromStabilityPool(
        uint256 amount,
        uint256 newTotalPrincipal
    );
    /// @notice Emitted when rewards are harvested
    event RewardsHarvested(
        uint256 ethAmount,
        uint256 lqtyAmount,
        address treasury
    );
    /// @notice Emitted when the Stability Pool address is set
    event StabilityPoolAddressSet(address newStabilityPoolAddress);
    /// @notice Emitted when the LUSD token address is set
    event LusdTokenAddressSet(address newLusdTokenAddress);
    /// @notice Emitted when the LQTY token address is set
    event LqtyTokenAddressSet(address newLqtyTokenAddress);
    /// @notice Emitted when the protocol treasury address is set
    event ProtocolTreasurySet(address newProtocolTreasury);
    /// @notice Emitted when the harvest reward threshold is set
    event HarvestRewardThresholdSet(uint256 newThreshold);
    /// @notice Emitted when the compounding percentage is set
    event CompoundingPercentageSet(uint256 newPercentage);
    /// @notice Emitted when the Stability Pool integration is toggled
    event StabilityPoolToggled(bool isActive);

    /**
     * @notice Returns struct used as storage for this library
     * @return spStorage Struct used as storage
     */
    function stabilityPoolStorage()
        internal
        pure
        returns (StabilityPoolStorage storage spStorage)
    {
        bytes32 position = STABILITY_POOL_STORAGE_POSITION;
        assembly {
            spStorage.slot := position
        }
    }

    //=====================
    // Views
    //=====================

    /**
     * @notice Returns the total LUSD principal deposited in the Stability Pool
     * @return Total principal in the pool
     */
    function totalPrincipalInPool() internal view returns (uint256) {
        StabilityPoolStorage storage spStorage = stabilityPoolStorage();
        return spStorage.totalPrincipalInPool;
    }

    /**
     * @notice Returns the current compounded LUSD deposit in the Stability Pool
     * @return Current LUSD balance in the Stability Pool
     */
    function currentLusdInStabilityPool() internal view returns (uint256) {
        StabilityPoolStorage storage spStorage = stabilityPoolStorage();
        if (spStorage.liquidityStabilityPoolAddress == address(0)) return 0;
        return
            ILiquityStabilityPool(spStorage.liquidityStabilityPoolAddress)
                .getCompoundedLUSDDeposit(address(this));
    }

    /**
     * @notice Returns the pending ETH rewards from the Stability Pool
     * @return Pending ETH reward amount
     */
    function pendingEthReward() internal view returns (uint256) {
        StabilityPoolStorage storage spStorage = stabilityPoolStorage();
        if (spStorage.liquidityStabilityPoolAddress == address(0)) return 0;
        return
            ILiquityStabilityPool(spStorage.liquidityStabilityPoolAddress)
                .getDepositorETHGain(address(this));
    }

    /**
     * @notice Returns the pending LQTY rewards from the Stability Pool
     * @return Pending LQTY reward amount
     */
    function pendingLqtyReward() internal view returns (uint256) {
        StabilityPoolStorage storage spStorage = stabilityPoolStorage();
        if (spStorage.liquidityStabilityPoolAddress == address(0)) return 0;
        return
            ILiquityStabilityPool(spStorage.liquidityStabilityPoolAddress)
                .getDepositorLQTYGain(address(this));
    }

    /**
     * @notice Returns whether the Stability Pool integration is active
     * @return True if active
     */
    function isActive() internal view returns (bool) {
        StabilityPoolStorage storage spStorage = stabilityPoolStorage();
        return spStorage.isActive;
    }

    /**
     * @notice Returns the harvest reward threshold
     * @return Threshold in wei
     */
    function harvestRewardThreshold() internal view returns (uint256) {
        StabilityPoolStorage storage spStorage = stabilityPoolStorage();
        return spStorage.harvestRewardThreshold;
    }

    /**
     * @notice Returns the compounding percentage
     * @return Percentage with 1e6 = 100%
     */
    function compoundingPercentage() internal view returns (uint256) {
        StabilityPoolStorage storage spStorage = stabilityPoolStorage();
        return spStorage.compoundingPercentage;
    }

    /**
     * @notice Returns the protocol treasury address
     * @return Treasury address
     */
    function protocolTreasury() internal view returns (address) {
        StabilityPoolStorage storage spStorage = stabilityPoolStorage();
        return spStorage.protocolTreasury;
    }

    //====================
    // Public functions
    //====================

    /**
     * @notice Deposits LUSD into the Liquity Stability Pool
     * @param amount Amount of LUSD to deposit
     */
    function depositToPool(uint256 amount) internal {
        StabilityPoolStorage storage spStorage = stabilityPoolStorage();
        require(spStorage.isActive, "StabilityPool: not active");
        require(amount > 0, "StabilityPool: zero amount");
        require(
            spStorage.liquidityStabilityPoolAddress != address(0),
            "StabilityPool: pool not set"
        );
        require(
            spStorage.lusdTokenAddress != address(0),
            "StabilityPool: LUSD not set"
        );

        // Approve LUSD spend by Stability Pool
        IERC20(spStorage.lusdTokenAddress).safeApprove(
            spStorage.liquidityStabilityPoolAddress,
            amount
        );

        // Deposit LUSD to Stability Pool (using address(0) as frontend tag)
        ILiquityStabilityPool(spStorage.liquidityStabilityPoolAddress)
            .provideToSP(amount, address(0));

        // Update principal tracker
        spStorage.totalPrincipalInPool = spStorage.totalPrincipalInPool.add(
            amount
        );

        emit DepositedToStabilityPool(amount, spStorage.totalPrincipalInPool);
    }

    /**
     * @notice Withdraws LUSD principal from the Liquity Stability Pool
     * @param amount Amount of LUSD to withdraw
     */
    function withdrawFromPool(uint256 amount) internal {
        StabilityPoolStorage storage spStorage = stabilityPoolStorage();
        require(amount > 0, "StabilityPool: zero amount");
        require(
            spStorage.liquidityStabilityPoolAddress != address(0),
            "StabilityPool: pool not set"
        );
        require(
            amount <= spStorage.totalPrincipalInPool,
            "StabilityPool: exceeds principal"
        );

        // Withdraw LUSD from Stability Pool (also claims pending ETH/LQTY)
        ILiquityStabilityPool(spStorage.liquidityStabilityPoolAddress)
            .withdrawFromSP(amount);

        // Update principal tracker
        spStorage.totalPrincipalInPool = spStorage.totalPrincipalInPool.sub(
            amount
        );

        emit WithdrawnFromStabilityPool(
            amount,
            spStorage.totalPrincipalInPool
        );
    }

    /**
     * @notice Harvests ETH and LQTY rewards from the Stability Pool and sends to treasury
     * @dev Calls withdrawFromSP(0) to claim rewards without withdrawing principal.
     *      Uses balance-based accounting: records ETH and LQTY balances before/after
     *      the withdrawal call to determine actual reward amounts received.
     *      Routes rewards to the protocol treasury for buybacks/compounding.
     * @dev NOTE: The Diamond proxy must have a receive() function to accept ETH
     *      from the Liquity Stability Pool. Ensure this is added before deployment.
     */
    function harvestRewards() internal {
        StabilityPoolStorage storage spStorage = stabilityPoolStorage();
        require(
            spStorage.liquidityStabilityPoolAddress != address(0),
            "StabilityPool: pool not set"
        );
        require(
            spStorage.protocolTreasury != address(0),
            "StabilityPool: treasury not set"
        );

        // Record balances before claiming
        uint256 ethBalanceBefore = address(this).balance;
        uint256 lqtyBalanceBefore = spStorage.lqtyTokenAddress != address(0)
            ? IERC20(spStorage.lqtyTokenAddress).balanceOf(address(this))
            : 0;

        // Claim rewards by withdrawing 0 LUSD
        ILiquityStabilityPool(spStorage.liquidityStabilityPoolAddress)
            .withdrawFromSP(0);

        // Calculate actual rewards received via balance difference
        uint256 ethReward = address(this).balance - ethBalanceBefore;
        uint256 lqtyReward = 0;
        if (spStorage.lqtyTokenAddress != address(0)) {
            lqtyReward =
                IERC20(spStorage.lqtyTokenAddress).balanceOf(address(this)) -
                lqtyBalanceBefore;
        }

        // Transfer ETH rewards to treasury
        if (ethReward > 0) {
            (bool success, ) = spStorage.protocolTreasury.call{
                value: ethReward
            }("");
            require(success, "StabilityPool: ETH transfer failed");
        }

        // Transfer LQTY rewards to treasury
        if (lqtyReward > 0) {
            IERC20(spStorage.lqtyTokenAddress).safeTransfer(
                spStorage.protocolTreasury,
                lqtyReward
            );
        }

        emit RewardsHarvested(
            ethReward,
            lqtyReward,
            spStorage.protocolTreasury
        );
    }

    //========================
    // Admin functions
    //========================

    /**
     * @notice Sets the Liquity Stability Pool address
     * @param newStabilityPoolAddress New Stability Pool address
     */
    function setStabilityPoolAddress(
        address newStabilityPoolAddress
    ) internal {
        require(
            newStabilityPoolAddress != address(0),
            "StabilityPool: zero address"
        );
        StabilityPoolStorage storage spStorage = stabilityPoolStorage();
        spStorage.liquidityStabilityPoolAddress = newStabilityPoolAddress;
        emit StabilityPoolAddressSet(newStabilityPoolAddress);
    }

    /**
     * @notice Sets the LUSD token address
     * @param newLusdTokenAddress New LUSD token address
     */
    function setLusdTokenAddress(address newLusdTokenAddress) internal {
        require(
            newLusdTokenAddress != address(0),
            "StabilityPool: zero address"
        );
        StabilityPoolStorage storage spStorage = stabilityPoolStorage();
        spStorage.lusdTokenAddress = newLusdTokenAddress;
        emit LusdTokenAddressSet(newLusdTokenAddress);
    }

    /**
     * @notice Sets the LQTY token address
     * @param newLqtyTokenAddress New LQTY token address
     */
    function setLqtyTokenAddress(address newLqtyTokenAddress) internal {
        require(
            newLqtyTokenAddress != address(0),
            "StabilityPool: zero address"
        );
        StabilityPoolStorage storage spStorage = stabilityPoolStorage();
        spStorage.lqtyTokenAddress = newLqtyTokenAddress;
        emit LqtyTokenAddressSet(newLqtyTokenAddress);
    }

    /**
     * @notice Sets the protocol treasury address
     * @param newProtocolTreasury New treasury address
     */
    function setProtocolTreasury(address newProtocolTreasury) internal {
        require(
            newProtocolTreasury != address(0),
            "StabilityPool: zero address"
        );
        StabilityPoolStorage storage spStorage = stabilityPoolStorage();
        spStorage.protocolTreasury = newProtocolTreasury;
        emit ProtocolTreasurySet(newProtocolTreasury);
    }

    /**
     * @notice Sets the minimum ETH reward threshold for triggering harvests
     * @param newThreshold New threshold in wei
     */
    function setHarvestRewardThreshold(uint256 newThreshold) internal {
        StabilityPoolStorage storage spStorage = stabilityPoolStorage();
        spStorage.harvestRewardThreshold = newThreshold;
        emit HarvestRewardThresholdSet(newThreshold);
    }

    /**
     * @notice Sets the compounding percentage for reward distribution
     * @param newPercentage New percentage (1e6 = 100%)
     */
    function setCompoundingPercentage(uint256 newPercentage) internal {
        require(
            newPercentage <= 1e6,
            "StabilityPool: percentage exceeds 100%"
        );
        StabilityPoolStorage storage spStorage = stabilityPoolStorage();
        spStorage.compoundingPercentage = newPercentage;
        emit CompoundingPercentageSet(newPercentage);
    }

    /**
     * @notice Toggles the Stability Pool integration on/off
     */
    function toggleStabilityPool() internal {
        StabilityPoolStorage storage spStorage = stabilityPoolStorage();
        spStorage.isActive = !spStorage.isActive;
        emit StabilityPoolToggled(spStorage.isActive);
    }
}
