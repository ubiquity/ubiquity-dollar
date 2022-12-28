// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../../dollar/StakingShare.sol";
import "../../dollar/libs/ABDKMathQuad.sol";
import "./Constants.sol";

library LibStakingFormulas {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    /* solhint-enable no-unused-vars */

    /// @dev formula to calculate the corrected amount to withdraw based on the proportion of
    ///      lp deposited against actual LP token on the staking contract
    /// @param _totalLpDeposited , Total amount of LP deposited by users
    /// @param _stakingLpBalance , actual staking contract LP tokens balance minus lp rewards
    /// @param _amount , amount of LP tokens
    /// @notice corrected_amount = amount * ( stakingLpBalance / totalLpDeposited)
    ///         if there is more or the same amount of LP than deposited then do nothing
    function correctedAmountToWithdraw(
        uint256 _totalLpDeposited,
        uint256 _stakingLpBalance,
        uint256 _amount
    ) internal pure returns (uint256) {
        if (_stakingLpBalance < _totalLpDeposited && _stakingLpBalance > 0) {
            // if there is less LP token inside the staking contract that what have been deposited
            // we have to reduce proportionally the lp amount to withdraw
            return
                _amount
                    .fromUInt()
                    .mul(_stakingLpBalance.fromUInt())
                    .div(_totalLpDeposited.fromUInt())
                    .toUInt();
        }
        return _amount;
    }

    /// @dev formula Governance Rights corresponding to a staking shares LP amount
    /// @param _stake , staking share
    /// @param _amount , amount of LP tokens
    /// @notice shares = (stake.shares * _amount )  / stake.lpAmount ;
    function sharesForLP(
        StakingShare.Stake memory _stake,
        uint256[2] memory _shareInfo,
        uint256 _amount
    ) internal pure returns (uint256 _uLP) {
        bytes16 a = _shareInfo[0].fromUInt(); // shares amount
        bytes16 v = _amount.fromUInt();
        bytes16 t = _stake.lpAmount.fromUInt();

        _uLP = a.mul(v).div(t).toUInt();
    }

    /// @dev formula may add a decreasing rewards if locking end is near when removing liquidity
    /// @param _stake , staking share
    /// @param _amount , amount of LP tokens
    /// @notice rewards = _amount;
    // solhint-disable-block  no-unused-vars
    /* solhint-disable no-unused-vars */
    function lpRewardsRemoveLiquidityNormalization(
        StakingShare.Stake memory _stake,
        uint256[2] memory _shareInfo,
        uint256 _amount
    ) internal pure returns (uint256) {
        return _amount;
    }

    /* solhint-enable no-unused-vars */
    /// @dev formula may add a decreasing rewards if locking end is near when adding liquidity
    /// @param _stake , staking share
    /// @param _amount , amount of LP tokens
    /// @notice rewards = _amount;
    // solhint-disable-block  no-unused-vars
    /* solhint-disable no-unused-vars */
    function lpRewardsAddLiquidityNormalization(
        StakingShare.Stake memory _stake,
        uint256[2] memory _shareInfo,
        uint256 _amount
    ) internal pure returns (uint256) {
        return _amount;
    }

    /// @dev formula duration multiply
    /// @param _uLP , amount of LP tokens
    /// @param _weeks , minimum duration of staking period
    /// @param _multiplier , staking discount multiplier = 0.0001
    /// @return _shares , amount of shares
    /// @notice _shares = (1 + _multiplier * _weeks^3/2) * _uLP
    //          D32 = D^3/2
    //          S = m * D32 * A + A
    function durationMultiply(
        uint256 _uLP,
        uint256 _weeks,
        uint256 _multiplier
    ) internal pure returns (uint256 _shares) {
        bytes16 unit = uint256(1 ether).fromUInt();
        bytes16 d = _weeks.fromUInt();
        bytes16 d32 = (d.mul(d).mul(d)).sqrt();
        bytes16 m = _multiplier.fromUInt().div(unit); // 0.0001
        bytes16 a = _uLP.fromUInt();

        _shares = m.mul(d32).mul(a).add(a).toUInt();
    }

    /// @dev formula bonding
    /// @param _shares , amount of shares
    /// @param _currentShareValue , current share value
    /// @param _targetPrice , target Ubiquity Dollar price
    /// @return _uBOND , amount of bonding shares
    /// @notice UBOND = _shares / _currentShareValue * _targetPrice
    // newShares = A / V * T
    function bonding(
        uint256 _shares,
        uint256 _currentShareValue,
        uint256 _targetPrice
    ) internal pure returns (uint256 _uBOND) {
        bytes16 a = _shares.fromUInt();
        bytes16 v = _currentShareValue.fromUInt();
        bytes16 t = _targetPrice.fromUInt();

        _uBOND = a.div(v).mul(t).toUInt();
    }

    /// @dev formula redeem bonds
    /// @param _uBOND , amount of bonding shares
    /// @param _currentShareValue , current share value
    /// @param _targetPrice , target uAD price
    /// @return _uLP , amount of LP tokens
    /// @notice _uLP = _uBOND * _currentShareValue / _targetPrice
    // _uLP = A * V / T
    function redeemBonds(
        uint256 _uBOND,
        uint256 _currentShareValue,
        uint256 _targetPrice
    ) internal pure returns (uint256 _uLP) {
        bytes16 a = _uBOND.fromUInt();
        bytes16 v = _currentShareValue.fromUInt();
        bytes16 t = _targetPrice.fromUInt();

        _uLP = a.mul(v).div(t).toUInt();
    }

    /// @dev formula bond price
    /// @param _totalULP , total LP tokens
    /// @param _totalUBOND , total bond shares
    /// @param _targetPrice ,  target Ubiquity Dollar price
    /// @return _priceUBOND , bond share price
    /// @notice
    // IF _totalUBOND = 0  priceBOND = TARGET_PRICE
    // ELSE                priceBOND = totalLP / totalShares * TARGET_PRICE
    // R = T == 0 ? 1 : LP / S
    // P = R * T
    function bondPrice(
        uint256 _totalULP,
        uint256 _totalUBOND,
        uint256 _targetPrice
    ) internal pure returns (uint256 _priceUBOND) {
        bytes16 lp = _totalULP.fromUInt();
        bytes16 s = _totalUBOND.fromUInt();
        bytes16 r = _totalUBOND == 0 ? uint256(1).fromUInt() : lp.div(s);
        bytes16 t = _targetPrice.fromUInt();

        _priceUBOND = r.mul(t).toUInt();
    }

    /// @dev formula Governance Token multiply
    /// @param _multiplier , initial Governance Token min multiplier
    /// @param _price , current share price
    /// @return _newMultiplier , new Governance Token min multiplier
    /// @notice new_multiplier = multiplier * ( 1.05 / (1 + abs( 1 - price ) ) )
    // nM = M * C / A
    // A = ( 1 + abs( 1 - P)))
    // 5 >= multiplier >= 0.2
    function governanceMultiply(uint256 _multiplier, uint256 _price)
        internal
        pure
        returns (uint256 _newMultiplier)
    {
        bytes16 m = _multiplier.fromUInt();
        bytes16 p = _price.fromUInt();
        bytes16 c = uint256(105 * 1e16).fromUInt(); // 1.05
        bytes16 u = uint256(1e18).fromUInt(); // 1
        bytes16 a = u.add(u.sub(p).abs()); // 1 + abs( 1 - P )

        _newMultiplier = m.mul(c).div(a).toUInt(); // nM = M * C / A

        // 5 >= multiplier >= 0.2
        if (_newMultiplier > 5e18 || _newMultiplier < 2e17) {
            _newMultiplier = _multiplier;
        }
    }
}
