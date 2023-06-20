// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {ManagerFacet} from "../facets/manager-facet.sol";
import {ERC20Ubiquity} from "erc-20-ubiquity.sol";
import {IERC20Ubiquity} from "../../dollar/interfaces/ierc-20-ubiquity.sol";
import "../libraries/constants.sol";

contract UbiquityCreditToken is ERC20Ubiquity {
    constructor(
        address _manager
    )
        // cspell: disable-next-line
        ERC20Ubiquity(_manager, "Ubiquity Credit", "uCR")
    {} // solhint-disable-line no-empty-blocks

    // ----------- Modifiers -----------
    modifier onlyCreditMinter() {
        require(
            accessCtrl.hasRole(CREDIT_TOKEN_MINTER_ROLE, msg.sender),
            "Credit token: not minter"
        );
        _;
    }

    modifier onlyCreditBurner() {
        require(
            accessCtrl.hasRole(CREDIT_TOKEN_BURNER_ROLE, msg.sender),
            "Credit token: not burner"
        );
        _;
    }

    /// @notice raise capital in form of Ubiquity Credit Token (only redeemable when Ubiquity Dollar > 1$)
    /// @param amount the amount to be minted
    /// @dev you should be minter to call that function
    function raiseCapital(uint256 amount) external {
        address treasuryAddress = ManagerFacet(address(accessCtrl))
            .treasuryAddress();
        mint(treasuryAddress, amount);
    }

    /// @notice burn Ubiquity Credit tokens from specified account
    /// @param account the account to burn from
    /// @param amount the amount to burn
    function burnFrom(
        address account,
        uint256 amount
    ) public override onlyCreditBurner whenNotPaused {
        _burn(account, amount);
        emit Burning(account, amount);
    }

    // @dev Creates `amount` new Credit tokens for `to`.
    function mint(
        address to,
        uint256 amount
    ) public override onlyCreditMinter whenNotPaused {
        _mint(to, amount);
        emit Minting(to, msg.sender, amount);
    }
}
