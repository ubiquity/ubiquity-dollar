// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {LibBondingCurve} from "../libraries/LibBondingCurve.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

/**
 * @title Bonding Curve
 * @dev Bonding curve contract based on Bancor formula
 * Inspired from Bancor protocol
 * https://github.com/bancorprotocol/contracts
 */
contract BondingCurveFacet is Modifiers {

    function setParams(
        uint32 _connectorWeight, 
        uint256 _baseY
    ) external onlyMinter {
        LibBondingCurve.setParams(_connectorWeight, _baseY);
    }

    /// @notice 
    /// @dev 
    /// @param _collateralDeposited Amount of collateral
    /// @param _recipient An address to receive the NFT
    /// @return Tokens minted
    function deposit(uint256 _collateralDeposited, address _recipient)
        external
        whenNotPaused
        returns (uint256)
    {
        LibBondingCurve.deposit(_collateralDeposited, _recipient);
    }

    function withdraw(uint256 _amount) external onlyMinter whenNotPaused {
        LibBondingCurve.withdraw(_amount);
    }
}
