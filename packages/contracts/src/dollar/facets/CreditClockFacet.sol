// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "abdk/ABDKMathQuad.sol";
import "../libraries/Constants.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";
import {LibCreditClock} from "../libraries/LibCreditClock.sol";

/**
 * @notice CreditClock Facet
 */
contract CreditClockFacet is Modifiers {
    /**
     * @notice Updates the manager address
     * @param _manager New manager address
     */
    function setManager(address _manager) external onlyAdmin {
        LibCreditClock.setManager(_manager);
    }

    /**
     * @notice Returns the manager address
     * @return Manager address
     */
    function getManager() external view returns (address) {
        return LibCreditClock.getManager();
    }

    /**
     * @notice Sets rate to apply from this block onward
     * @param _ratePerBlock ABDKMathQuad new rate per block to apply from this block onward
     */
    function setRatePerBlock(bytes16 _ratePerBlock) external onlyAdmin {
        LibCreditClock.setRatePerBlock(_ratePerBlock);
    }

    /**
     * @param blockNumber Block number to get the rate for. 0 for current block.
     */
    function getRate(uint256 blockNumber) external view {
        LibCreditClock.getRate(blockNumber);
    }
}
