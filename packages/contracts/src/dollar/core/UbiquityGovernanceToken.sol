// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {ERC20Ubiquity} from "./ERC20Ubiquity.sol";
import {IERC20Ubiquity} from "../../dollar/interfaces/IERC20Ubiquity.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../libraries/Constants.sol";

/**
 * @notice Ubiquity Governance token contract
 */
contract UbiquityGovernanceToken is ERC20Ubiquity {
    /// @notice Ensures initialize cannot be called on the implementation contract
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract
    /// @param _manager Address of the Ubiquity Manager
    function initialize(address _manager) public initializer {
        // cspell: disable-next-line
        __ERC20Ubiquity_init(_manager, "Ubiquity", "UBQ");
    }

    // ----------- Modifiers -----------

    /// @notice Modifier checks that the method is called by a user with the "Governance minter" role
    modifier onlyGovernanceMinter() {
        require(
            accessControl.hasRole(GOVERNANCE_TOKEN_MINTER_ROLE, _msgSender()),
            "Governance token: not minter"
        );
        _;
    }

    /// @notice Modifier checks that the method is called by a user with the "Governance burner" role
    modifier onlyGovernanceBurner() {
        require(
            accessControl.hasRole(GOVERNANCE_TOKEN_BURNER_ROLE, _msgSender()),
            "Governance token: not burner"
        );
        _;
    }

    /**
     * @notice Burns Governance tokens from the `account` address
     * @param account Address to burn tokens from
     * @param amount Amount of tokens to burn
     */
    function burnFrom(
        address account,
        uint256 amount
    ) public override onlyGovernanceBurner whenNotPaused {
        _burn(account, amount);
        emit Burning(account, amount);
    }

    /**
     * @notice Mints Governance tokens to the `to` address
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     */
    function mint(
        address to,
        uint256 amount
    ) public onlyGovernanceMinter whenNotPaused {
        _mint(to, amount);
        emit Minting(to, _msgSender(), amount);
    }

    /// @notice Allows an admin to upgrade to another implementation contract
    /// @param newImplementation Address of the new implementation contract
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyAdmin {}
}
