// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ILiquityStabilityPool} from "../interfaces/ILiquityStabilityPool.sol";

/**
 * @title MockLiquityStabilityPool
 * @notice Mock contract simulating Liquity V1 Stability Pool for testing
 * @dev ETH rewards are not auto-pushed on withdraw in the mock. Instead, use
 *      vm.deal to simulate ETH arriving at the caller (the Diamond proxy requires
 *      a receive() function to accept raw ETH transfers from the real Liquity pool).
 */
contract MockLiquityStabilityPool is ILiquityStabilityPool {
    IERC20 public lusdToken;

    // depositor -> deposit amount
    mapping(address => uint256) public deposits;
    // depositor -> ETH gain (tracked for view functions)
    mapping(address => uint256) public ethGains;
    // depositor -> LQTY gain
    mapping(address => uint256) public lqtyGains;

    IERC20 public lqtyToken;

    constructor(address _lusdToken, address _lqtyToken) {
        lusdToken = IERC20(_lusdToken);
        lqtyToken = IERC20(_lqtyToken);
    }

    function provideToSP(uint256 _amount, address) external override {
        lusdToken.transferFrom(msg.sender, address(this), _amount);
        deposits[msg.sender] += _amount;
    }

    function withdrawFromSP(uint256 _amount) external override {
        if (_amount > 0) {
            require(
                deposits[msg.sender] >= _amount,
                "MockSP: insufficient deposit"
            );
            deposits[msg.sender] -= _amount;
            lusdToken.transfer(msg.sender, _amount);
        }

        // Distribute accumulated LQTY rewards
        uint256 lqtyGain = lqtyGains[msg.sender];
        if (lqtyGain > 0) {
            lqtyGains[msg.sender] = 0;
            lqtyToken.transfer(msg.sender, lqtyGain);
        }

        // Clear ETH gain tracking (ETH delivery simulated via vm.deal in tests,
        // since Diamond proxy requires receive() for raw ETH transfers)
        ethGains[msg.sender] = 0;
    }

    function getCompoundedLUSDDeposit(
        address _depositor
    ) external view override returns (uint256) {
        return deposits[_depositor];
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

    // Test helpers to simulate rewards accumulation

    function setETHGain(address _depositor, uint256 _amount) external {
        ethGains[_depositor] = _amount;
    }

    function setLQTYGain(address _depositor, uint256 _amount) external {
        lqtyGains[_depositor] = _amount;
    }

    /// @notice Allows the mock to receive ETH for distributing as rewards
    receive() external payable {}
}
