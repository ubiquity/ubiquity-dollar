// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ILiquityStabilityPool} from "../../interfaces/ILiquityStabilityPool.sol";
import {ILQTY} from "../../interfaces/ILQTY.sol";
import {LibAppStorage} from "./LibAppStorage.sol";

/// @notice Storage struct for Stability Pool integration
struct StabilityPoolStorage {
    /// @notice Address of the Liquity V1 Stability Pool contract
    address stabilityPool;
    /// @notice Address of the LUSD token
    address lusdToken;
    /// @notice Address of the LQTY token
    address lqtyToken;
    /// @notice Whether auto-deposit on mint is enabled
    bool autoDepositEnabled;
    /// @notice Total LUSD deposited into the Stability Pool by this protocol
    uint256 totalDeposited;
    /// @notice Accumulated ETH gains claimed from the Stability Pool
    uint256 accumulatedEthGains;
    /// @notice Accumulated LQTY rewards claimed from the Stability Pool
    uint256 accumulatedLqtyRewards;
}

/// @notice Library for Stability Pool storage and operations
library LibStabilityPool {
    /// @notice Storage slot for StabilityPoolStorage
    bytes32 constant STABILITY_POOL_STORAGE_POSITION = keccak256("ubiquity.stability.pool.storage");

    /// @notice Returns the StabilityPoolStorage struct
    function spStorage() internal pure returns (StabilityPoolStorage storage ss) {
        bytes32 position = STABILITY_POOL_STORAGE_POSITION;
        assembly {
            ss.slot := position
        }
    }

    /// @notice Emitted when LUSD is deposited to the Stability Pool
    event StabilityPoolDeposited(uint256 amount);
    /// @notice Emitted when LUSD is withdrawn from the Stability Pool
    event StabilityPoolWithdrawn(uint256 amount);
    /// @notice Emitted when ETH gains are claimed
    event StabilityPoolEthGainsClaimed(uint256 ethAmount);
    /// @notice Emitted when LQTY rewards are claimed
    event StabilityPoolLqtyRewardsClaimed(uint256 lqtyAmount);
    /// @notice Emitted when auto-deposit setting changes
    event AutoDepositToggled(bool enabled);

    /// @notice Deposits LUSD to the Liquity Stability Pool
    /// @param amount Amount of LUSD to deposit
    function deposit(uint256 amount) internal {
        if (amount == 0) return;
        StabilityPoolStorage storage ss = spStorage();
        require(ss.stabilityPool != address(0), "StabilityPool not set");

        IERC20 lusd = IERC20(ss.lusdToken);
        ILiquityStabilityPool sp = ILiquityStabilityPool(ss.stabilityPool);

        lusd.approve(ss.stabilityPool, amount);
        sp.provideToSP(amount);

        ss.totalDeposited += amount;

        emit StabilityPoolDeposited(amount);
    }

    /// @notice Withdraws LUSD from the Liquity Stability Pool
    /// @param amount Amount of LUSD to withdraw
    function withdraw(uint256 amount) internal {
        if (amount == 0) return;
        StabilityPoolStorage storage ss = spStorage();
        require(ss.stabilityPool != address(0), "StabilityPool not set");

        ILiquityStabilityPool sp = ILiquityStabilityPool(ss.stabilityPool);

        uint256 actualAmount = amount;
        uint256 compounded = sp.getCompoundedLUSDDeposit(address(this));
        if (actualAmount > compounded) {
            actualAmount = compounded;
        }

        sp.withdrawFromSP(actualAmount);

        ss.totalDeposited = ss.totalDeposited > actualAmount ? ss.totalDeposited - actualAmount : 0;

        emit StabilityPoolWithdrawn(actualAmount);
    }

    /// @notice Claims ETH gains and LQTY rewards from the Stability Pool
    function claimRewards() internal {
        StabilityPoolStorage storage ss = spStorage();
        require(ss.stabilityPool != address(0), "StabilityPool not set");

        ILiquityStabilityPool sp = ILiquityStabilityPool(ss.stabilityPool);

        uint256 ethGain = sp.getDepositorETHGain(address(this));
        uint256 lqtyGain = sp.getDepositorLQTYGain(address(this));

        // Withdraw 0 to trigger reward claim
        if (ethGain > 0 || lqtyGain > 0) {
            sp.withdrawFromSP(0);

            if (ethGain > 0) {
                ss.accumulatedEthGains += ethGain;
                emit StabilityPoolEthGainsClaimed(ethGain);
            }
            if (lqtyGain > 0) {
                ss.accumulatedLqtyRewards += lqtyGain;
                emit StabilityPoolLqtyRewardsClaimed(lqtyGain);
            }
        }
    }

    /// @notice Withdraws all LUSD from the Stability Pool
    function withdrawAll() internal {
        StabilityPoolStorage storage ss = spStorage();
        require(ss.stabilityPool != address(0), "StabilityPool not set");

        ILiquityStabilityPool sp = ILiquityStabilityPool(ss.stabilityPool);
        uint256 compounded = sp.getCompoundedLUSDDeposit(address(this));

        if (compounded > 0) {
            sp.withdrawFromSP();
            ss.totalDeposited = 0;

            emit StabilityPoolWithdrawn(compounded);
        }
    }
}
