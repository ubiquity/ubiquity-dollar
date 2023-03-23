// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {LibBondingCurve} from "../libraries/LibBondingCurve.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

import {IStaking} from "../../dollar/interfaces/IStaking.sol";

/**
 * @title Bonding Curve
 * @dev Bonding curve contract based on Bancor formula
 * Inspired from Bancor protocol
 * https://github.com/bancorprotocol/contracts
 */
contract BondingCurve is Modifiers {

    /// @notice 
    /// @dev 
    /// @param _collateral Collateral address
    /// @return Tokens minted
    function setCollateralToken(address _collateral) external onlyBondingMinter {
        LibBondingCurve.setCollateralToken(_collateral);
    }

    function setParams(
        uint32 _connectorWeight, 
        uint256 _baseY
    ) external onlyBondingMinter {
        LibBondingCurve.setParams(_connectorWeight, _baseY);
    }

    function setTreasuryAddress() external onlyBondingMinter {
        LibBondingCurve.setTreasuryAddress();
    }

    /// @notice 
    /// @dev 
    /// @param _collateralDeposited Amount of collateral
    /// @param _recipient An address to receive the NFT
    /// @return Tokens minted
    function deposit(uint256 _collateralDeposited, address _recipient)
        external
        onlyParamsSet
        whenNotPaused
        returns (uint256)
    {
        LibBondingCurve.deposit(_collateralDeposited, _recipient);
    }

    function withdraw(uint256 _amount) external onlyBondingMinter whenNotPaused {
        LibBondingCurve.withdraw(_amount);
    }
}
