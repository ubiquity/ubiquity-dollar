// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../interfaces/ILiquityStabilityPool.sol";
import "../libraries/LibAppStorage.sol";
import "../libraries/LibAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title StabilityPoolFacet
/// @notice Facet for integrating Liquity V1 Stability Pool yield into Ubiquity Dollar
contract StabilityPoolFacet {
    using SafeERC20 for IERC20;

    error NotAdmin();
    error Paused();
    error ZeroAmount();
    error BelowThreshold();
    error TransferFailed();
    error AlreadyInitialized();
    error InsufficientBalance();

    modifier onlyAdmin() {
        if (!LibAccessControl.hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert NotAdmin();
        _;
    }

    modifier notPaused() {
        AppStorage storage s = LibAppStorage.appStorage();
        if (s.liquidityPaused) revert Paused();
        _;
    }

    function initialize(address _treasury, address _stabilityPool, uint256 _threshold) external {
        AppStorage storage s = LibAppStorage.appStorage();
        if (s.liquidityStabilityPool != address(0)) revert AlreadyInitialized();
        s.liquidityTreasury = _treasury;
        s.liquidityStabilityPool = _stabilityPool;
        s.liquidityHarvestThreshold = _threshold;
        s.liquidityPaused = false;
    }

    function depositToPool(uint256 amount) external notPaused {
        if (amount == 0) revert ZeroAmount();
        AppStorage storage s = LibAppStorage.appStorage();
        IERC20 lusd = IERC20(0x5f98805A4E8be255a32880FDeC7F6728C6568bA0);
        lusd.safeTransferFrom(msg.sender, address(this), amount);
        ILiquityStabilityPool(s.liquidityStabilityPool).provideToSP(amount);
        s.totalPrincipalInPool += amount;
    }

    function withdrawFromPool(uint256 amount) external notPaused {
        if (amount == 0) revert ZeroAmount();
        AppStorage storage s = LibAppStorage.appStorage();
        if (s.totalPrincipalInPool < amount) revert InsufficientBalance();
        ILiquityStabilityPool(s.liquidityStabilityPool).withdrawFromSP(amount);
        IERC20 lusd = IERC20(0x5f98805A4E8be255a32880FDeC7F6728C6568bA0);
        lusd.safeTransfer(msg.sender, amount);
        s.totalPrincipalInPool -= amount;
    }

    function harvestRewards() external notPaused {
        AppStorage storage s = LibAppStorage.appStorage();
        uint256 gain = ILiquityStabilityPool(s.liquidityStabilityPool).getDepositorLQTYGain(address(this));
        if (gain < s.liquidityHarvestThreshold) revert BelowThreshold();
        ILiquityStabilityPool(s.liquidityStabilityPool).claimLQTY();
        IERC20 lqty = IERC20(0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D);
        lqty.safeTransfer(s.liquidityTreasury, gain);
    }

    function setTreasury(address _treasury) external {
        LibAppStorage.appStorage().liquidityTreasury = _treasury;
    }
    function setThreshold(uint256 _threshold) external {
        LibAppStorage.appStorage().liquidityHarvestThreshold = _threshold;
    }
    function togglePause() external {
        AppStorage storage s = LibAppStorage.appStorage();
        s.liquidityPaused = !s.liquidityPaused;
    }
    function emergencyWithdraw(address token, uint256 amount) external {
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    function totalPrincipalInPool() external view returns (uint256) {
        return LibAppStorage.appStorage().totalPrincipalInPool;
    }
    function getPendingRewards() external view returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        return ILiquityStabilityPool(s.liquidityStabilityPool).getDepositorLQTYGain(address(this));
    }
}
