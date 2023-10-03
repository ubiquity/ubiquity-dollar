// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {LibAppStorage} from "./LibAppStorage.sol";
import {UbiquiStick} from "../../ubiquistick/UbiquiStick.sol";
import "../../ubiquistick/interfaces/IUbiquiStick.sol";
import "../interfaces/IERC1155Ubiquity.sol";
import "./Constants.sol";
import "abdk/ABDKMathQuad.sol";

/**
 * @notice Bonding curve library based on Bancor formula
 * @notice Inspired from Bancor protocol https://github.com/bancorprotocol/contracts
 * @notice Used on UbiquiStick NFT minting
 */
library LibBondingCurve {
    using SafeERC20 for IERC20;
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    /// @notice Storage slot used to store data for this library
    bytes32 constant BONDING_CONTROL_STORAGE_SLOT =
        bytes32(uint256(keccak256("ubiquity.contracts.bonding.storage")) - 1);

    /// @notice Emitted when collateral is deposited
    event Deposit(address indexed user, uint256 amount);

    /// @notice Emitted when collateral is withdrawn
    event Withdraw(uint256 amount);

    /// @notice Emitted when parameters are updated
    event ParamsSet(uint32 connectorWeight, uint256 baseY);

    /// @notice Struct used as a storage for the current library
    struct BondingCurveData {
        uint32 connectorWeight;
        uint256 baseY;
        uint256 poolBalance;
        uint256 tokenIds;
        mapping(address => uint256) share;
    }

    /**
     * @notice Returns struct used as a storage for this library
     * @return l Struct used as a storage
     */
    function bondingCurveStorage()
        internal
        pure
        returns (BondingCurveData storage l)
    {
        bytes32 slot = BONDING_CONTROL_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /**
     * @notice Sets bonding curve params
     * @param _connectorWeight Connector weight
     * @param _baseY Base Y
     */
    function setParams(uint32 _connectorWeight, uint256 _baseY) internal {
        require(
            _connectorWeight > 0 && _connectorWeight <= 1000000,
            "invalid values"
        );
        require(_baseY > 0, "must valid baseY");

        bondingCurveStorage().connectorWeight = _connectorWeight;
        bondingCurveStorage().baseY = _baseY;
        emit ParamsSet(_connectorWeight, _baseY);
    }

    /**
     * @notice Returns `connectorWeight` value
     * @return Connector weight value
     */
    function connectorWeight() internal view returns (uint32) {
        return bondingCurveStorage().connectorWeight;
    }

    /**
     * @notice Returns `baseY` value
     * @return Base Y value
     */
    function baseY() internal view returns (uint256) {
        return bondingCurveStorage().baseY;
    }

    /**
     * @notice Returns total balance of deposited collateral
     * @return Amount of deposited collateral
     */
    function poolBalance() internal view returns (uint256) {
        return bondingCurveStorage().poolBalance;
    }

    /**
     * @notice Deposits collateral tokens in exchange for UbiquiStick NFT
     * @param _collateralDeposited Amount of collateral
     * @param _recipient Address to receive the NFT
     */
    function deposit(
        uint256 _collateralDeposited,
        address _recipient
    ) internal {
        BondingCurveData storage ss = bondingCurveStorage();
        require(ss.connectorWeight != 0 && ss.baseY != 0, "not set");

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

        IERC20 dollar = IERC20(LibAppStorage.appStorage().dollarTokenAddress);
        dollar.transferFrom(_recipient, address(this), _collateralDeposited);

        ss.poolBalance = ss.poolBalance + _collateralDeposited;
        ss.share[_recipient] += tokensReturned;
        ss.tokenIds += 1;

        UbiquiStick ubiquiStick = UbiquiStick(
            LibAppStorage.appStorage().ubiquiStickAddress
        );
        ubiquiStick.batchSafeMint(_recipient, tokensReturned);

        emit Deposit(_recipient, _collateralDeposited);
    }

    /**
     * @notice Returns number of NFTs a `_recipient` holds
     * @param _recipient User address
     * @return Amount of NFTs for `_recipient`
     */
    function getShare(address _recipient) internal view returns (uint256) {
        BondingCurveData storage ss = bondingCurveStorage();
        return ss.share[_recipient];
    }

    /**
     * @notice Converts `x` to `bytes`
     * @param x Value to convert to `bytes`
     * @return b `x` value converted to `bytes`
     */
    function toBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }

    /**
     * @notice Withdraws collateral tokens to treasury
     * @param _amount Amount of collateral tokens to withdraw
     */
    function withdraw(uint256 _amount) internal {
        BondingCurveData storage ss = bondingCurveStorage();
        require(_amount <= ss.poolBalance, "invalid amount");

        IERC20 dollar = IERC20(LibAppStorage.appStorage().dollarTokenAddress);
        uint256 toTransfer = _amount;
        dollar.safeTransfer(
            LibAppStorage.appStorage().treasuryAddress,
            toTransfer
        );

        ss.poolBalance -= _amount;

        emit Withdraw(_amount);
    }

    /**
     * @notice Given a token supply, reserve balance, weight and a deposit amount (in the reserve token),
     * calculates the target amount for a given conversion (in the main token)
     *
     * @notice `_supply * ((1 + _tokensDeposited / _connectorBalance) ^ (_connectorWeight / 1000000) - 1)`
     *
     * @param _tokensDeposited Amount of collateral tokens to deposit
     * @param _connectorWeight Connector weight, represented in ppm, 1 - 1,000,000
     * @param _supply Current token supply
     * @param _connectorBalance Total connector balance
     * @return Amount of tokens minted
     */
    function purchaseTargetAmount(
        uint256 _tokensDeposited,
        uint32 _connectorWeight,
        uint256 _supply,
        uint256 _connectorBalance
    ) internal pure returns (uint256) {
        // validate input
        require(_connectorBalance > 0, "ERR_INVALID_SUPPLY");
        require(
            _connectorWeight > 0 && _connectorWeight <= MAX_WEIGHT,
            "ERR_INVALID_WEIGHT"
        );

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
        bytes16 temp = _one.add(_tokensDeposited.fromUInt().div(connBal));
        //Instead of calculating "base ^ exp", we calculate "e ^ (log(base) * exp)".
        bytes16 result = _supply.fromUInt().mul(
            (temp.ln().mul(exponent)).exp().sub(_one)
        );
        return result.toUInt();
    }

    /**
     * @notice Given a deposit (in the collateral token) token supply of 0, calculates the return
     * for a given conversion (in the token)
     *
     * @notice `_supply * ((1 + _tokensDeposited / _connectorBalance) ^ (_connectorWeight / 1000000) - 1)`
     *
     * @param _tokensDeposited Amount of collateral tokens to deposit
     * @param _connectorWeight Connector weight, represented in ppm, 1 - 1,000,000
     * @param _baseX Constant x
     * @param _baseY Expected price
     * @return Amount of tokens minted
     */
    function purchaseTargetAmountFromZero(
        uint256 _tokensDeposited,
        uint256 _connectorWeight,
        uint256 _baseX,
        uint256 _baseY
    ) internal pure returns (uint256) {
        // (MAX_WEIGHT/reserveWeight -1)
        bytes16 _one = uintToBytes16(ONE);

        bytes16 exponent = uint256(MAX_WEIGHT)
            .fromUInt()
            .div(_connectorWeight.fromUInt())
            .sub(_one);

        // Instead of calculating "x ^ exp", we calculate "e ^ (log(x) * exp)".
        // _baseY ^ (MAX_WEIGHT/reserveWeight -1)
        bytes16 denominator = (_baseY.fromUInt().ln().mul(exponent)).exp();

        // ( baseX * tokensDeposited  ^ (MAX_WEIGHT/reserveWeight -1) ) /  _baseY ^ (MAX_WEIGHT/reserveWeight -1)
        bytes16 res = _tokensDeposited.fromUInt().ln().mul(exponent).exp();
        bytes16 result = _baseX.fromUInt().mul(res).div(denominator);

        return result.toUInt();
    }

    /**
     * @notice Converts `x` to `bytes16`
     * @param x Value to convert to `bytes16`
     * @return b `x` value converted to `bytes16`
     */
    function uintToBytes16(uint256 x) internal pure returns (bytes16 b) {
        require(
            x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
            "Value too large for bytes16"
        );
        b = bytes16(abi.encodePacked(x));
    }
}
