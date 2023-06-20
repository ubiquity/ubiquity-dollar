// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/erc-4626.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ZozoVault is ERC4626 {
    constructor(ERC20 _asset) ERC4626(_asset) ERC20("ZoZo Vault", "vZOZO") {}

    function totalAssets() public view override returns (uint256) {
        return ERC20(asset()).balanceOf(address(this));
    }
}
