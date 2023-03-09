// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ERC1155Ubiquity} from "./ERC1155Ubiquity.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../src/dollar/utils/SafeAddArray.sol";
import "../interfaces/IAccessControl.sol";
import "../libraries/Constants.sol";

contract StakingShare is ERC1155Ubiquity {
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
    mapping(address => uint256[]) private _holderBalances;
    mapping(uint256 => Stake) private _stakes;
    uint256 private _totalLP;
    uint256 private _totalSupply;

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
    // TODO should this inherit from ERC1155Ubiquity?
    constructor(
        address _diamond,
        string memory uri
    ) ERC1155Ubiquity(_diamond, uri) {}

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
        id = _totalSupply + 1;
        _mint(to, id, 1, bytes(""));
        _totalSupply += 1;
        _holderBalances[to].add(id);
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
     * @dev Total amount of tokens  .
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
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

    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual override whenNotPaused {
        require(amount == 1, "amount <> 1");
        super._burn(account, id, 1);
        Stake storage _stake = _stakes[id];
        require(_stake.lpAmount == 0, "LP <> 0");
        _totalSupply -= 1;
    }
}
