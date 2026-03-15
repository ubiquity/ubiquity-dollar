// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ILiquityStabilityPool} from "../interfaces/ILiquityStabilityPool.sol";

/**
 * @notice Mock Liquity Stability Pool for testing
 * @dev Simulates deposit/withdrawal behavior, ETH/LQTY gain accrual,
 *      and liquidation-based deposit reduction (compounding).
 */
contract MockLiquityStabilityPool is ILiquityStabilityPool {
    IERC20 public lusdToken;
    IERC20 public lqtyToken;

    mapping(address => uint256) public deposits;
    mapping(address => uint256) public ethGains;
    mapping(address => uint256) public lqtyGains;

    /// @notice Simulated loss ratio (basis points). 0 = no loss. 500 = 5% loss.
    uint256 public lossRatioBps;

    constructor(address _lusdToken, address _lqtyToken) {
        lusdToken = IERC20(_lusdToken);
        lqtyToken = IERC20(_lqtyToken);
    }

    function provideToSP(uint256 _amount, address) external override {
        lusdToken.transferFrom(msg.sender, address(this), _amount);
        deposits[msg.sender] += _amount;
    }

    function withdrawFromSP(uint256 _amount) external override {
        uint256 compounded = getCompoundedLUSDDeposit(msg.sender);
        uint256 toWithdraw = _amount > compounded ? compounded : _amount;

        // Reduce deposit
        if (toWithdraw >= deposits[msg.sender]) {
            deposits[msg.sender] = 0;
        } else {
            deposits[msg.sender] -= toWithdraw;
        }

        // Transfer LUSD back
        if (toWithdraw > 0) {
            lusdToken.transfer(msg.sender, toWithdraw);
        }

        // Transfer ETH gains
        uint256 ethGain = ethGains[msg.sender];
        if (ethGain > 0) {
            ethGains[msg.sender] = 0;
            (bool success, ) = msg.sender.call{value: ethGain}("");
            require(success, "ETH transfer failed");
        }

        // Transfer LQTY gains
        uint256 lqtyGain = lqtyGains[msg.sender];
        if (lqtyGain > 0) {
            lqtyGains[msg.sender] = 0;
            lqtyToken.transfer(msg.sender, lqtyGain);
        }
    }

    function getDepositorETHGain(
        address _depositor
    ) external view override returns (uint256) {
        return ethGains[_depositor];
    }

    function getDepositorLQTYGain(
        address _depositor
    ) external view override returns (uint256) {
        return lqtyGains[_depositor];
    }

    function getCompoundedLUSDDeposit(
        address _depositor
    ) public view override returns (uint256) {
        uint256 deposit = deposits[_depositor];
        if (lossRatioBps > 0) {
            uint256 loss = (deposit * lossRatioBps) / 10000;
            return deposit - loss;
        }
        return deposit;
    }

    // ---- Test helpers ----

    /// @notice Simulate ETH gains from liquidations
    function setETHGain(address _depositor, uint256 _amount) external {
        ethGains[_depositor] = _amount;
    }

    /// @notice Simulate LQTY reward gains
    function setLQTYGain(address _depositor, uint256 _amount) external {
        lqtyGains[_depositor] = _amount;
    }

    /// @notice Simulate liquidation losses (basis points)
    function setLossRatio(uint256 _bps) external {
        lossRatioBps = _bps;
    }

    /// @notice Fund the mock with ETH for gain distribution
    receive() external payable {}
}
