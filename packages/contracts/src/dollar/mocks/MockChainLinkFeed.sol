// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../interfaces/AggregatorV3Interface.sol";

contract MockChainLinkFeed is AggregatorV3Interface {
    uint80 roundId;
    int256 answer;
    uint256 startedAt;
    uint256 updatedAt;
    uint80 answeredInRound;

    constructor() public {
        roundId = 0;
        answer = 0;
        startedAt = block.timestamp;
        updatedAt = block.timestamp;
        answeredInRound = 0;
    }

    function decimals() external view override returns (uint8) {
        return 18;
    }

    function description() external view override returns (string memory) {
        return "mock ChainLink data feed";
    }

    function version() external view override returns (uint256) {
        return 1;
    }

    function getRoundData(
        uint80
    )
        external
        view
        override
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (
            roundId,
            answer,
            block.timestamp,
            block.timestamp,
            answeredInRound
        );
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (
            roundId,
            answer,
            block.timestamp,
            block.timestamp,
            answeredInRound
        );
    }
}
