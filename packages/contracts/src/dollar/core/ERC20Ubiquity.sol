// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20, ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {IAccessControl} from "../interfaces/IAccessControl.sol";
import {DEFAULT_ADMIN_ROLE, PAUSER_ROLE} from "../libraries/Constants.sol";
import {IERC20Ubiquity} from "../../dollar/interfaces/IERC20Ubiquity.sol";

/// @title ERC20 Ubiquity preset
/// @author Ubiquity DAO
/// @notice ERC20 with :
/// - ERC20 minter, burner and pauser
/// - draft-ERC20 permit
/// - Ubiquity Manager access control
abstract contract ERC20Ubiquity is ERC20Permit, ERC20Pausable, IERC20Ubiquity {
    string private _symbol;
    IAccessControl public accessCtrl;

    // modifiers
    modifier onlyPauser() {
        require(
            accessCtrl.hasRole(PAUSER_ROLE, msg.sender),
            "ERC20Ubiquity: not pauser"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            accessCtrl.hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERC20Ubiquity: not admin"
        );
        _;
    }

    constructor(
        address _manager,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) ERC20Permit(name_) {
        _symbol = symbol_;
        accessCtrl = IAccessControl(_manager);
    }

    /// @notice setSymbol update token symbol
    /// @param newSymbol new token symbol
    function setSymbol(string memory newSymbol) external onlyAdmin {
        _symbol = newSymbol;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /// @notice getManager returns the manager address
    /// @return manager address
    function getManager() external view returns (address) {
        return address(accessCtrl);
    }

    /// @notice setManager update the manager address
    /// @param _manager new manager address
    function setManager(address _manager) external onlyAdmin {
        accessCtrl = IAccessControl(_manager);
    }

    // @dev Pauses all token transfers.
    function pause() public onlyPauser {
        _pause();
    }

    // @dev Unpauses all token transfers.
    function unpause() public onlyPauser {
        _unpause();
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual whenNotPaused {
        _burn(_msgSender(), amount);
        emit Burning(msg.sender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual;

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override whenNotPaused {
        super._transfer(sender, recipient, amount);
    }
}
