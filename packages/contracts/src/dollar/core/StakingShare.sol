// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC1155Ubiquity} from "./ERC1155Ubiquity.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "../../dollar/utils/SafeAddArray.sol";
import "../interfaces/IAccessControl.sol";
import "../libraries/Constants.sol";

contract StakingShare is ERC1155Ubiquity, ERC1155URIStorage {
    using SafeAddArray for uint256[];

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

    // Mapping from account to operator approvals
    mapping(uint256 => Stake) private _stakes;
    uint256 private _totalLP;

    string private _baseURI = "";

    // ----------- Modifiers -----------
    modifier onlyMinter() override {
        require(
            accessCtrl.hasRole(STAKING_SHARE_MINTER_ROLE, msg.sender),
            "Staking Share: not minter"
        );
        _;
    }

    modifier onlyBurner() override {
        require(
            accessCtrl.hasRole(STAKING_SHARE_BURNER_ROLE, msg.sender),
            "Staking Share: not burner"
        );
        _;
    }

    modifier onlyPauser() override {
        require(
            accessCtrl.hasRole(PAUSER_ROLE, msg.sender),
            "Staking Share: not pauser"
        );
        _;
    }

    /**
     * @dev constructor
     */
    constructor(
        address _manager,
        string memory uri
    ) ERC1155Ubiquity(_manager, uri) {}

    /// @dev update stake LP amount , LP rewards debt and end block.
    /// @param _stakeId staking share id
    /// @param _lpAmount amount of LP token deposited
    /// @param _lpRewardDebt amount of excess LP token inside the staking contract
    /// @param _endBlock end locking period block number
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

    // @dev Creates `amount` new tokens for `to`, of token type `id`.
    /// @param to owner address
    /// @param lpDeposited amount of LP token deposited
    /// @param lpRewardDebt amount of excess LP token inside the staking contract
    /// @param endBlock block number when the locking period ends
    function mint(
        address to,
        uint256 lpDeposited,
        uint256 lpRewardDebt,
        uint256 endBlock
    ) public virtual onlyMinter whenNotPaused returns (uint256 id) {
        id = accessTotalSupply() + 1;
        _mint(to, id, 1, bytes(""));
        _incrementTotalSupply();
        addToHolderBalances(to, id);
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
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override(ERC1155, ERC1155Ubiquity) whenNotPaused {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev Total amount of tokens  .
     */
    function totalSupply() public view virtual override returns (uint256) {
        return accessTotalSupply();
    }

    /**
     * @dev Total amount of LP tokens deposited.
     */
    function totalLP() public view virtual returns (uint256) {
        return _totalLP;
    }

    /**
     * @dev return stake details.
     */
    function getStake(uint256 id) public view returns (Stake memory) {
        return _stakes[id];
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override(ERC1155, ERC1155Ubiquity) whenNotPaused {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override(ERC1155, ERC1155Ubiquity) whenNotPaused {
        super._burnBatch(account, ids, amounts);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Ubiquity) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function uri(
        uint256 tokenId
    )
        public
        view
        virtual
        override(ERC1155, ERC1155URIStorage)
        returns (string memory)
    {
        return super.uri(tokenId);
    }

    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual override(ERC1155, ERC1155Ubiquity) whenNotPaused {
        require(amount == 1, "amount <> 1");
        super._burn(account, id, 1);
        Stake storage _stake = _stakes[id];
        require(_stake.lpAmount == 0, "LP <> 0");
        _decrementTotalSupply();
    }

    /**
     * @dev this function is used to allow the staking manage to fix the uri should anything be wrong with the current one.
     */

    function setUri(
        uint256 tokenId,
        string memory tokenUri
    ) external onlyMinter {
        _setURI(tokenId, tokenUri);
    }

    /**
     * @dev this function is used to allow the staking manage to fix the base uri should anything be wrong with the current one.
     */
    function setBaseUri(string memory newUri) external onlyMinter {
        _setBaseURI(newUri);
        _baseURI = newUri;
    }

    function getBaseUri() external view returns (string memory) {
        return _baseURI;
    }
}
