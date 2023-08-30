// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "abdk/ABDKMathQuad.sol";
import {IAccessControl} from "../interfaces/IAccessControl.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";
import {LibCreditClock} from "../libraries/LibCreditClock.sol";
import {ICreditClock} from "../interfaces/ICreditClock.sol";

/**
 * @notice CreditClockFacet contract
 */
contract CreditClockFacet is ICreditClock, Modifiers {
    /**
     * @notice Updates the manager address
     * @param _manager New manager address
     */
    function setManager(address _manager) external override onlyAdmin {
        LibCreditClock.setManager(_manager);
    }

    /**
     * @notice Returns the manager address
     * @return Manager address
     */
    function getManager() external view override returns (address) {
        return LibCreditClock.getManager();
    }

    /**
     * @notice Sets rate to apply from this block onward
     * @param _ratePerBlock ABDKMathQuad new rate per block to apply from this block onward
     */
    function setRatePerBlock(
        bytes16 _ratePerBlock
    ) external override onlyAdmin {
        LibCreditClock.setRatePerBlock(_ratePerBlock);
    }

    /**
     * @notice Calculates `rateStartValue * (1 / ((1 + ratePerBlock)^blockNumber - rateStartBlock)))`
     * @param _blockNumber Block number to get the rate for. 0 for current block.
     * @return rate ABDKMathQuad rate calculated for the block number
     */
    function getRate(
        uint256 _blockNumber
    ) public view override returns (bytes16 rate) {
        return LibCreditClock.getRate(_blockNumber);
    }
}
