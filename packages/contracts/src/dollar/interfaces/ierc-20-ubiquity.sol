// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ierc-20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ierc-20-permit.sol";

/// @title ERC20 Ubiquity preset interface
/// @author Ubiquity DAO
interface IERC20Ubiquity is IERC20, IERC20Permit {
    // ----------- Events -----------
    event Minting(
        address indexed _to,
        address indexed _minter,
        uint256 _amount
    );

    event Burning(address indexed _burned, uint256 _amount);

    // ----------- State changing api -----------
    function burn(uint256 amount) external;

    // ----------- Burner only state changing api -----------
    function burnFrom(address account, uint256 amount) external;

    // ----------- Minter only state changing api -----------
    function mint(address account, uint256 amount) external;
}
