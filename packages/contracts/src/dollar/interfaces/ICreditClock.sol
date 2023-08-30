// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// Interface for a CreditClockFacet contract
interface ICreditClock {
    // Event emitted when the rate per block is updated
    event SetRatePerBlock(
        uint256 rateStartBlock,
        bytes16 rateStartValue,
        bytes16 ratePerBlock
    );

    // Function to get the manager's address
    function getManager() external view returns (address);

    // Function to get the rate at a specific block number
    function getRate(uint256 blockNumber) external view returns (bytes16 rate);

    // Function to set the manager's address (only callable by the current manager)
    function setManager(address _manager) external;

    // Function to set the rate per block (only callable by the current manager)
    function setRatePerBlock(bytes16 _ratePerBlock) external;
}
