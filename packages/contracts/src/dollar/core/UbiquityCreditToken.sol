// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import "../ERC20Ubiquity.sol";
import "src/dollar/core/UbiquityDollarManager.sol";

contract UbiquityCreditToken is ERC20Ubiquity {
    constructor(
        UbiquityDollarManager _manager
    ) ERC20Ubiquity(_manager, "Ubiquity Auto Redeem", "uAR") {} // solhint-disable-line no-empty-blocks

    /// @notice raise capital in form of Ubiquity Credit Token (only redeemable when Ubiquity Dollar > 1$)
    /// @param amount the amount to be minted
    /// @dev you should be minter to call that function
    function raiseCapital(uint256 amount) external {
        address treasuryAddress = manager.treasuryAddress();
        mint(treasuryAddress, amount);
    }
}
