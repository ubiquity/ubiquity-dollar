// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import {PERMIT_TYPEHASH} from "./LibAppStorage.sol";
import "../../dollar/interfaces/IIncentive.sol";

library LibUbiquityDollar {
    struct UbiquityDollarStorage {
        /// @notice get associated incentive contract, 0 address if N/A
        mapping(address => address) incentiveContract;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        mapping(address => uint256) nonces;
        uint256 totalSupply;
        bytes32 DOMAIN_SEPARATOR;
        string name;
        string symbol;
        uint8 decimals;
    }

    bytes32 public constant UBIQUITY_DOLLAR_STORAGE_POSITION =
        keccak256("diamond.standard.ubiquity.dollar.storage");

    // ----------- Events -----------
    event IncentiveContractUpdate(
        address indexed _incentivized,
        address indexed _incentiveContract
    );

    event Minting(
        address indexed _to,
        address indexed _minter,
        uint256 _amount
    );

    event Burning(address indexed _burned, uint256 _amount);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function ubiquityDollarStorage()
        internal
        pure
        returns (UbiquityDollarStorage storage ds)
    {
        bytes32 position = UBIQUITY_DOLLAR_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function initialize(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) internal {
        UbiquityDollarStorage storage us = ubiquityDollarStorage();
        us.name = name;
        us.symbol = symbol;
        us.decimals = decimals;
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }

        us.DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    // solhint-disable-next-line max-line-length
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function setSymbol(string memory newSymbol) internal {
        ubiquityDollarStorage().symbol = newSymbol;
    }

    function setName(string memory newName) internal {
        ubiquityDollarStorage().name = newName;
    }

    function name() internal returns (string memory) {
        return ubiquityDollarStorage().name;
    }

    function symbol() internal returns (string memory) {
        return ubiquityDollarStorage().symbol;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        // solhint-disable-next-line not-rely-on-time
        require(deadline >= block.timestamp, "Dollar: EXPIRED");
        UbiquityDollarStorage storage us = ubiquityDollarStorage();
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                us.DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        us.nonces[owner]++,
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
        approve(owner, spender, value);
    }

    function transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        mapping(address => uint256) storage _balances = ubiquityDollarStorage()
            .balances;

        uint256 fromBalance = _balances[sender];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        unchecked {
            _balances[sender] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[recipient] += amount;
        }
        checkAndApplyIncentives(sender, recipient, amount);
        emit Transfer(sender, recipient, amount);
    }

    function mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        UbiquityDollarStorage storage us = ubiquityDollarStorage();
        us.totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            us.balances[account] += amount;
        }

        emit Minting(account, msg.sender, amount);
    }

    function burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        UbiquityDollarStorage storage us = ubiquityDollarStorage();

        uint256 accountBalance = us.balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            us.balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            us.totalSupply -= amount;
        }

        emit Burning(account, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        spendAllowance(from, msg.sender, amount);
        transfer(from, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        internal
        view
        returns (uint256)
    {
        return ubiquityDollarStorage().allowances[owner][spender];
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(
        address owner,
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(
        address owner,
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        ubiquityDollarStorage().allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setIncentiveContract(address account, address incentive) internal {
        ubiquityDollarStorage().incentiveContract[account] = incentive;
        emit IncentiveContractUpdate(account, incentive);
    }

    function checkAndApplyIncentives(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        UbiquityDollarStorage storage us = ubiquityDollarStorage();
        // incentive on sender
        address senderIncentive = us.incentiveContract[sender];
        if (senderIncentive != address(0)) {
            IIncentive(senderIncentive).incentivize(
                sender,
                recipient,
                msg.sender,
                amount
            );
        }

        // incentive on recipient
        address recipientIncentive = us.incentiveContract[recipient];
        if (recipientIncentive != address(0)) {
            IIncentive(recipientIncentive).incentivize(
                sender,
                recipient,
                msg.sender,
                amount
            );
        }

        // incentive on operator
        address operatorIncentive = us.incentiveContract[msg.sender];
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
        address allIncentive = us.incentiveContract[address(0)];
        if (allIncentive != address(0)) {
            IIncentive(allIncentive).incentivize(
                sender,
                recipient,
                msg.sender,
                amount
            );
        }
    }
}
