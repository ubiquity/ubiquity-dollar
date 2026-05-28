// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {ERC1155BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import {ERC1155PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IAccessControl.sol";
import "../libraries/Constants.sol";

import "../../../src/dollar/utils/SafeAddArray.sol";

/**
 * @notice ERC1155 Ubiquity preset
 * @notice ERC1155 with:
 * - ERC1155 minter, burner and pauser
 * - TotalSupply per id
 * - Ubiquity Manager access control
 */
abstract contract ERC1155Ubiquity is
    Initializable,
    ERC1155BurnableUpgradeable,
    ERC1155PausableUpgradeable,
    UUPSUpgradeable
{
    using SafeAddArray for uint256[];

    /// @notice Access control interface
    IAccessControl public accessControl;

    /// @notice Mapping from account to array of token ids held by the account
    mapping(address => uint256[]) public holderBalances;

    /// @notice Total supply among all token ids
    uint256 public totalSupply;

    // ----------- Modifiers -----------

    /// @notice Modifier checks that the method is called by a user with the "Governance minter" role
    modifier onlyMinter() virtual {
        require(
            accessControl.hasRole(GOVERNANCE_TOKEN_MINTER_ROLE, _msgSender()),
            "ERC1155Ubiquity: not minter"
        );
        _;
    }

    /// @notice Modifier checks that the method is called by a user with the "Governance burner" role
    modifier onlyBurner() virtual {
        require(
            accessControl.hasRole(GOVERNANCE_TOKEN_BURNER_ROLE, _msgSender()),
            "ERC1155Ubiquity: not burner"
        );
        _;
    }

    /// @notice Modifier checks that the method is called by a user with the "Pauser" role
    modifier onlyPauser() virtual {
        require(
            accessControl.hasRole(PAUSER_ROLE, _msgSender()),
            "ERC1155Ubiquity: not pauser"
        );
        _;
    }

    /// @notice Modifier checks that the method is called by a user with the "Admin" role
    modifier onlyAdmin() {
        require(
            accessControl.hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "ERC20Ubiquity: not admin"
        );
        _;
    }

    /// @notice Ensures __ERC1155Ubiquity_init cannot be called on the implementation contract
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes this contract with all base(parent) contracts
    /// @param _manager Address of the manager of the contract
    /// @param _uri Base URI
    function __ERC1155Ubiquity_init(
        address _manager,
        string memory _uri
    ) internal onlyInitializing {
        // init base contracts
        __ERC1155_init(_uri);
        __ERC1155Burnable_init();
        __ERC1155Pausable_init();
        __UUPSUpgradeable_init();
        // init current contract
        __ERC1155Ubiquity_init_unchained(_manager);
    }

    /// @notice Initializes the current contract
    /// @param _manager Address of the manager of the contract
    function __ERC1155Ubiquity_init_unchained(
        address _manager
    ) internal onlyInitializing {
        accessControl = IAccessControl(_manager);
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

    /**
     * @notice Sets base URI
     * @param newURI New URI
     */
    function setUri(string memory newURI) external onlyAdmin {
        _setURI(newURI);
    }

    /**
     * @notice Creates `amount` new tokens for `to`, of token type `id`
     * @param to Address where to mint tokens
     * @param id Token type id
     * @param amount Tokens amount to mint
     * @param data Arbitrary data
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual onlyMinter {
        _mint(to, id, amount, data);
        totalSupply += amount;
        holderBalances[to].add(id);
    }

    /**
     * @notice Mints multiple token types for `to` address
     * @param to Address where to mint tokens
     * @param ids Array of token type ids
     * @param amounts Array of token amounts
     * @param data Arbitrary data
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual onlyMinter whenNotPaused {
        _mintBatch(to, ids, amounts, data);
        uint256 localTotalSupply = totalSupply;
        for (uint256 i = 0; i < ids.length; ++i) {
            localTotalSupply += amounts[i];
        }
        totalSupply = localTotalSupply;
        holderBalances[to].add(ids);
    }

    /// @notice Pauses all token transfers
    function pause() public virtual onlyPauser {
        _pause();
    }

    /// @notice Unpauses all token transfers
    function unpause() public virtual onlyPauser {
        _unpause();
    }

    /**
     * @notice Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a `TransferSingle` event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via `setApprovalForAll`.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement `IERC1155Receiver-onERC1155Received` and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        super.safeTransferFrom(from, to, id, amount, data);
        holderBalances[to].add(id);
    }

    /**
     * @notice Batched version of `safeTransferFrom()`
     *
     * Emits a `TransferBatch` event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement `IERC1155Receiver-onERC1155BatchReceived` and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
        holderBalances[to].add(ids);
    }

    /**
     * @notice Returns array of token ids held by the `holder`
     * @param holder Account to check tokens for
     * @return Array of tokens which `holder` has
     */
    function holderTokens(
        address holder
    ) public view returns (uint256[] memory) {
        return holderBalances[holder];
    }

    /**
     * @notice Destroys `amount` tokens of token type `id` from `account`
     *
     * Emits a `TransferSingle` event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual override whenNotPaused {
        super._burn(account, id, amount);
        totalSupply -= amount;
    }

    /**
     * @notice Batched version of `_burn()`
     *
     * Emits a `TransferBatch` event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override whenNotPaused {
        super._burnBatch(account, ids, amounts);
        for (uint256 i = 0; i < ids.length; ++i) {
            totalSupply -= amounts[i];
        }
    }

    /**
     * @notice Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
        override(ERC1155PausableUpgradeable, ERC1155Upgradeable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /// @notice Allows an admin to upgrade to another implementation contract
    /// @param newImplementation Address of the new implementation contract
    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyAdmin {}

    /// @notice Allows for future upgrades on the base contract without affecting the storage of the derived contract
    uint256[50] private __gap;
}
