// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

import "./ERC20UbiquityForDiamond.sol";

contract UbiquityGovernanceTokenForDiamond is ERC20UbiquityForDiamond {
    constructor(address _manager)
        ERC20UbiquityForDiamond(_manager, "Ubiquity", "UBQ")
    {} // solhint-disable-line no-empty-blocks, max-line-length
}
