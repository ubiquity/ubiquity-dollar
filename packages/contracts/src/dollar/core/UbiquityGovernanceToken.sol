// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import "../ERC20Ubiquity.sol";
import "src/dollar/core/UbiquityDollarManager.sol";

contract UbiquityGovernanceToken is ERC20Ubiquity {
    constructor(
        UbiquityDollarManager _manager
    ) ERC20Ubiquity(_manager, "Ubiquity", "UBQ") {} // solhint-disable-line no-empty-blocks, max-line-length
}
