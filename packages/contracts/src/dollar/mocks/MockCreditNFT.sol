// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MockCreditNFT is ERC1155 {
    uint256 private _totalOutstandingDebt;
    uint256 public checkPoint;
    mapping(address => mapping(uint256 => uint256)) _balances;

    event MintedCreditNFT(
        address recipient,
        uint256 expiryBlock,
        uint256 amount
    );

    event BurnedCreditNFT(
        address creditNFTHolder,
        uint256 expiryBlock,
        uint256 amount
    );

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

    function mintCreditNFT(
        address receiver,
        uint256 amount,
        uint256 expiryBlockNumber
    ) public {
        _balances[receiver][expiryBlockNumber] =
            _balances[receiver][expiryBlockNumber] +
            amount;
        emit MintedCreditNFT(receiver, expiryBlockNumber, amount);
    }

    function balanceOf(
        address receiver,
        uint256 id
    ) public view override returns (uint256) {
        return _balances[receiver][id];
    }

    function burnCreditNFT(
        address creditNFTOwner,
        uint256 amount,
        uint256 expiryBlockNumber
    ) public {
        uint256 _balance = _balances[creditNFTOwner][expiryBlockNumber];
        require(_balance >= amount, "Insufficient balance");
        _balances[creditNFTOwner][expiryBlockNumber] = _balance - amount;
        emit BurnedCreditNFT(creditNFTOwner, expiryBlockNumber, amount);
    }
}
