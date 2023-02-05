// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @title A Credit Nft which corresponds to a ICreditNftRedemptionCalculator contract
interface ICreditNft is IERC1155 {
    function updateTotalDebt() external;

    function burnCreditNft(
        address creditNftOwner,
        uint256 amount,
        uint256 expiryBlockNumber
    ) external;

    function mintCreditNft(
        address recipient,
        uint256 amount,
        uint256 expiryBlockNumber
    ) external;

    function getTotalOutstandingDebt() external view returns (uint256);
}
