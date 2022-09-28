// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MockDebtCoupon is ERC1155 {
    uint256 private _totalOutstandingDebt;
    uint256 public checkPoint;

    event MintedCoupons(address indexed receiver, uint256 couponsToMint, uint256 expiryBlockNumber);

    //@dev URI param is if we want to add an off-chain meta data uri associated with this contract
    constructor(uint256 totalDebt) ERC1155("URI") {
        _totalOutstandingDebt = totalDebt;
    }

    function setTotalOutstandingDebt(uint256 totalDebt) public {
        _totalOutstandingDebt = totalDebt;
    }

    function getTotalOutstandingDebt() public view returns (uint256) {
        return _totalOutstandingDebt;
    }

    function updateTotalDebt() public {
        checkPoint = block.number;
    }

    function mintCoupons(address receiver, uint256 couponsToMint, uint256 expiryBlockNumber) public {
        emit MintedCoupons(receiver, couponsToMint, expiryBlockNumber);
    }
}
