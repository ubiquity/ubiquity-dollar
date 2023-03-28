// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

// import "@openzeppelin/contracts/security/Pausable.sol";
// import "./LibBancorFormula.sol";

import "../interfaces/IERC1155Ubiquity.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {LibAppStorage} from "./LibAppStorage.sol";
import "./LibBancorFormula.sol";
import "./Constants.sol";


library LibBondingCurve {
    using SafeERC20 for IERC20;

    bytes32 constant BONDING_CONTROL_STORAGE_SLOT =
        keccak256("ubiquity.contracts.bonding.storage");

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(uint256 amount);

    struct BondingCurveData {
        uint32 connectorWeight;
        uint256 baseY;
        uint256 poolBalance;
        uint256 tokenIds;
        mapping (address => uint256) share;
    }

    function bondingCurveStorage() internal pure returns (BondingCurveData storage l) {
        bytes32 slot = BONDING_CONTROL_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setParams(
        uint32 _connectorWeight, 
        uint256 _baseY
    ) internal {
        require(_connectorWeight > 0 && _connectorWeight <= 1000000, "invalid values"); 
        require(_baseY > 0, "must valid baseY");

        BondingCurveData storage ss = bondingCurveStorage();

        ss.connectorWeight = _connectorWeight;
        ss.baseY = _baseY;
    }

    function deposit(uint256 _collateralDeposited, address _recipient)
        internal
        returns (uint256 tokensReturned)
    {
        BondingCurveData storage ss = bondingCurveStorage();
        require(
            ss.connectorWeight != 0 && ss.baseY != 0, "not set"
        );

        uint256 tokensReturned;

        if (ss.tokenIds > 0) {
            tokensReturned = LibBancorFormula._purchaseTargetAmount(
                _collateralDeposited,
                ss.connectorWeight,
                ss.tokenIds,
                ss.poolBalance
            );
        } else {
            tokensReturned = LibBancorFormula._purchaseTargetAmountFromZero(
                _collateralDeposited,
                ss.connectorWeight,
                ACCURACY,
                ss.baseY
            );
        }

        IERC20 dollar = IERC20(
            LibAppStorage.appStorage().dollarTokenAddress
        );
        uint256 toTransfer = _collateralDeposited;
        dollar.safeTransfer(
            LibAppStorage.appStorage().treasuryAddress, 
            _collateralDeposited
        );

        ss.poolBalance += _collateralDeposited;
        bytes memory tokReturned = toBytes(tokensReturned);
        ss.share[_recipient] = tokensReturned;

        IERC1155Ubiquity(LibAppStorage.appStorage().ubiquiStickAddress).mint(
           _recipient, 
           ss.tokenIds, 
           tokensReturned, 
           tokReturned 
        );

        emit Deposit(_recipient, _collateralDeposited);

    }

    function toBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }

    function withdraw(uint256 _amount) internal {
        BondingCurveData storage ss = bondingCurveStorage();
        require(_amount <= ss.poolBalance, "invalid amount");

        IERC20 dollar = IERC20(LibAppStorage.appStorage().dollarTokenAddress);
        uint256 toTransfer = _amount;
        dollar.safeTransfer(
            LibAppStorage.appStorage().treasuryAddress,
            _amount
        );

        ss.poolBalance -= _amount;

        emit Withdraw(_amount);
    }
}
