// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC1155Ubiquity} from "./ERC1155Ubiquity.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {ICreditNft} from "../../dollar/interfaces/ICreditNft.sol";
import "solidity-linked-list/contracts/StructuredLinkedList.sol";
import "../libraries/Constants.sol";

/**
 * @notice CreditNft redeemable for Dollars with an expiry block number
 * @notice ERC1155 where the token ID is the expiry block number
 * @dev Implements ERC1155 so receiving contracts must implement `IERC1155Receiver`
 * @dev 1 Credit NFT = 1 whole Ubiquity Dollar, not 1 wei
 */
contract CreditNft is ERC1155Ubiquity, ICreditNft {
    using StructuredLinkedList for StructuredLinkedList.List;

    /**
     * @notice Total amount of CreditNfts minted
     * @dev Not public as if called externally can give inaccurate value, see method
     */
    uint256 private _totalOutstandingDebt;

    /// @notice Mapping of block number and amount of CreditNfts to expire on that block number
    mapping(uint256 => uint256) private _tokenSupplies;

    /// @notice Ordered list of CreditNft expiries
    StructuredLinkedList.List private _sortedBlockNumbers;

    /// @notice Emitted on CreditNfts mint
    event MintedCreditNft(
        address recipient,
        uint256 expiryBlock,
        uint256 amount
    );

    /// @notice Emitted on CreditNfts burn
    event BurnedCreditNft(
        address creditNftHolder,
        uint256 expiryBlock,
        uint256 amount
    );

    /// @notice Modifier checks that the method is called by a user with the "CreditNft manager" role
    modifier onlyCreditNftManager() {
        require(
            accessControl.hasRole(CREDIT_NFT_MANAGER_ROLE, _msgSender()),
            "Caller is not a CreditNft manager"
        );
        _;
    }

    /// @notice Ensures initialize cannot be called on the implementation contract
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract
    /// @param _manager Address of the manager of the contract
    function initialize(address _manager) public initializer {
        __ERC1155Ubiquity_init(_manager, "URI");
        _totalOutstandingDebt = 0;
    }

    /**
     * @notice Mint an `amount` of CreditNfts expiring at `expiryBlockNumber` for a certain `recipient`
     * @param recipient Address where to mint tokens
     * @param amount Amount of tokens to mint
     * @param expiryBlockNumber Expiration block number of the CreditNfts to mint
     */
    function mintCreditNft(
        address recipient,
        uint256 amount,
        uint256 expiryBlockNumber
    ) public onlyCreditNftManager {
        mint(recipient, expiryBlockNumber, amount, "");
        emit MintedCreditNft(recipient, expiryBlockNumber, amount);

        //insert new relevant block number if it doesn't exist in our list
        // (linked list implementation won't insert if dupe)
        require(_sortedBlockNumbers.pushBack(expiryBlockNumber));

        //update the total supply for that expiry and total outstanding debt
        _tokenSupplies[expiryBlockNumber] =
            _tokenSupplies[expiryBlockNumber] +
            (amount);
        _totalOutstandingDebt = _totalOutstandingDebt + (amount);
    }

    /**
     * @notice Burns an `amount` of CreditNfts expiring at `expiryBlockNumber` from `creditNftOwner` balance
     * @param creditNftOwner Owner of those CreditNfts
     * @param amount Amount of tokens to burn
     * @param expiryBlockNumber Expiration block number of the CreditNfts to burn
     */
    function burnCreditNft(
        address creditNftOwner,
        uint256 amount,
        uint256 expiryBlockNumber
    ) public onlyCreditNftManager {
        require(
            balanceOf(creditNftOwner, expiryBlockNumber) >= amount,
            "CreditNft owner not enough CreditNfts"
        );
        burn(creditNftOwner, expiryBlockNumber, amount);
        emit BurnedCreditNft(creditNftOwner, expiryBlockNumber, amount);

        //update the total supply for that expiry and total outstanding debt
        _tokenSupplies[expiryBlockNumber] =
            _tokenSupplies[expiryBlockNumber] -
            (amount);
        _totalOutstandingDebt = _totalOutstandingDebt - (amount);
    }

    /**
     * @notice Updates debt according to current block number
     * @notice Invalidates expired CreditNfts
     * @dev Should be called prior to any state changing functions
     */
    function updateTotalDebt() public {
        bool reachedEndOfExpiredKeys = false;
        uint256 currentBlockNumber = _sortedBlockNumbers.popFront();
        uint256 outstandingDebt = _totalOutstandingDebt;
        //if list is empty, currentBlockNumber will be 0
        while (!reachedEndOfExpiredKeys && currentBlockNumber != 0) {
            if (currentBlockNumber > block.number) {
                //put the key back in since we popped, and end loop
                require(_sortedBlockNumbers.pushFront(currentBlockNumber));
                reachedEndOfExpiredKeys = true;
            } else {
                //update tally and remove key from blocks and map
                outstandingDebt =
                    outstandingDebt -
                    (_tokenSupplies[currentBlockNumber]);
                // slither-disable-next-line costly-loop
                delete _tokenSupplies[currentBlockNumber];
                _sortedBlockNumbers.remove(currentBlockNumber);
            }
            currentBlockNumber = _sortedBlockNumbers.popFront();
        }
        _totalOutstandingDebt = outstandingDebt;
    }

    /// @notice Returns outstanding debt by fetching current tally and removing any expired debt
    function getTotalOutstandingDebt() public view returns (uint256) {
        uint256 outstandingDebt = _totalOutstandingDebt;
        bool reachedEndOfExpiredKeys = false;
        (, uint256 currentBlockNumber) = _sortedBlockNumbers.getNextNode(0);

        while (!reachedEndOfExpiredKeys && currentBlockNumber != 0) {
            if (currentBlockNumber > block.number) {
                reachedEndOfExpiredKeys = true;
            } else {
                outstandingDebt =
                    outstandingDebt -
                    (_tokenSupplies[currentBlockNumber]);
            }
            (, currentBlockNumber) = _sortedBlockNumbers.getNextNode(
                currentBlockNumber
            );
        }

        return outstandingDebt;
    }

    /// @notice Allows an admin to upgrade to another implementation contract
    /// @param newImplementation Address of the new implementation contract
    function _authorizeUpgrade(
        address newImplementation
    ) internal override(ERC1155Ubiquity) onlyAdmin {}
}
