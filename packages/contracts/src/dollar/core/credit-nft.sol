// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC1155Ubiquity} from "packages/contracts/src/dollar/core/erc-1155-ubiquity.sol";
import "solidity-linked-list/contracts/StructuredLinkedList.sol";
import {ICreditNft} from "../../dollar/interfaces/i-credit-nft.sol";
import "../libraries/constants.sol";

/// @title A CreditNft redeemable for dollars with an expiry block number
/// @notice An ERC1155 where the token ID is the expiry block number
/// @dev Implements ERC1155 so receiving contracts must implement IERC1155Receiver
contract CreditNft is ERC1155Ubiquity, ICreditNft {
    using StructuredLinkedList for StructuredLinkedList.List;

    //not public as if called externally can give inaccurate value. see method
    uint256 private _totalOutstandingDebt;

    //represents tokenSupply of each expiry (since 1155 doesn't have this)
    mapping(uint256 => uint256) private _tokenSupplies;

    //ordered list of CreditNft expiries
    StructuredLinkedList.List private _sortedBlockNumbers;

    event MintedCreditNft(
        address recipient,
        uint256 expiryBlock,
        uint256 amount
    );

    event BurnedCreditNft(
        address creditNftHolder,
        uint256 expiryBlock,
        uint256 amount
    );

    modifier onlyCreditNftManager() {
        require(
            accessCtrl.hasRole(CREDIT_NFT_MANAGER_ROLE, msg.sender),
            "Caller is not a CreditNft manager"
        );
        _;
    }

    //@dev URI param is if we want to add an off-chain meta data uri associated with this contract
    constructor(address _manager) ERC1155Ubiquity(_manager, "URI") {
        _totalOutstandingDebt = 0;
    }

    /// @notice Mint an amount of CreditNfts expiring at a certain block for a certain recipient
    /// @param amount amount of tokens to mint
    /// @param expiryBlockNumber the expiration block number of the CreditNFTs to mint
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

    /// @notice Burn an amount of CreditNfts expiring at a certain block from
    /// a certain holder's balance
    /// @param creditNftOwner the owner of those CreditNFTs
    /// @param amount amount of tokens to burn
    /// @param expiryBlockNumber the expiration block number of the CreditNFTs to burn
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

    /// @notice Should be called prior to any state changing functions.
    // Updates debt according to current block number
    function updateTotalDebt() public {
        bool reachedEndOfExpiredKeys = false;
        uint256 currentBlockNumber = _sortedBlockNumbers.popFront();
        uint256 outstandingDebt = _totalOutstandingDebt;
        uint256 localTotalOutstandingDebt = outstandingDebt;
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
}
