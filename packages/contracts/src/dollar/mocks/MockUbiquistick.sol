// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MockUbiquistick is ERC1155 {
    // cspell: disable-next-line
    constructor() ERC1155("UbiquiStick") {
    }

    function mint(address to, uint256 id, uint256 amount, bytes memory data) public {
        _mint(to, id, amount, data);
    }
}
