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
    error EthTransferFailed();

    event Initialized(address treasury, address stabilityPool, address lusd, address lqty, uint256 threshold);
    event Deposited(uint256 amount);
    event Withdrawn(uint256 amountRequested, uint256 amountReceived);
    event RewardsHarvested(uint256 lqtyAmount, uint256 ethAmount);
    event TreasuryUpdated(address newTreasury);
    event ThresholdUpdated(uint256 newThreshold);
    event PauseToggled(bool paused);
    event EmergencyWithdraw(address token, uint256 amount);

    modifier onlyAdmin() {
        if (!LibAccessControl.hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert NotAdmin();
        _;
    }

    modifier notPaused() {
        if (LibAppStorage.appStorage().liquidityPaused) revert Paused();
        _;
    }

    receive() external payable {}

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

        emit Initialized(_treasury, _stabilityPool, _lusdToken, _lqtyToken, _threshold);
    }

    function depositToPool(uint256 amount) external onlyAdmin notPaused {
        if (amount == 0) revert ZeroAmount();
        AppStorage storage s = LibAppStorage.appStorage();

        IERC20 lusd = IERC20(s.lusdToken);
        lusd.safeTransferFrom(msg.sender, address(this), amount);
        lusd.safeApprove(s.liquidityStabilityPool, 0);
        lusd.safeApprove(s.liquidityStabilityPool, amount);

        ILiquityStabilityPool(s.liquidityStabilityPool).provideToSP(amount, address(0));
        s.totalPrincipalInPool += amount;

        emit Deposited(amount);
    }

    function withdrawFromPool(uint256 amount) external onlyAdmin notPaused {
        if (amount == 0) revert ZeroAmount();
        AppStorage storage s = LibAppStorage.appStorage();

        ILiquityStabilityPool sp = ILiquityStabilityPool(s.liquidityStabilityPool);
        uint256 poolBalanceBefore = sp.getCompoundedLUSDDeposit(address(this));
        if (poolBalanceBefore < amount) revert InsufficientBalance();

        IERC20 lusd = IERC20(s.lusdToken);
        uint256 balanceBefore = lusd.balanceOf(address(this));

        sp.withdrawFromSP(amount);

        uint256 balanceAfter = lusd.balanceOf(address(this));
        uint256 received = balanceAfter - balanceBefore;

        if (received > 0) {
            lusd.safeTransfer(s.liquidityTreasury, received);
        }

        uint256 poolBalanceAfter = sp.getCompoundedLUSDDeposit(address(this));
        s.totalPrincipalInPool -= (poolBalanceBefore - poolBalanceAfter);

        emit Withdrawn(amount, received);
    }

    function harvestRewards() external onlyAdmin notPaused {
        AppStorage storage s = LibAppStorage.appStorage();
        ILiquityStabilityPool sp = ILiquityStabilityPool(s.liquidityStabilityPool);

        uint256 lqtyGain = sp.getDepositorLQTYGain(address(this));
        uint256 ethGain = sp.getDepositorETHGain(address(this));

        if (lqtyGain < s.liquidityHarvestThreshold && ethGain == 0) revert BelowThreshold();

        uint256 ethBalanceBefore = address(this).balance;
        sp.withdrawFromSP(0);
        uint256 ethHarvested = address(this).balance - ethBalanceBefore;

        uint256 lqtyHarvested = 0;
        if (lqtyGain > 0) {
            IERC20 lqty = IERC20(s.lqtyToken);
            uint256 actualLqty = lqty.balanceOf(address(this));
            if (actualLqty > 0) {
                lqty.safeTransfer(s.liquidityTreasury, actualLqty);
                lqtyHarvested = actualLqty;
            }
        }

        if (ethHarvested > 0) {
            (bool success, ) = s.liquidityTreasury.call{value: ethHarvested}("");
            if (!success) revert EthTransferFailed();
        }

        emit RewardsHarvested(lqtyHarvested, ethHarvested);
    }

    function setTreasury(address _treasury) external onlyAdmin {
        LibAppStorage.appStorage().liquidityTreasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    function setThreshold(uint256 _threshold) external {
        LibAppStorage.appStorage().liquidityHarvestThreshold = _threshold;
        emit ThresholdUpdated(_threshold);
    }

    function togglePause() external {
        AppStorage storage s = LibAppStorage.appStorage();
        s.liquidityPaused = !s.liquidityPaused;
        emit PauseToggled(s.liquidityPaused);
    }

    function emergencyWithdraw(address token, uint256 amount) external onlyAdmin {
        IERC20(token).safeTransfer(msg.sender, amount);
        emit EmergencyWithdraw(token, amount);
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
