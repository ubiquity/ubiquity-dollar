// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "abdk/ABDKMathQuad.sol";
import {LibAccessControl} from "./LibAccessControl.sol";
import {IAccessControl} from "../interfaces/IAccessControl.sol";
import "../libraries/Constants.sol";

/// @notice Library for Credit Clock Facet
library LibCreditClock {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    /// @notice Emitted when depreciation rate per block is updated
    event SetRatePerBlock(
        uint256 rateStartBlock,
        bytes16 rateStartValue,
        bytes16 ratePerBlock
    );

    /// @notice Storage slot used to store data for this library
    bytes32 constant CREDIT_CLOCK_STORAGE_POSITION =
        bytes32(
            uint256(keccak256("ubiquity.contracts.credit.clock.storage")) - 1
        );

    /// @notice Struct used as a storage for the current library
    struct CreditClockData {
        IAccessControl accessControl;
        uint256 rateStartBlock;
        bytes16 rateStartValue;
        bytes16 ratePerBlock;
        bytes16 one;
    }

    /**
     * @notice Returns struct used as a storage for this library
     * @return data Struct used as a storage
     */
    function creditClockStorage()
        internal
        pure
        returns (CreditClockData storage data)
    {
        bytes32 position = CREDIT_CLOCK_STORAGE_POSITION;
        assembly {
            data.slot := position
        }
    }

    /**
     * @notice Updates the manager address
     * @param _manager New manager address
     */
    function setManager(address _manager) internal {
        creditClockStorage().accessControl = IAccessControl(_manager);
    }

    /**
     * @notice Returns the manager address
     * @return Manager address
     */
    function getManager() internal view returns (address) {
        return address(creditClockStorage().accessControl);
    }

    /**
     * @notice Sets rate to apply from this block onward
     * @param _ratePerBlock ABDKMathQuad new rate per block to apply from this block onward
     */
    function setRatePerBlock(bytes16 _ratePerBlock) internal {
        CreditClockData storage data = creditClockStorage();
        data.rateStartValue = getRate(block.number);
        data.rateStartBlock = block.number;
        data.ratePerBlock = _ratePerBlock;

        emit SetRatePerBlock(
            data.rateStartBlock,
            data.rateStartValue,
            data.ratePerBlock
        );
    }

    /**
     * @notice Calculates `rateStartValue * (1 / ((1 + ratePerBlock)^blockNumber - rateStartBlock)))`
     * @param blockNumber Block number to get the rate for. 0 for current block.
     * @return rate ABDKMathQuad rate calculated for the block number
     */
    function getRate(uint256 blockNumber) internal view returns (bytes16 rate) {
        CreditClockData storage data = creditClockStorage();
        if (blockNumber == 0) {
            blockNumber = block.number;
        } else {
            if (blockNumber < block.number) {
                revert("CreditClock: block number must not be in the past.");
            }
        }
        // slither-disable-next-line divide-before-multiply
        rate = data.rateStartValue.mul(
            data.one.div(
                // b ^ n == 2^(n*log²(b))
                (blockNumber - data.rateStartBlock)
                    .fromUInt()
                    .mul(data.one.add(data.ratePerBlock).log_2())
                    .pow_2()
            )
        );
    }
}
