// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {ERC20Ubiquity} from "./ERC20Ubiquity.sol";
import {IERC20Ubiquity} from "../../dollar/interfaces/IERC20Ubiquity.sol";
import "../libraries/Constants.sol";

contract UbiquityGovernanceToken is ERC20Ubiquity {
    constructor(
        address _manager
    )
        // cspell: disable-next-line
        ERC20Ubiquity(_manager, "Ubiquity", "UBQ")
    {} // solhint-disable-line no-empty-blocks, max-line-length

    // ----------- Modifiers -----------
    modifier onlyGovernanceMinter() {
        require(
            accessCtrl.hasRole(GOVERNANCE_TOKEN_MINTER_ROLE, msg.sender),
            "Governance token: not minter"
        );
        _;
    }

    modifier onlyGovernanceBurner() {
        require(
            accessCtrl.hasRole(GOVERNANCE_TOKEN_BURNER_ROLE, msg.sender),
            "Governance token: not burner"
        );
        _;
    }

    /// @notice burn Ubiquity Dollar tokens from specified account
    /// @param account the account to burn from
    /// @param amount the amount to burn
    function burnFrom(
        address account,
        uint256 amount
    ) public override onlyGovernanceBurner whenNotPaused {
        _burn(account, amount);
        emit Burning(account, amount);
    }

    // @dev Creates `amount` new tokens for `to`.
    function mint(
        address to,
        uint256 amount
    ) public override onlyGovernanceMinter whenNotPaused {
        _mint(to, amount);
        emit Minting(to, msg.sender, amount);
    }
}
