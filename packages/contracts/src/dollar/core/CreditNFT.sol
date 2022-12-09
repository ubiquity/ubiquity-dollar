// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "solidity-linked-list/contracts/StructuredLinkedList.sol";
import "../ERC1155Ubiquity.sol";
import "./UbiquityDollarManager.sol";

/// @title A Credit NFT redeemable for dollars with an expiry block number
/// @notice An ERC1155 where the token ID is the expiry block number
/// @dev Implements ERC1155 so receiving contracts must implement IERC1155Receiver
contract CreditNFT is ERC1155Ubiquity {
    using StructuredLinkedList for StructuredLinkedList.List;

    //not public as if called externally can give inaccurate value. see method
    uint256 private _totalOutstandingDebt;

    //represents tokenSupply of each expiry (since 1155 doesn't have this)
    mapping(uint256 => uint256) private _tokenSupplies;

    //ordered list of coupon expiries
    StructuredLinkedList.List private _sortedBlockNumbers;

    event MintedCreditNFT(
        address recipient, uint256 expiryBlock, uint256 amount
    );

    event BurnedCreditNFT(
        address creditNFTHolder, uint256 expiryBlock, uint256 amount
    );

    modifier onlyCreditNFTManager() {
        require(
            manager.hasRole(manager.CREDIT_NFT_MANAGER_ROLE(), msg.sender),
            "Caller is not a Credit NFT manager"
        );
        _;
    }

    //@dev URI param is if we want to add an off-chain meta data uri associated with this contract
    constructor(address _manager) ERC1155Ubiquity(_manager, "URI") {
        manager = UbiquityDollarManager(_manager);
        _totalOutstandingDebt = 0;
    }

    /// @notice Mint an amount of Credit NFT expiring at a certain block for a certain recipient
    /// @param amount amount of tokens to mint
    /// @param expiryBlockNumber the expiration block number of the Credit NFT to mint
    function mintCreditNFT(
        address recipient,
        uint256 amount,
        uint256 expiryBlockNumber
    ) public onlyCreditNFTManager {
        mint(recipient, expiryBlockNumber, amount, "");
        emit MintedCreditNFT(recipient, expiryBlockNumber, amount);

        //insert new relevant block number if it doesn't exist in our list
        // (linked list implementation won't insert if dupe)
        require(_sortedBlockNumbers.pushBack(expiryBlockNumber));

        //update the total supply for that expiry and total outstanding debt
        _tokenSupplies[expiryBlockNumber] =
            _tokenSupplies[expiryBlockNumber] + (amount);
        _totalOutstandingDebt = _totalOutstandingDebt + (amount);
    }

    /// @notice Burn an amount of Credit NFT expiring at a certain block from
    /// a certain holder's balance
    /// @param creditNFTOwner the owner of those Credit NFT
    /// @param amount amount of tokens to burn
    /// @param expiryBlockNumber the expiration block number of the Credit NFT to burn
    function burnCreditNFT(
        address creditNFTOwner,
        uint256 amount,
        uint256 expiryBlockNumber
    ) public onlyCreditNFTManager {
        require(
            balanceOf(creditNFTOwner, expiryBlockNumber) >= amount,
            "Credit NFT owner not enough coupons"
        );
        burn(creditNFTOwner, expiryBlockNumber, amount);
        emit BurnedCreditNFT(creditNFTOwner, expiryBlockNumber, amount);

        //update the total supply for that expiry and total outstanding debt
        _tokenSupplies[expiryBlockNumber] =
            _tokenSupplies[expiryBlockNumber] - (amount);
        _totalOutstandingDebt = _totalOutstandingDebt - (amount);
    }

    /// @notice Should be called prior to any state changing functions.
    // Updates debt according to current block number
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
                    outstandingDebt - (_tokenSupplies[currentBlockNumber]);
                _tokenSupplies[currentBlockNumber] = 0;
                require( currentBlockNumber == _sortedBlockNumbers.remove(currentBlockNumber));
                
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
                    outstandingDebt - (_tokenSupplies[currentBlockNumber]);
            }
            (, currentBlockNumber) =
                _sortedBlockNumbers.getNextNode(currentBlockNumber);
        }

        return outstandingDebt;
    }
}
