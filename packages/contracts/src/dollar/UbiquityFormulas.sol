// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "abdk-libraries-solidity/ABDKMathQuad.sol";
import {IUbiquityFormulas} from "./interfaces/IUbiquityFormulas.sol";

contract UbiquityFormulas is IUbiquityFormulas {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    /// @dev formula duration multiply
    /// @param uLP , amount of LP tokens
    /// @param weeks_ , minimum duration of staking period
    /// @param multiplier , staking discount multiplier = 0.0001
    /// @return shares , amount of shares
    /// @notice shares = (1 + multiplier * weeks^3/2) * uLP
    //          D32 = D^3/2
    //          S = m * D32 * A + A
    function durationMultiply(uint256 uLP, uint256 weeks_, uint256 multiplier)
        public
        pure
        returns (uint256 shares)
    {
        bytes16 unit = uint256(1 ether).fromUInt();
        bytes16 d = weeks_.fromUInt();
        bytes16 d32 = (d.mul(d).mul(d)).sqrt();
        ///bytes16 m = multiplier.fromUInt().div(unit); // 0.0001
        bytes16 a = uLP.fromUInt();

        shares = multiplier.fromUInt().mul(d32).mul(a).div(unit).add(a).toUInt();
    }

    /// @dev formula bonding
    /// @param shares , amount of shares
    /// @param currentShareValue , current share value
    /// @param targetPrice , target Ubiquity Dollar price
    /// @return uBOND , amount of bonding shares
    /// @notice UBOND = shares * targetPrice / currentShareValue
    // newShares = A * T / V
    function bonding(
        uint256 shares,
        uint256 currentShareValue,
        uint256 targetPrice
    ) public pure returns (uint256 uBOND) {
        bytes16 a = shares.fromUInt();
        bytes16 v = currentShareValue.fromUInt();
        bytes16 t = targetPrice.fromUInt();

        uBOND = a.mul(t).div(v).toUInt();
    }

    /// @dev formula redeem bonds
    /// @param uBOND , amount of bonding shares
    /// @param currentShareValue , current share value
    /// @param targetPrice , target uAD price
    /// @return uLP , amount of LP tokens
    /// @notice uLP = uBOND * currentShareValue / targetPrice
    // uLP = A * V / T
    function redeemBonds(
        uint256 uBOND,
        uint256 currentShareValue,
        uint256 targetPrice
    ) public pure returns (uint256 uLP) {
        bytes16 a = uBOND.fromUInt();
        bytes16 v = currentShareValue.fromUInt();
        bytes16 t = targetPrice.fromUInt();

        uLP = a.mul(v).div(t).toUInt();
    }

    /// @dev formula bond price
    /// @param totalULP , total LP tokens
    /// @param totalUBOND , total bond shares
    /// @param targetPrice ,  target Ubiquity Dollar price
    /// @return priceUBOND , bond share price
    /// @notice
    // IF totalUBOND = 0  priceBOND = TARGET_PRICE
    // ELSE                priceBOND = totalLP / totalShares * TARGET_PRICE
    // R = T == 0 ? 1 : LP / S
    // P = R * T
    function bondPrice(
        uint256 totalULP,
        uint256 totalUBOND,
        uint256 targetPrice
    ) public pure returns (uint256 priceUBOND) {
        bytes16 lp = totalULP.fromUInt();
        bytes16 s = totalUBOND.fromUInt();
        bytes16 t = targetPrice.fromUInt();
        
        if(totalUBOND == 0){ 
            priceUBOND = uint256(1).fromUInt().mul(t).toUInt();
        } else {
            priceUBOND = lp.mul(t).div(s).toUInt();
        }
    }

    /// @dev formula ugov multiply
    /// @param multiplier , initial ugov min multiplier
    /// @param price , current share price
    /// @return newMultiplier , new ugov min multiplier
    /// @notice newMultiplier = multiplier * ( 1.05 / (1 + abs( 1 - price ) ) )
    // nM = M * C / A
    // A = ( 1 + abs( 1 - P)))
    // 5 >= multiplier >= 0.2
    function ugovMultiply(uint256 multiplier, uint256 price)
        public
        pure
        returns (uint256 newMultiplier)
    {
        bytes16 m = multiplier.fromUInt();
        bytes16 p = price.fromUInt();
        bytes16 c = uint256(105 * 1e16).fromUInt(); // 1.05
        bytes16 u = uint256(1e18).fromUInt(); // 1
        bytes16 a = u.add(u.sub(p).abs()); // 1 + abs( 1 - P )

        newMultiplier = m.mul(c).div(a).toUInt(); // nM = M * C / A

        // 5 >= multiplier >= 0.2
        if (newMultiplier > 5e18 || newMultiplier < 2e17) {
            newMultiplier = multiplier;
        }
    }
}
