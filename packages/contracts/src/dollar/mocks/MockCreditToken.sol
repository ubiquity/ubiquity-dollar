// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockCreditToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Ubiquity Auto Redeem", "uAR") {
        _mint(msg.sender, initialSupply);
    }

    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }

    function burnFrom(address account, uint256 amount) public {
        _burn(account, amount);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function raiseCapital(uint256 amount) external {
        mint(address(this), amount);
    }
}
