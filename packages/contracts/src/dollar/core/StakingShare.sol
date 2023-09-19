// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {ERC1155Ubiquity} from "./ERC1155Ubiquity.sol";
import {ERC1155URIStorageUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../dollar/utils/SafeAddArray.sol";
import "../interfaces/IAccessControl.sol";
import "../libraries/Constants.sol";

/// @notice Contract representing a staking share in the form of ERC1155 token
contract StakingShare is ERC1155Ubiquity, ERC1155URIStorageUpgradeable {
    using SafeAddArray for uint256[];

    /// @notice Stake struct
    struct Stake {
        // address of the minter
        address minter;
        // lp amount deposited by the user
        uint256 lpFirstDeposited;
        uint256 creationBlock;
        // lp that were already there when created
        uint256 lpRewardDebt;
        uint256 endBlock;
        // lp remaining for a user
        uint256 lpAmount;
    }

    /// @notice Mapping of stake id to stake info
    mapping(uint256 => Stake) private _stakes;

    /// @notice Total LP amount staked
    uint256 private _totalLP;

    /// @notice Base token URI
    string private _baseURI;

    // ----------- Modifiers -----------

    /// @notice Modifier checks that the method is called by a user with the "Staking share minter" role
    modifier onlyMinter() override {
        require(
            accessControl.hasRole(STAKING_SHARE_MINTER_ROLE, msg.sender),
            "Staking Share: not minter"
        );
        _;
    }

    /// @notice Modifier checks that the method is called by a user with the "Staking share burner" role
    modifier onlyBurner() override {
        require(
            accessControl.hasRole(STAKING_SHARE_BURNER_ROLE, msg.sender),
            "Staking Share: not burner"
        );
        _;
    }

    /// @notice Modifier checks that the method is called by a user with the "Pauser" role
    modifier onlyPauser() override {
        require(
            accessControl.hasRole(PAUSER_ROLE, msg.sender),
            "Staking Share: not pauser"
        );
        _;
    }

    /// @notice Ensures initialize cannot be called on the implementation contract
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes this contract
    /// @param _manager Address of the manager of the contract
    /// @param _uri Base URI
    function initialize(
        address _manager,
        string memory _uri
    ) public virtual initializer {
        __ERC1155Ubiquity_init(_manager, _uri);
    }

    /**
     * @notice Updates a staking share
     * @param _stakeId Staking share id
     * @param _lpAmount Amount of Dollar-3CRV LP tokens deposited
     * @param _lpRewardDebt Amount of excess LP token inside the staking contract
     * @param _endBlock Block number when the locking period ends
     */
    function updateStake(
        uint256 _stakeId,
        uint256 _lpAmount,
        uint256 _lpRewardDebt,
        uint256 _endBlock
    ) external onlyMinter whenNotPaused {
        Stake storage stake = _stakes[_stakeId];
        uint256 curLpAmount = stake.lpAmount;
        if (curLpAmount > _lpAmount) {
            // we are removing LP
            _totalLP -= curLpAmount - _lpAmount;
        } else {
            // we are adding LP
            _totalLP += _lpAmount - curLpAmount;
        }
        stake.lpAmount = _lpAmount;
        stake.lpRewardDebt = _lpRewardDebt;
        stake.endBlock = _endBlock;
    }

    /**
     * @notice Mints a single staking share token for the `to` address
     * @param to Owner address
     * @param lpDeposited Amount of Dollar-3CRV LP tokens deposited
     * @param lpRewardDebt Amount of excess LP tokens inside the staking contract
     * @param endBlock Block number when the locking period ends
     * @return id Minted staking share id
     */
    function mint(
        address to,
        uint256 lpDeposited,
        uint256 lpRewardDebt,
        uint256 endBlock
    ) public virtual onlyMinter whenNotPaused returns (uint256 id) {
        id = totalSupply + 1;
        _mint(to, id, 1, bytes(""));
        totalSupply += 1;
        holderBalances[to].add(id);
        Stake storage _stake = _stakes[id];
        _stake.minter = to;
        _stake.lpFirstDeposited = lpDeposited;
        _stake.lpAmount = lpDeposited;
        _stake.lpRewardDebt = lpRewardDebt;
        _stake.creationBlock = block.number;
        _stake.endBlock = endBlock;
        _totalLP += lpDeposited;
    }

    /**
     * @notice Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override(ERC1155Upgradeable, ERC1155Ubiquity) whenNotPaused {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @notice Returns total amount of Dollar-3CRV LP tokens deposited
     * @return Total amount of LP tokens deposited
     */
    function totalLP() public view virtual returns (uint256) {
        return _totalLP;
    }

    /**
     * @notice Returns stake info
     * @param id Staking share id
     * @return Staking share info
     */
    function getStake(uint256 id) public view returns (Stake memory) {
        return _stakes[id];
    }

    /// @inheritdoc ERC1155Ubiquity
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override(ERC1155Upgradeable, ERC1155Ubiquity)
        whenNotPaused
    {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /// @inheritdoc ERC1155Ubiquity
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    )
        internal
        virtual
        override(ERC1155Upgradeable, ERC1155Ubiquity)
        whenNotPaused
    {
        super._burnBatch(account, ids, amounts);
    }

    /// @inheritdoc ERC1155Ubiquity
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Upgradeable, ERC1155Ubiquity) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @notice Returns URI by token id
     * @param tokenId Token id
     * @return URI string
     */
    function uri(
        uint256 tokenId
    )
        public
        view
        virtual
        override(ERC1155Upgradeable, ERC1155URIStorageUpgradeable)
        returns (string memory)
    {
        return super.uri(tokenId);
    }

    /// @inheritdoc ERC1155Ubiquity
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    )
        internal
        virtual
        override(ERC1155Upgradeable, ERC1155Ubiquity)
        whenNotPaused
    {
        require(amount == 1, "amount <> 1");
        super._burn(account, id, 1);
        Stake storage _stake = _stakes[id];
        require(_stake.lpAmount == 0, "LP <> 0");
        totalSupply -= 1;
    }

    /**
     * @notice Sets URI for token type `tokenId`
     * @param tokenId Token type id
     * @param tokenUri Token URI
     */
    function setUri(
        uint256 tokenId,
        string memory tokenUri
    ) external onlyMinter {
        _setURI(tokenId, tokenUri);
    }

    /**
     * @notice Sets base URI for all token types
     * @param newUri New URI string
     */
    function setBaseUri(string memory newUri) external onlyMinter {
        _setBaseURI(newUri);
        _baseURI = newUri;
    }

    /**
     * @notice Returns base URI for all token types
     * @return Base URI string
     */
    function getBaseUri() external view returns (string memory) {
        return _baseURI;
    }

    /// @notice Allows an admin to upgrade to another implementation contract
    /// @param newImplementation Address of the new implementation contract
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyAdmin {}
}
