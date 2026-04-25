// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../interfaces/ILiquityStabilityPool.sol";
import "../libraries/LibAppStorage.sol";
import "../libraries/LibAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract StabilityPoolFacet {
    using SafeERC20 for IERC20;

    error NotAdmin();
    error Paused();
    error ZeroAmount();
    error BelowThreshold();
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

    function initialize(
        address _treasury,
        address _stabilityPool,
        address _lusdToken,
        address _lqtyToken,
        uint256 _threshold
    ) external {
        AppStorage storage s = LibAppStorage.appStorage();
        if (s.liquidityStabilityPool != address(0)) revert AlreadyInitialized();

        s.liquidityTreasury = _treasury;
        s.liquidityStabilityPool = _stabilityPool;
        s.lusdToken = _lusdToken;
        s.lqtyToken = _lqtyToken;
        s.liquidityHarvestThreshold = _threshold;
        s.liquidityPaused = false;
        s.totalPrincipalInPool = 0;
    }

    function depositToPool(uint256 amount) external notPaused {
        if (amount == 0) revert ZeroAmount();
        AppStorage storage s = LibAppStorage.appStorage();

        IERC20 lusd = IERC20(s.lusdToken);
        lusd.safeTransferFrom(msg.sender, address(this), amount);
        lusd.safeApprove(s.liquidityStabilityPool, amount);

        ILiquityStabilityPool(s.liquidityStabilityPool).provideToSP(amount, address(0));
        s.totalPrincipalInPool += amount;
    }

    function withdrawFromPool(uint256 amount) external notPaused {
        if (amount == 0) revert ZeroAmount();
        AppStorage storage s = LibAppStorage.appStorage();
        if (s.totalPrincipalInPool < amount) revert InsufficientBalance();

        IERC20 lusd = IERC20(s.lusdToken);
        uint256 balanceBefore = lusd.balanceOf(address(this));

        ILiquityStabilityPool(s.liquidityStabilityPool).withdrawFromSP(amount);

        uint256 balanceAfter = lusd.balanceOf(address(this));
        uint256 received = balanceAfter - balanceBefore;

        if (received > 0) {
            lusd.safeTransfer(msg.sender, received);
        }

        s.totalPrincipalInPool -= amount;
    }

    function harvestRewards() external notPaused {
        AppStorage storage s = LibAppStorage.appStorage();
        ILiquityStabilityPool sp = ILiquityStabilityPool(s.liquidityStabilityPool);

        uint256 lqtyGain = sp.getDepositorLQTYGain(address(this));
        uint256 ethGain = sp.getDepositorETHGain(address(this));

        if (lqtyGain < s.liquidityHarvestThreshold && ethGain == 0) revert BelowThreshold();

        sp.withdrawFromSP(0);

        if (lqtyGain > 0) {
            IERC20 lqty = IERC20(s.lqtyToken);
            uint256 actualLqty = lqtyGain;
            if (actualLqty > 0) {
                lqty.safeTransfer(s.liquidityTreasury, actualLqty);
            }
        }
    }

    function setTreasury(address _treasury) external onlyAdmin {
        LibAppStorage.appStorage().liquidityTreasury = _treasury;
    }

    function setThreshold(uint256 _threshold) external {
        LibAppStorage.appStorage().liquidityHarvestThreshold = _threshold;
    }

    function togglePause() external {
        AppStorage storage s = LibAppStorage.appStorage();
        s.liquidityPaused = !s.liquidityPaused;
    }

    function emergencyWithdraw(address token, uint256 amount) external onlyAdmin {
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    function totalPrincipalInPool() external view returns (uint256) {
        return LibAppStorage.appStorage().totalPrincipalInPool;
    }

    function getPendingRewards() external view returns (uint256 lqtyGain, uint256 ethGain) {
        AppStorage storage s = LibAppStorage.appStorage();
        ILiquityStabilityPool sp = ILiquityStabilityPool(s.liquidityStabilityPool);
        lqtyGain = sp.getDepositorLQTYGain(address(this));
        ethGain = sp.getDepositorETHGain(address(this));
    }
}
