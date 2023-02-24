// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {IAccessControl} from "../interfaces/IAccessControl.sol";
import "../libraries/Constants.sol";
import {IERC20Ubiquity} from "../../dollar/interfaces/IERC20Ubiquity.sol";

/// @title ERC20 Ubiquity preset
/// @author Ubiquity DAO
/// @notice ERC20 with :
/// - ERC20 minter, burner and pauser
/// - draft-ERC20 permit
/// - Ubiquity Manager access control
abstract contract ERC20UbiquityForDiamond is
    ERC20,
    ERC20Pausable,
    IERC20Ubiquity
{
    IAccessControl public immutable accessCtrl;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 public immutable DOMAIN_SEPARATOR;
    mapping(address => uint256) public nonces;
    string private _tokenName;
    string private _symbol;

    // modifiers
    modifier onlyPauser() {
        require(
            accessCtrl.hasRole(PAUSER_ROLE, msg.sender),
            "ERC20: not pauser"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            accessCtrl.hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERC20: not admin"
        );
        _;
    }

    constructor(
        address _diamond,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {
        _tokenName = name_;
        _symbol = symbol_;
        accessCtrl = IAccessControl(_diamond);

        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    // solhint-disable-next-line max-line-length
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name())),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    /// @notice setSymbol update token symbol
    /// @param newSymbol new token symbol
    function setSymbol(string memory newSymbol) external onlyAdmin {
        _symbol = newSymbol;
    }

    /// @notice setName update token name
    /// @param newName new token name
    function setName(string memory newName) external onlyAdmin {
        _tokenName = newName;
    }

    /// @notice permit spending of Ubiquity Dollar. owner has signed a message allowing
    ///         spender to transfer up to amount Ubiquity Dollar
    /// @param owner the Ubiquity Dollar holder
    /// @param spender the approved operator
    /// @param value the amount approved
    /// @param deadline the deadline after which the approval is no longer valid
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        // solhint-disable-next-line not-rely-on-time
        require(deadline >= block.timestamp, "Dollar: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "Dollar: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
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
    function burnFrom(
        address account,
        uint256 amount
    ) public virtual whenNotPaused onlyAdmin {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
        emit Burning(msg.sender, amount);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view override(ERC20) returns (string memory) {
        return _tokenName;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view override(ERC20) returns (string memory) {
        return _symbol;
    }

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
