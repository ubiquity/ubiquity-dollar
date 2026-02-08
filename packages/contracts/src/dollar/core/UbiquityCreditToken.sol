// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {ManagerFacet} from "../facets/ManagerFacet.sol";
import {ERC20Ubiquity} from "./ERC20Ubiquity.sol";
import {IERC20Ubiquity} from "../../dollar/interfaces/IERC20Ubiquity.sol";

import "../libraries/Constants.sol";

/**
 * @notice Credit token contract
 */
contract UbiquityCreditToken is ERC20Ubiquity {
    /// @notice Ensures initialize cannot be called on the implementation contract
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract
    /// @param _manager Address of the Ubiquity Manager
    function initialize(address _manager) public initializer {
        // cspell: disable-next-line
        __ERC20Ubiquity_init(_manager, "Ubiquity Credit", "uCR");
    }

    // ----------- Modifiers -----------

    /// @notice Modifier checks that the method is called by a user with the "Credit minter" role
    modifier onlyCreditMinter() {
        require(
            accessControl.hasRole(CREDIT_TOKEN_MINTER_ROLE, _msgSender()),
            "Credit token: not minter"
        );
        _;
    }

    /// @notice Modifier checks that the method is called by a user with the "Credit burner" role
    modifier onlyCreditBurner() {
        require(
            accessControl.hasRole(CREDIT_TOKEN_BURNER_ROLE, _msgSender()),
            "Credit token: not burner"
        );
        _;
    }

    /**
     * @notice Raises capital in the form of Ubiquity Credit Token
     * @param amount Amount to be minted
     * @dev CREDIT_TOKEN_MINTER_ROLE access control role is required to call this function
     */
    function raiseCapital(uint256 amount) external {
        address treasuryAddress = ManagerFacet(address(accessControl))
            .treasuryAddress();
        mint(treasuryAddress, amount);
    }

    /**
     * @notice Burns Ubiquity Credit tokens from specified account
     * @param account Account to burn from
     * @param amount Amount to burn
     */
    function burnFrom(
        address account,
        uint256 amount
    ) public override onlyCreditBurner whenNotPaused {
        _burn(account, amount);
        emit Burning(account, amount);
    }

    /**
     * @notice Creates `amount` new Credit tokens for `to`
     * @param to Account to mint Credit tokens to
     * @param amount Amount of Credit tokens to mint
     */
    function mint(
        address to,
        uint256 amount
    ) public onlyCreditMinter whenNotPaused {
        _mint(to, amount);
        emit Minting(to, _msgSender(), amount);
    }

    /// @notice Allows an admin to upgrade to another implementation contract
    /// @param newImplementation Address of the new implementation contract
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyAdmin {}
}
