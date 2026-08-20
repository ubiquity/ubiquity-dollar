// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IStabilityPool} from "../interfaces/IStabilityPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library LibStabilityPool {
    using SafeERC20 for IERC20;

    bytes32 constant STABILITY_POOL_STORAGE_POSITION =
        keccak256("ubiquity.contracts.stability.pool.storage");

    struct StabilityPoolStorage {
        address stabilityPoolAddress;
        address lusdTokenAddress;
        address lqtyTokenAddress;
        address treasuryAddress;
        uint256 totalPrincipalDeposited;
        uint256 harvestThreshold;
        bool isAutoYieldEnabled;
    }

    event StabilityPoolDeposit(uint256 amount, uint256 totalPrincipal);
    event StabilityPoolWithdraw(uint256 amount, uint256 remainingPrincipal);
    event StabilityPoolHarvest(uint256 ethGain, uint256 lqtyGain);

    function stabilityPoolStorage() internal pure returns (StabilityPoolStorage storage ds) {
        bytes32 position = STABILITY_POOL_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function init(
        address _stabilityPool,
        address _lusd,
        address _lqty,
        address _treasury
    ) internal {
        StabilityPoolStorage storage s = stabilityPoolStorage();
        s.stabilityPoolAddress = _stabilityPool;
        s.lusdTokenAddress = _lusd;
        s.lqtyTokenAddress = _lqty;
        s.treasuryAddress = _treasury;
        s.harvestThreshold = 1e18; // 1 token threshold
        s.isAutoYieldEnabled = true;
    }

    function deposit(uint256 _amount) internal {
        if (_amount == 0) return;
        StabilityPoolStorage storage s = stabilityPoolStorage();
        if (!s.isAutoYieldEnabled || s.stabilityPoolAddress == address(0)) return;

        IERC20(s.lusdTokenAddress).safeApprove(s.stabilityPoolAddress, _amount);
        IStabilityPool(s.stabilityPoolAddress).provideToSP(_amount, address(0));

        s.totalPrincipalDeposited += _amount;
        emit StabilityPoolDeposit(_amount, s.totalPrincipalDeposited);
    }

    function withdraw(uint256 _amount) internal returns (uint256 actualAmount) {
        if (_amount == 0) return 0;
        StabilityPoolStorage storage s = stabilityPoolStorage();
        if (s.stabilityPoolAddress == address(0)) return 0;

        uint256 currentDeposit = IStabilityPool(s.stabilityPoolAddress).getCompoundedLUSDDeposit(address(this));
        actualAmount = _amount > currentDeposit ? currentDeposit : _amount;

        if (actualAmount > 0) {
            IStabilityPool(s.stabilityPoolAddress).withdrawFromSP(actualAmount);
            if (s.totalPrincipalDeposited >= actualAmount) {
                s.totalPrincipalDeposited -= actualAmount;
            } else {
                s.totalPrincipalDeposited = 0;
            }
            emit StabilityPoolWithdraw(actualAmount, s.totalPrincipalDeposited);
        }
    }

    function harvest() internal {
        StabilityPoolStorage storage s = stabilityPoolStorage();
        if (s.stabilityPoolAddress == address(0)) return;

        uint256 ethGain = IStabilityPool(s.stabilityPoolAddress).getDepositorETHGain(address(this));
        uint256 lqtyGain = IStabilityPool(s.stabilityPoolAddress).getDepositorLQTYGain(address(this));

        if (ethGain > 0 || lqtyGain > 0) {
            // Withdraw 0 to trigger reward distribution in Liquity V1
            IStabilityPool(s.stabilityPoolAddress).withdrawFromSP(0);
            
            if (ethGain > 0 && s.treasuryAddress != address(0)) {
                (bool success, ) = s.treasuryAddress.call{value: ethGain}("");
                require(success, "ETH transfer failed");
            }

            if (lqtyGain > 0 && s.treasuryAddress != address(0) && s.lqtyTokenAddress != address(0)) {
                IERC20(s.lqtyTokenAddress).safeTransfer(s.treasuryAddress, lqtyGain);
            }

            emit StabilityPoolHarvest(ethGain, lqtyGain);
        }
    }
}
