// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {LibAppStorage} from "./LibAppStorage.sol";
import "../../ubiquistick/interfaces/IUbiquiStick.sol";
import "../interfaces/IERC1155Ubiquity.sol";
import "./Constants.sol";
import "abdk/ABDKMathQuad.sol";


library LibBondingCurve {
    using SafeERC20 for IERC20;
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    bytes32 constant BONDING_CONTROL_STORAGE_SLOT =
        keccak256("ubiquity.contracts.bonding.storage");

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(uint256 amount);
    event ParamsSet(uint32 connectorWeight, uint256 baseY);

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

        bondingCurveStorage().connectorWeight = _connectorWeight;
        bondingCurveStorage().baseY = _baseY;
        emit ParamsSet(_connectorWeight, _baseY);
    }

    function connectorWeight() internal returns (uint32) {
        return bondingCurveStorage().connectorWeight;
    }

    function baseY() internal returns (uint256) {
        return bondingCurveStorage().baseY;
    }
    
    function poolBalance() internal returns (uint256) {
        return bondingCurveStorage().poolBalance;
    }

    function deposit(uint256 _collateralDeposited, address _recipient)
        internal
    {
        BondingCurveData storage ss = bondingCurveStorage();
        require(
            ss.connectorWeight != 0 && ss.baseY != 0, "not set"
        );

        uint256 tokensReturned;

        if (ss.tokenIds > 0) {
            tokensReturned = purchaseTargetAmount(
                _collateralDeposited,
                ss.connectorWeight,
                ss.tokenIds,
                ss.poolBalance
            );
        } else {
            tokensReturned = purchaseTargetAmountFromZero(
                _collateralDeposited,
                ss.connectorWeight,
                ACCURACY,
                ss.baseY
            );
        }

        IERC20 dollar = IERC20(
            LibAppStorage.appStorage().dollarTokenAddress
        );
        dollar.transferFrom(
            _recipient,
            address(this),
            _collateralDeposited
        );

        ss.poolBalance = ss.poolBalance + _collateralDeposited;
        bytes memory tokReturned = toBytes(tokensReturned);
        ss.share[_recipient] += tokensReturned;
        ss.tokenIds += 1;

        IERC1155Ubiquity bNFT = IERC1155Ubiquity(
            LibAppStorage.appStorage().ubiquiStickAddress
        );
        bNFT.mint(
            _recipient, 
            ss.tokenIds, 
            tokensReturned, 
            tokReturned 
        );

        emit Deposit(_recipient, _collateralDeposited);
    }

    function getShare(address _recipient) internal returns (uint256) {
        BondingCurveData storage ss = bondingCurveStorage();
        return ss.share[_recipient];
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

    /**
     * @dev Given a token supply, reserve balance, weight and a deposit amount (in the reserve token),
     * calculates the target amount for a given conversion (in the main token)
     *
     * @dev _supply * ((1 + _tokensDeposited / _connectorBalance) ^ (_connectorWeight / 1000000) - 1)
     *
     * @param _tokensDeposited   amount of collateral tokens to deposit
     * @param _connectorWeight   connector weight, represented in ppm, 1 - 1,000,000
     * @param _supply          current Token supply
     * @param _connectorBalance   total connector balance
     * 
     * @return amount of Tokens minted
     */
    function purchaseTargetAmount(
        uint256 _tokensDeposited,
        uint32 _connectorWeight,
        uint256 _supply,
        uint256 _connectorBalance
    ) internal view returns(uint256) {

        // validate input
        require(_connectorBalance > 0, "ERR_INVALID_SUPPLY");
        require(_connectorWeight > 0 && _connectorWeight <= MAX_WEIGHT, "ERR_INVALID_WEIGHT");
        
        // special case for 0 deposit amount
        if (_tokensDeposited == 0) {
            return 0;
        }
        // special case if the weight = 100%
        if (_connectorWeight == MAX_WEIGHT) {
            return (_supply * _tokensDeposited) / _connectorBalance;
        }

        bytes16 _one = uintToBytes16(ONE);

        bytes16 exponent = uint256(_connectorWeight).fromUInt().div(
            uint256(MAX_WEIGHT).fromUInt()
        );

        bytes16 connBal = _connectorBalance.fromUInt();
        bytes16 temp = _one.add(
            _tokensDeposited.fromUInt().div(connBal)
        );
        //Instead of calculating "base ^ exp", we calculate "e ^ (log(base) * exp)".
        bytes16 result = _supply.fromUInt().mul(
            (temp.ln().mul(exponent)).exp().sub(_one)
        );
        return result.toUInt();
    }

    /**
     * @notice Given a deposit (in the collateral token) Token supply of 0, calculates the return
     * for a given conversion (in the token)
     *
     * @dev _supply * ((1 + _tokensDeposited / _connectorBalance) ^ (_connectorWeight / 1000000) - 1)
     *
     * @param _tokensDeposited      amount of collateral tokens to deposit
     * @param _connectorWeight      connector weight, represented in ppm, 1 - 1,000,000
     * @param _baseX                constant x
     * @param _baseY                expected price
     * 
     * @return amount of Tokens minted
     */
    function purchaseTargetAmountFromZero(
        uint256 _tokensDeposited,
        uint256 _connectorWeight,
        uint256 _baseX,
        uint256 _baseY
    ) internal view returns (uint256) {
        // (MAX_WEIGHT/reserveWeight -1)
        bytes16 _one = uintToBytes16(ONE);

        bytes16 exponent = uint256(MAX_WEIGHT).fromUInt().div(
            _connectorWeight.fromUInt()
        ).sub(_one);

        // Instead of calculating "x ^ exp", we calculate "e ^ (log(x) * exp)".
        // _baseY ^ (MAX_WEIGHT/reserveWeight -1)
        bytes16 denominator = (_baseY.fromUInt().ln().mul(exponent)).exp();

        // ( baseX * tokensDeposited  ^ (MAX_WEIGHT/reserveWeight -1) ) /  _baseY ^ (MAX_WEIGHT/reserveWeight -1)
        bytes16 res = _tokensDeposited.fromUInt().ln().mul(exponent).exp();
        bytes16 result = _baseX.fromUInt().mul(res).div(denominator);

        return result.toUInt();
    }

    function uintToBytes16(uint256 x) internal pure returns (bytes16 b) {
        require(x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, "Value too large for bytes16");
        b = bytes16(abi.encodePacked(x));
    }
}
