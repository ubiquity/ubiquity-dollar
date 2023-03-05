// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../token/ERC1155UbiquityForDiamond.sol";

contract BondingShareForDiamond is ERC1155UbiquityForDiamond {
    // solhint-disable-next-line no-empty-blocks
    constructor(address _diamond) ERC1155UbiquityForDiamond(_diamond, "URI") {}
}
