// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../../dollar/interfaces/IIncentive.sol";
import {IERC20Ubiquity} from "../../dollar/interfaces/IERC20Ubiquity.sol";
import "../libraries/LibUbiquityDollarToken.sol";
import "../libraries/LibAccessControl.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";
import {ERC20ForFacet} from "../token/ERC20ForFacet.sol";

/// @title ERC20 Ubiquity preset
/// @author Ubiquity DAO
/// @notice ERC20 with :
/// - ERC20 minter, burner and pauser
/// - draft-ERC20 permit
/// - Ubiquity Manager access control
contract UbiquityDollarTokenFacet is Modifiers, ERC20ForFacet, IERC20Ubiquity {
    event IncentiveContractUpdate(
        address indexed _incentivized,
        address indexed _incentiveContract
    );

    /// @param account the account to incentivize
    /// @param incentive the associated incentive contract
    /// @notice only Ubiquity Dollar manager can set Incentive contract
    function setIncentiveContract(address account, address incentive) external {
        require(
            LibAccessControl.hasRole(GOVERNANCE_TOKEN_MANAGER_ROLE, msg.sender),
            "Dollar: must have admin role"
        );

        LibUbiquityDollarToken.setIncentiveContract(account, incentive);
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) external onlyAdmin {
        // sender must be UbiquityDollarManager roleAdmin
        // because he will get the admin, minter and pauser role on Ubiquity Dollar and we want to
        // manage all permissions through the manager

        LibUbiquityDollarToken.initialize(name_, symbol_, decimals_);
    }

    /// @notice setSymbol update token symbol
    /// @param newSymbol new token symbol
    function setSymbol(string memory newSymbol) external onlyAdmin {
        LibUbiquityDollarToken.setSymbol(newSymbol);
    }

    /// @notice setName update token name
    /// @param newName new token name
    function setName(string memory newName) external onlyAdmin {
        LibUbiquityDollarToken.setName(newName);
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
        bytes32 _s
    ) external {
        LibUbiquityDollarToken.permit(
            owner,
            spender,
            value,
            deadline,
            v,
            r,
            _s
        );
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        LibUbiquityDollarToken.burn(_msgSender(), amount);
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
    function burnFrom(address account, uint256 amount) public virtual {
        LibUbiquityDollarToken.spendAllowance(account, _msgSender(), amount);
        LibUbiquityDollarToken.burn(account, amount);
    }

    // @dev Creates `amount` new tokens for `to`.
    function mint(address to, uint256 amount)
        public
        override
        onlyMinter
        whenNotPaused
    {
        LibUbiquityDollarToken.mint(to, amount);
    }
}
