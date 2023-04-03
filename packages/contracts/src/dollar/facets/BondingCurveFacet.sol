// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {LibBondingCurve} from "../libraries/LibBondingCurve.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

import {IBondingCurve} from "../../dollar/interfaces/IBondingCurve.sol";
/**
 * @title Bonding Curve
 * @dev Bonding curve contract based on Bancor formula
 * Inspired from Bancor protocol
 * https://github.com/bancorprotocol/contracts
 */
contract BondingCurveFacet is Modifiers, IBondingCurve {

    function setParams(
        uint32 _connectorWeight, 
        uint256 _baseY
    ) external {
        LibBondingCurve.setParams(_connectorWeight, _baseY);
    }

    function connectorWeight() external returns (uint32) {
        return LibBondingCurve.connectorWeight();
    }

    function baseY() external returns (uint256) {
        return LibBondingCurve.baseY();
    }

    function poolBalance() external returns (uint256) {
        return LibBondingCurve.poolBalance();
    }

    /// @notice 
    /// @dev 
    /// @param _collateralDeposited Amount of collateral
    /// @param _recipient An address to receive the NFT
    function deposit(uint256 _collateralDeposited, address _recipient)
        external
    {
        LibBondingCurve.deposit(_collateralDeposited, _recipient);
    }

    function withdraw(uint256 _amount) external whenNotPaused {
        LibBondingCurve.withdraw(_amount);
    }
}
