// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Modifiers} from "../libraries/LibAppStorage.sol";
import {LibStabilityPool, StabilityPoolStorage} from "../libraries/LibStabilityPool.sol";
import {ILiquityStabilityPool} from "../interfaces/ILiquityStabilityPool.sol";
import {ILQTY} from "../interfaces/ILQTY.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IStabilityPoolFacet
/// @notice Interface for the Stability Pool facet
interface IStabilityPoolFacet {
    // Views
    function stabilityPoolAddress() external view returns (address);
    function lusdTokenAddress() external view returns (address);
    function lqtyTokenAddress() external view returns (address);
    function isAutoDepositEnabled() external view returns (bool);
    function totalDeposited() external view returns (uint256);
    function accumulatedEthGains() external view returns (uint256);
    function accumulatedLqtyRewards() external view returns (uint256);
    function compoundedLusdDeposit() external view returns (uint256);
    function pendingEthGain() external view returns (uint256);
    function pendingLqtyGain() external view returns (uint256);

    // Actions
    function depositToStabilityPool(uint256 amount) external;
    function withdrawFromStabilityPool(uint256 amount) external;
    function withdrawAllFromStabilityPool() external;
    function claimStabilityPoolRewards() external;
    function depositAndClaim() external;

    // Admin
    function setStabilityPoolAddresses(
        address stabilityPool,
        address lusdToken,
        address lqtyToken
    ) external;
    function toggleAutoDeposit(bool enabled) external;
}

/**
 * @title StabilityPoolFacet
 * @notice Diamond facet for integrating with the Liquity V1 Stability Pool
 * @dev Allows the Ubiquity protocol to deposit LUSD collateral into the Liquity
 *      Stability Pool to earn ETH gains and LQTY rewards, increasing yield on
 *      LUSD collateral holdings.
 *
 * Integration flow:
 * - On mint: LUSD collateral is auto-deposited to the Stability Pool
 * - On redemption: LUSD is withdrawn from the Stability Pool
 * - ETH gains and LQTY rewards can be claimed at any time
 *
 * Uses the diamond storage pattern with a unique storage position.
 */
contract StabilityPoolFacet is IStabilityPoolFacet, Modifiers {
    //=====================
    // Views
    //=====================

    /// @inheritdoc IStabilityPoolFacet
    function stabilityPoolAddress() external view returns (address) {
        return LibStabilityPool.spStorage().stabilityPool;
    }

    /// @inheritdoc IStabilityPoolFacet
    function lusdTokenAddress() external view returns (address) {
        return LibStabilityPool.spStorage().lusdToken;
    }

    /// @inheritdoc IStabilityPoolFacet
    function lqtyTokenAddress() external view returns (address) {
        return LibStabilityPool.spStorage().lqtyToken;
    }

    /// @inheritdoc IStabilityPoolFacet
    function isAutoDepositEnabled() external view returns (bool) {
        return LibStabilityPool.spStorage().autoDepositEnabled;
    }

    /// @inheritdoc IStabilityPoolFacet
    function totalDeposited() external view returns (uint256) {
        return LibStabilityPool.spStorage().totalDeposited;
    }

    /// @inheritdoc IStabilityPoolFacet
    function accumulatedEthGains() external view returns (uint256) {
        return LibStabilityPool.spStorage().accumulatedEthGains;
    }

    /// @inheritdoc IStabilityPoolFacet
    function accumulatedLqtyRewards() external view returns (uint256) {
        return LibStabilityPool.spStorage().accumulatedLqtyRewards;
    }

    /// @inheritdoc IStabilityPoolFacet
    function compoundedLusdDeposit() external view returns (uint256) {
        StabilityPoolStorage storage ss = LibStabilityPool.spStorage();
        if (ss.stabilityPool == address(0)) return 0;
        return ILiquityStabilityPool(ss.stabilityPool).getCompoundedLUSDDeposit(address(this));
    }

    /// @inheritdoc IStabilityPoolFacet
    function pendingEthGain() external view returns (uint256) {
        StabilityPoolStorage storage ss = LibStabilityPool.spStorage();
        if (ss.stabilityPool == address(0)) return 0;
        return ILiquityStabilityPool(ss.stabilityPool).getDepositorETHGain(address(this));
    }

    /// @inheritdoc IStabilityPoolFacet
    function pendingLqtyGain() external view returns (uint256) {
        StabilityPoolStorage storage ss = LibStabilityPool.spStorage();
        if (ss.stabilityPool == address(0)) return 0;
        return ILiquityStabilityPool(ss.stabilityPool).getDepositorLQTYGain(address(this));
    }

    //=====================
    // Actions
    //=====================

    /// @inheritdoc IStabilityPoolFacet
    function depositToStabilityPool(uint256 amount) external {
        LibStabilityPool.deposit(amount);
    }

    /// @inheritdoc IStabilityPoolFacet
    function withdrawFromStabilityPool(uint256 amount) external {
        LibStabilityPool.withdraw(amount);
    }

    /// @inheritdoc IStabilityPoolFacet
    function withdrawAllFromStabilityPool() external {
        LibStabilityPool.withdrawAll();
    }

    /// @inheritdoc IStabilityPoolFacet
    function claimStabilityPoolRewards() external {
        LibStabilityPool.claimRewards();
    }

    /// @inheritdoc IStabilityPoolFacet
    function depositAndClaim() external {
        LibStabilityPool.claimRewards();
        // Caller should specify amount via depositToStabilityPool separately
    }

    //=====================
    // Admin
    //=====================

    /// @inheritdoc IStabilityPoolFacet
    function setStabilityPoolAddresses(
        address stabilityPool,
        address lusdToken,
        address lqtyToken
    ) external onlyAdmin {
        require(stabilityPool != address(0), "Invalid stability pool");
        require(lusdToken != address(0), "Invalid LUSD token");
        require(lqtyToken != address(0), "Invalid LQTY token");

        StabilityPoolStorage storage ss = LibStabilityPool.spStorage();
        ss.stabilityPool = stabilityPool;
        ss.lusdToken = lusdToken;
        ss.lqtyToken = lqtyToken;
    }

    /// @inheritdoc IStabilityPoolFacet
    function toggleAutoDeposit(bool enabled) external onlyAdmin {
        LibStabilityPool.spStorage().autoDepositEnabled = enabled;
        emit LibStabilityPool.AutoDepositToggled(enabled);
    }
}
