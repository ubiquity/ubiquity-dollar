// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @title A Credit NFT which corresponds to a ICreditNFTRedemptionCalculator contract
interface ICreditNFT is IERC1155 {
    function updateTotalDebt() external;

    function burnCreditNFT(
        address creditNFTOwner,
        uint256 amount,
        uint256 expiryBlockNumber
    ) external;

    function mintCreditNFT(
        address recipient,
        uint256 amount,
        uint256 expiryBlockNumber
    ) external;

    function getTotalOutstandingDebt() external view returns (uint256);
}
