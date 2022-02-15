// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IJar is IERC20 {
    function claimInsurance() external; // NOTE: Only yDelegatedVault implements this

    function depositAll() external;

    function deposit(uint256) external;

    function withdrawAll() external;

    function withdraw(uint256) external;

    function earn() external;

    function token() external view returns (address);

    function reward() external view returns (address);

    function getRatio() external view returns (uint256);

    function balance() external view returns (uint256);

    function decimals() external view returns (uint8);
}
