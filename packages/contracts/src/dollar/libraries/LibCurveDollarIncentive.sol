// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./LibTWAPOracle.sol";
import "../core/UbiquityDollarToken.sol";
import "../interfaces/IUbiquityGovernance.sol";
import "abdk/ABDKMathQuad.sol";
import "./Constants.sol";
import {LibAppStorage} from "./LibAppStorage.sol";

library LibCurveDollarIncentive {
    using SafeERC20 for IERC20;
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    bytes32 constant CURVE_DOLLAR_STORAGE_SLOT =
        bytes32(uint256(keccak256("ubiquity.contracts.curve.storage")) - 1);

    bytes16 constant _one = bytes16(abi.encodePacked(uint256(1 ether)));

    event ExemptAddressUpdate(address indexed _account, bool _isExempt);

    struct CurveDollarData {
        bool isSellPenaltyOn;
        bool isBuyIncentiveOn;
        mapping(address => bool) _exempt;
    }

    function curveDollarStorage()
        internal
        pure
        returns (CurveDollarData storage l)
    {
        bytes32 slot = CURVE_DOLLAR_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function isSellPenaltyOn() internal view returns (bool) {
        CurveDollarData storage ss = curveDollarStorage();
        return ss.isSellPenaltyOn;
    }

    function isBuyIncentiveOn() internal view returns (bool) {
        CurveDollarData storage ss = curveDollarStorage();
        return ss.isBuyIncentiveOn;
    }

    function incentivize(
        address sender,
        address receiver,
        uint256 amountIn
    ) internal {
        require(sender != receiver, "CurveIncentive: cannot send self");

        if (sender == LibAppStorage.appStorage().stableSwapMetaPoolAddress) {
            _incentivizeBuy(receiver, amountIn);
        }

        if (receiver == LibAppStorage.appStorage().stableSwapMetaPoolAddress) {
            _incentivizeSell(sender, amountIn);
        }
    }

    /// @notice set an address to be exempted from Curve trading incentives
    /// @param account the address to update
    /// @param isExempt a flag for whether to flag as exempt or not
    function setExemptAddress(address account, bool isExempt) internal {
        CurveDollarData storage ss = curveDollarStorage();
        ss._exempt[account] = isExempt;
        emit ExemptAddressUpdate(account, isExempt);
    }

    /// @notice switch the sell penalty
    function switchSellPenalty() internal {
        CurveDollarData storage ss = curveDollarStorage();
        ss.isSellPenaltyOn = !ss.isSellPenaltyOn;
    }

    /// @notice switch the buy incentive
    function switchBuyIncentive() internal {
        CurveDollarData storage ss = curveDollarStorage();
        ss.isBuyIncentiveOn = !ss.isBuyIncentiveOn;
    }

    /// @notice returns true if account is marked as exempt
    function isExemptAddress(address account) internal view returns (bool) {
        CurveDollarData storage ss = curveDollarStorage();
        return ss._exempt[account];
    }

    function _incentivizeSell(address target, uint256 amount) internal {
        CurveDollarData storage ss = curveDollarStorage();

        if (isExemptAddress(target) || !ss.isSellPenaltyOn) {
            return;
        }

        // WARNING
        // From curve doc :Tokens that take a fee upon a successful transfer may cause the curve pool
        // to break or act in unexpected ways.
        // fei does it differently because they can make sure only one contract has the ability to sell
        // Ubiquity Dollar and they control the whole liquidity pool on curve.
        // here to avoid problem with the curve pool we execute the transfer as specified and then we
        // take the penalty so if penalty + amount > balance then we revert
        // swapping Ubiquity Dollar for 3CRV (or underlying) (aka selling Ubiquity Dollar) will burn x% of Ubiquity Dollar
        // Where x = (1- TWAP_Price) *100.

        uint256 penalty = _getPercentDeviationFromUnderPeg(amount);
        if (penalty != 0) {
            require(penalty < amount, "Dollar: burn exceeds trade size");

            require(
                UbiquityDollarToken(
                    LibAppStorage.appStorage().dollarTokenAddress
                ).balanceOf(target) >= penalty + amount,
                "Dollar: balance too low to get penalized"
            );
            UbiquityDollarToken(LibAppStorage.appStorage().dollarTokenAddress)
                .burnFrom(target, penalty); // burn from the recipient
        }
        LibTWAPOracle.update();
    }

    function _incentivizeBuy(address target, uint256 amountIn) internal {
        CurveDollarData storage ss = curveDollarStorage();

        if (isExemptAddress(target) || !ss.isBuyIncentiveOn) {
            return;
        }

        uint256 incentive = _getPercentDeviationFromUnderPeg(amountIn);
        // swapping 3CRV (or underlying) for Ubiquity Dollar (aka buying Ubiquity Dollar) will mint x% of Governance Token.
        //  Where x = (1- TWAP_Price) * amountIn.
        // E.g. Ubiquity Dollar = 0.8, you buy 1000 Ubiquity Dollar, you get (1-0.8)*1000 = 200 Governance Token

        if (incentive != 0) {
            // this means CurveIncentive should be a minter of Governance Token
            IUbiquityGovernanceToken(
                LibAppStorage.appStorage().dollarTokenAddress
            ).mint(target, incentive);
        }
        LibTWAPOracle.update();
    }

    /// @notice returns the percentage of deviation from the peg multiplied by amount
    //          when Ubiquity Dollar is <1$
    function _getPercentDeviationFromUnderPeg(
        uint256 amount
    ) internal returns (uint256) {
        uint256 curPrice = _getTWAPPrice();
        if (curPrice >= 1 ether) {
            return 0;
        }

        bytes16 res = _one.sub(curPrice.fromUInt()).mul(amount.fromUInt());
        // returns (1- TWAP_Price) * amount.
        //LibTWAPOracle.update();
        return res.div(_one).toUInt();
    }

    function _getTWAPPrice() internal view returns (uint256) {
        return
            LibTWAPOracle.consult(
                LibAppStorage.appStorage().dollarTokenAddress
            );
    }
}
