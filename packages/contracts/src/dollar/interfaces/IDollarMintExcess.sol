// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/**
 * @notice Interface for distributing excess Dollars when `mintClaimableDollars()` is called
 * @notice Excess Dollars are distributed this way:
 * - 50% goes to the treasury address
 * - 10% goes for burning Dollar-Governance LP tokens in a DEX pool
 * - 40% goes to the Staking contract
 *
 * @notice Example:
 * 1. 1000 Dollars should be distributed
 * 2. 50% (500 Dollars) goes to the `AppStorage.treasuryAddress`
 * 3. 10% (100 Dollars) goes for burning Dollar-Governance LP tokens:
 *   - Half of 10% Dollars are swapped for Governance tokens on a DEX
 *   - Governance tokens and half of 10% tokens are added as a liquidity to the Dollar-Governance DEX pool
 *   - Dollar-Governance LP tokens are transfered to 0 address (i.e. burning LP tokens)
 * 4. 40% (400 Dollars) goes to the Staking contract:
 *   - Swap Dollars for 3CRV LP tokens in the Curve's Dollar-3CRV MetaPool
 *   - Add 3CRV LP tokens to the Curve Dollar-3CRV MetaPool
 *   - Transfer Dollar-3CRV LP tokens to the Staking contract
 */
interface IDollarMintExcess {
    /**
     * @notice Distributes excess Dollars:
     * - 50% goes to the treasury address
     * - 10% goes for burning Dollar-Governance LP tokens in a DEX pool
     * - 40% goes to the Staking contract
     */
    function distributeDollars() external;
}
