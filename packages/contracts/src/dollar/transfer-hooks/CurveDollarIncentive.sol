// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../core/TWAPOracleDollar3pool.sol";
import "../core/UbiquityDollarManager.sol";
import "../core/UbiquityDollarToken.sol";
import "../interfaces/IUbiquityGovernance.sol";
import "../interfaces/IIncentive.sol";
import "../libs/ABDKMathQuad.sol";

/// @title Curve trading incentive contract
/// @author Ubiquity DAO
/// @dev incentives
contract CurveDollarIncentive is IIncentive {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    UbiquityDollarManager public manager;
    bool public isSellPenaltyOn = true;
    bool public isBuyIncentiveOn = true;
    bytes16 private immutable _one = (uint256(1 ether)).fromUInt();
    mapping(address => bool) private _exempt;

    event ExemptAddressUpdate(address indexed _account, bool _isExempt);

    modifier onlyAdmin() {
        require(
            manager.hasRole(manager.INCENTIVE_MANAGER_ROLE(), msg.sender),
            "CurveIncentive: not admin"
        );
        _;
    }

    modifier onlyDollar() {
        require(
            msg.sender == manager.dollarTokenAddress(),
            "CurveIncentive: Caller is not Ubiquity Dollar"
        );
        _;
    }

    /// @notice CurveIncentive constructor
    /// @param _manager Ubiquity Dollar Manager
    constructor(address _manager) {
        manager = UbiquityDollarManager(_manager);
    }

    function incentivize(
        address sender,
        address receiver,
        address,
        uint256 amountIn
    ) external override onlyDollar {
        require(sender != receiver, "CurveIncentive: cannot send self");

        if (sender == manager.stableSwapMetaPoolAddress()) {
            _incentivizeBuy(receiver, amountIn);
        }

        if (receiver == manager.stableSwapMetaPoolAddress()) {
            _incentivizeSell(sender, amountIn);
        }
    }

    /// @notice set an address to be exempted from Curve trading incentives
    /// @param account the address to update
    /// @param isExempt a flag for whether to flag as exempt or not
    function setExemptAddress(
        address account,
        bool isExempt
    ) external onlyAdmin {
        _exempt[account] = isExempt;
        emit ExemptAddressUpdate(account, isExempt);
    }

    /// @notice switch the sell penalty
    function switchSellPenalty() external onlyAdmin {
        isSellPenaltyOn = !isSellPenaltyOn;
    }

    /// @notice switch the buy incentive
    function switchBuyIncentive() external onlyAdmin {
        isBuyIncentiveOn = !isBuyIncentiveOn;
    }

    /// @notice returns true if account is marked as exempt
    function isExemptAddress(address account) public view returns (bool) {
        return _exempt[account];
    }

    function _incentivizeSell(address target, uint256 amount) internal {
        _updateOracle();
        if (isExemptAddress(target) || !isSellPenaltyOn) {
            return;
        }

        /*
        WARNING
        From curve doc :Tokens that take a fee upon a successful transfer may cause the curve pool
        to break or act in unexpected ways.
        fei does it differently because they can make sure only one contract has the ability to sell
        Ubiquity Dollar and they control the whole liquidity pool on curve.
        here to avoid problem with the curve pool we execute the transfer as specified and then we
        take the penalty so if penalty + amount > balance then we revert
        swapping Ubiquity Dollar for 3CRV (or underlying) (aka selling Ubiquity Dollar) will burn x% of Ubiquity Dollar
        Where x = (1- TWAP_Price) *100.
        */

        uint256 penalty = _getPercentDeviationFromUnderPeg(amount);
        if (penalty != 0) {
            require(penalty < amount, "Dollar: burn exceeds trade size");

            require(
                UbiquityDollarToken(manager.dollarTokenAddress()).balanceOf(
                    target
                ) >= penalty + amount,
                "Dollar: balance too low to get penalized"
            );
            UbiquityDollarToken(manager.dollarTokenAddress()).burnFrom(
                target,
                penalty
            ); // burn from the recipient
        }
    }

    function _incentivizeBuy(address target, uint256 amountIn) internal {
        _updateOracle();

        if (isExemptAddress(target) || !isBuyIncentiveOn) {
            return;
        }

        uint256 incentive = _getPercentDeviationFromUnderPeg(amountIn);
        /* swapping 3CRV (or underlying) for Ubiquity Dollar (aka buying Ubiquity Dollar) will mint x% of Governance Token.
             Where x = (1- TWAP_Price) * amountIn.
            E.g. Ubiquity Dollar = 0.8, you buy 1000 Ubiquity Dollar, you get (1-0.8)*1000 = 200 Governance Token */

        if (incentive != 0) {
            // this means CurveIncentive should be a minter of Governance Token
            IUbiquityGovernanceToken(manager.governanceTokenAddress()).mint(
                target,
                incentive
            );
        }
    }

    /// @notice returns the percentage of deviation from the peg multiplied by amount
    //          when Ubiquity Dollar is <1$
    function _getPercentDeviationFromUnderPeg(
        uint256 amount
    ) internal returns (uint256) {
        _updateOracle();
        uint256 curPrice = _getTWAPPrice();
        if (curPrice >= 1 ether) {
            return 0;
        }

        uint256 res = _one
            .sub(curPrice.fromUInt())
            .mul((amount.fromUInt().div(_one)))
            .toUInt();
        // returns (1- TWAP_Price) * amount.
        return res;
    }

    function _updateOracle() internal {
        TWAPOracleDollar3pool(manager.twapOracleAddress()).update();
    }

    function _getTWAPPrice() internal view returns (uint256) {
        return
            TWAPOracleDollar3pool(manager.twapOracleAddress()).consult(
                manager.dollarTokenAddress()
            );
    }
}
