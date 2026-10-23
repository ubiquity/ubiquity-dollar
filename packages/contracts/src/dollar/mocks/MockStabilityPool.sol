// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Mock Stability Pool for testing
contract MockStabilityPool {
    address public LUSD;
    address public lqtyToken;

    mapping(address => uint256) public deposits;
    mapping(address => uint256) public ethGains;
    mapping(address => uint256) public lqtyGains;
    uint256 public totalLUSDDeposits;

    constructor(address _lusd, address _lqty) {
        LUSD = _lusd;
        lqtyToken = _lqty;
    }

    function provideToSP(uint256 _amount, address) external {
        if (_amount > 0) {
            IERC20(LUSD).transferFrom(msg.sender, address(this), _amount);
            deposits[msg.sender] += _amount;
            totalLUSDDeposits += _amount;
        }

        // Simulate reward payout: transfer ETH and LQTY gains to caller
        uint256 ethGain = ethGains[msg.sender];
        uint256 lqtyGain = lqtyGains[msg.sender];

        if (ethGain > 0) {
            ethGains[msg.sender] = 0;
            (bool success, ) = msg.sender.call{value: ethGain}("");
            require(success, "MockSP: ETH transfer failed");
        }

        if (lqtyGain > 0) {
            lqtyGains[msg.sender] = 0;
            IERC20(lqtyToken).transfer(msg.sender, lqtyGain);
        }
    }

    function withdrawFromSP(uint256 _amount) external {
        require(
            deposits[msg.sender] >= _amount,
            "MockStabilityPool: insufficient deposit"
        );
        deposits[msg.sender] -= _amount;
        totalLUSDDeposits -= _amount;
        IERC20(LUSD).transfer(msg.sender, _amount);
    }

    function getDepositorETHGain(
        address _depositor
    ) external view returns (uint256) {
        return ethGains[_depositor];
    }

    function getDepositorLQTYGain(
        address _depositor
    ) external view returns (uint256) {
        return lqtyGains[_depositor];
    }

    function getCompoundedLUSDDeposit(
        address _depositor
    ) external view returns (uint256) {
        return deposits[_depositor];
    }

    function getTotalLUSDDeposits() external view returns (uint256) {
        return totalLUSDDeposits;
    }

    // --- Test helpers ---

    /// @dev Set the ETH gain for a depositor (fund this contract with ETH first)
    function setETHGain(address _depositor, uint256 _amount) external {
        ethGains[_depositor] = _amount;
    }

    /// @dev Set the LQTY gain for a depositor (fund this contract with LQTY first)
    function setLQTYGain(address _depositor, uint256 _amount) external {
        lqtyGains[_depositor] = _amount;
    }

    receive() external payable {}
}
