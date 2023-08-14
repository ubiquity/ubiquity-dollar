// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {ERC20Ubiquity} from "./ERC20Ubiquity.sol";
import {IERC20Ubiquity} from "../../dollar/interfaces/IERC20Ubiquity.sol";
import {IIncentive} from "../../dollar/interfaces/IIncentive.sol";
import "../libraries/Constants.sol";

/**
 * @notice Ubiquity Dollar token contract
 */
contract UbiquityDollarToken is ERC20Ubiquity {
    /**
     * @notice Mapping of account and incentive contract address
     * @dev Address is 0 if there is no incentive contract for the account
     */
    mapping(address => address) public incentiveContract;

    /// @notice Emitted on setting an incentive contract for an account
    event IncentiveContractUpdate(
        address indexed _incentivized,
        address indexed _incentiveContract
    );

    /**
     * @notice Contract constructor
     * @param _manager Access control address
     */
    constructor(
        address _manager
    )
        // cspell: disable-next-line
        ERC20Ubiquity(_manager, "Ubiquity Dollar", "uAD")
    {} // solhint-disable-line no-empty-blocks, max-line-length

    // ----------- Modifiers -----------

    /// @notice Modifier checks that the method is called by a user with the "Dollar minter" role
    modifier onlyDollarMinter() {
        require(
            accessControl.hasRole(DOLLAR_TOKEN_MINTER_ROLE, msg.sender),
            "Dollar token: not minter"
        );
        _;
    }

    /// @notice Modifier checks that the method is called by a user with the "Dollar burner" role
    modifier onlyDollarBurner() {
        require(
            accessControl.hasRole(DOLLAR_TOKEN_BURNER_ROLE, msg.sender),
            "Dollar token: not burner"
        );
        _;
    }

    /**
     * @notice Sets `incentive` contract for `account`
     * @notice Incentive contracts are applied on Dollar transfers:
     * - EOA => contract
     * - contract => EOA
     * - contract => contract
     * - any transfer global incentive
     * @param account Account to incentivize
     * @param incentive Incentive contract address
     */
    function setIncentiveContract(address account, address incentive) external {
        require(
            accessControl.hasRole(GOVERNANCE_TOKEN_MANAGER_ROLE, msg.sender),
            "Dollar: must have admin role"
        );

        incentiveContract[account] = incentive;
        emit IncentiveContractUpdate(account, incentive);
    }

    /**
     * @notice Applies incentives on Dollar transfers
     * @param sender Sender address
     * @param recipient Recipient address
     * @param amount Dollar token transfer amount
     */
    function _checkAndApplyIncentives(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        // incentive on sender
        address senderIncentive = incentiveContract[sender];
        if (senderIncentive != address(0)) {
            IIncentive(senderIncentive).incentivize(
                sender,
                recipient,
                msg.sender,
                amount
            );
        }

        // incentive on recipient
        address recipientIncentive = incentiveContract[recipient];
        if (recipientIncentive != address(0)) {
            IIncentive(recipientIncentive).incentivize(
                sender,
                recipient,
                msg.sender,
                amount
            );
        }

        // incentive on operator
        address operatorIncentive = incentiveContract[msg.sender];
        if (
            msg.sender != sender &&
            msg.sender != recipient &&
            operatorIncentive != address(0)
        ) {
            IIncentive(operatorIncentive).incentivize(
                sender,
                recipient,
                msg.sender,
                amount
            );
        }

        // all incentive, if active applies to every transfer
        address allIncentive = incentiveContract[address(0)];
        if (allIncentive != address(0)) {
            IIncentive(allIncentive).incentivize(
                sender,
                recipient,
                msg.sender,
                amount
            );
        }
    }

    /**
     * @notice Moves `amount` of tokens from `from` to `to` and applies incentives.
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
    ) internal override {
        super._transfer(sender, recipient, amount);
        _checkAndApplyIncentives(sender, recipient, amount);
    }

    /**
     * @notice Burns Dollars from the `account` address
     * @param account Address to burn tokens from
     * @param amount Amount of tokens to burn
     */
    function burnFrom(
        address account,
        uint256 amount
    ) public override onlyDollarBurner whenNotPaused {
        _burn(account, amount);
        emit Burning(account, amount);
    }

    /**
     * @notice Mints Dollars to the `to` address
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     */
    function mint(
        address to,
        uint256 amount
    ) public override onlyDollarMinter whenNotPaused {
        _mint(to, amount);
        emit Minting(to, msg.sender, amount);
    }
}
