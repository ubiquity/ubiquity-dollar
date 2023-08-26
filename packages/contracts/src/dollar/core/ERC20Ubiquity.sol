// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// import {ERC20, ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
// import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {IAccessControl} from "../interfaces/IAccessControl.sol";
import {DEFAULT_ADMIN_ROLE, PAUSER_ROLE} from "../libraries/Constants.sol";
import {Initializable} from "@openzeppelinUpgradeable/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelinUpgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelinUpgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {ERC20PermitUpgradeable} from "@openzeppelinUpgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {ERC20PausableUpgradeable} from "@openzeppelinUpgradeable/contracts/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelinUpgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import {IERC20PermitUpgradeable} from "@openzeppelinUpgradeable/contracts/token/ERC20/extensions/IERC20PermitUpgradeable.sol";

/**
 * @notice Base contract for Ubiquity ERC20 tokens (Dollar, Credit, Governance)
 * @notice ERC20 with:
 * - ERC20 minter, burner and pauser
 * - draft-ERC20 permit
 * - Ubiquity Manager access control
 */
abstract contract ERC20Ubiquity is
    Initializable,
    UUPSUpgradeable,
    ERC20Upgradeable,
    ERC20PermitUpgradeable,
    ERC20PausableUpgradeable
{
    /// @notice Token symbol
    string private _symbol;

    /// @notice Access control interface
    IAccessControl public accessControl;

    event Burning(address indexed _burned, uint256 _amount);
    event Minting(
        address indexed _to,
        address indexed _minter,
        uint256 _amount
    );

    /// @notice Modifier checks that the method is called by a user with the "pauser" role
    modifier onlyPauser() {
        require(
            accessControl.hasRole(PAUSER_ROLE, msg.sender),
            "ERC20Ubiquity: not pauser"
        );
        _;
    }

    /// @notice Modifier checks that the method is called by a user with the "admin" role
    modifier onlyAdmin() {
        require(
            accessControl.hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERC20Ubiquity: not admin"
        );
        _;
    }

    // /**
    //  * @notice Contract constructor
    //  * @param _manager Access control address
    //  * @param name_ Token name
    //  * @param symbol_ Token symbol
    //  */
    // constructor(
    //     address _manager,
    //     string memory name_,
    //     string memory symbol_
    // ) ERC20(name_, symbol_) ERC20Permit(name_) {
    //     _symbol = symbol_;
    //     accessControl = IAccessControl(_manager);
    // }

    constructor() {
        _disableInitializers();
    }

    function __ERC20Ubiquity_init(
        address _manager,
        string memory name_,
        string memory symbol_
    ) public onlyInitializing {
        __ERC20_init(name_, symbol_);
        __ERC20Permit_init(name_);
        __ERC20Pausable_init();
        _symbol = symbol_;
        accessControl = IAccessControl(_manager);
    }

    /**
     * @notice Updates token symbol
     * @param newSymbol New token symbol name
     */
    function setSymbol(string memory newSymbol) external onlyAdmin {
        _symbol = newSymbol;
    }

    /**
     * @notice Returns token symbol name
     * @return Token symbol name
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Returns access control address
     * @return Access control address
     */
    function getManager() external view returns (address) {
        return address(accessControl);
    }

    /**
     * @notice Sets access control address
     * @param _manager New access control address
     */
    function setManager(address _manager) external onlyAdmin {
        accessControl = IAccessControl(_manager);
    }

    /// @notice Pauses all token transfers
    function pause() public onlyPauser {
        _pause();
    }

    /// @notice Unpauses all token transfers
    function unpause() public onlyPauser {
        _unpause();
    }

    /**
     * @notice Destroys `amount` tokens from the caller
     * @param amount Amount of tokens to destroy
     */
    function burn(uint256 amount) public virtual whenNotPaused {
        _burn(_msgSender(), amount);
        emit Burning(msg.sender, amount);
    }

    /**
     * @notice Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance
     * @notice Requirements:
     * - the caller must have allowance for `account`'s tokens of at least `amount`
     * @param account Address to burn tokens from
     * @param amount Amount of tokens to burn
     */
    function burnFrom(address account, uint256 amount) public virtual;

    /**
     * @notice Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @notice Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override whenNotPaused {
        super._transfer(sender, recipient, amount);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyAdmin {}

    function allowance(
        address owner,
        address spender
    ) public view override(ERC20Upgradeable) returns (uint256) {
        return super.allowance(owner, spender);
    }

    function approve(
        address spender,
        uint256 amount
    ) public override(ERC20Upgradeable) returns (bool) {
        return super.approve(spender, amount);
    }

    function balanceOf(
        address account
    ) public view override(ERC20Upgradeable) returns (uint256) {
        return super.balanceOf(account);
    }

    function decimals() public view override returns (uint8) {
        return super.decimals();
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public override returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public override returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function nonces(
        address owner
    ) public view override(ERC20PermitUpgradeable) returns (uint256) {
        return super.nonces(owner);
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override(ERC20PermitUpgradeable) {
        super.permit(owner, spender, value, deadline, v, r, s);
    }

    function totalSupply()
        public
        view
        override(ERC20Upgradeable)
        returns (uint256)
    {
        return super.totalSupply();
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override(ERC20Upgradeable) returns (bool) {
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override(ERC20Upgradeable) returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    uint256[50] private __gap;
}
