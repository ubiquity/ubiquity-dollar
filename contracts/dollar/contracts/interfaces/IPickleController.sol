// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

interface IController {
    function withdraw(address, uint256) external;

    function withdrawReward(address, uint256) external;

    function earn(address, uint256) external;

    function jars(address) external view returns (address);

    function rewards() external view returns (address);

    function devfund() external view returns (address);

    function treasury() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function strategies(address) external view returns (address);
}
