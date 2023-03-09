// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import {ERC20Ubiquity} from "./ERC20Ubiquity.sol";
import {IERC20Ubiquity} from "../../dollar/interfaces/IERC20Ubiquity.sol";
import {IIncentive} from "../../dollar/interfaces/IIncentive.sol";
import "../libraries/Constants.sol";

contract UbiquityDollarToken is ERC20Ubiquity {
    /// @notice get associated incentive contract, 0 address if N/A
    mapping(address => address) public incentiveContract;

    event IncentiveContractUpdate(
        address indexed _incentivized,
        address indexed _incentiveContract
    );

    constructor(
        address _diamond
    )
        // cspell: disable-next-line
        ERC20Ubiquity(_diamond, "Ubiquity Algorithmic Dollar", "uAD")
    {} // solhint-disable-line no-empty-blocks, max-line-length

    // ----------- Modifiers -----------
    modifier onlyDollarMinter() {
        require(
            accessCtrl.hasRole(DOLLAR_TOKEN_MINTER_ROLE, msg.sender),
            "Dollar token: not minter"
        );
        _;
    }

    modifier onlyDollarBurner() {
        require(
            accessCtrl.hasRole(DOLLAR_TOKEN_BURNER_ROLE, msg.sender),
            "Dollar token: not burner"
        );
        _;
    }

    /// @param account the account to incentivize
    /// @param incentive the associated incentive contract
    /// @notice only Ubiquity Dollar manager can set Incentive contract
    function setIncentiveContract(address account, address incentive) external {
        require(
            accessCtrl.hasRole(GOVERNANCE_TOKEN_MANAGER_ROLE, msg.sender),
            "Dollar: must have admin role"
        );

        incentiveContract[account] = incentive;
        emit IncentiveContractUpdate(account, incentive);
    }

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

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        super._transfer(sender, recipient, amount);
        _checkAndApplyIncentives(sender, recipient, amount);
    }

    /// @notice burn Ubiquity Dollar tokens from specified account
    /// @param account the account to burn from
    /// @param amount the amount to burn
    function burnFrom(
        address account,
        uint256 amount
    ) public override onlyDollarBurner whenNotPaused {
        _burn(account, amount);
        emit Burning(account, amount);
    }

    // @dev Creates `amount` new dollar tokens for `to`.
    function mint(
        address to,
        uint256 amount
    ) public override onlyDollarMinter whenNotPaused {
        _mint(to, amount);
        emit Minting(to, msg.sender, amount);
    }
}
