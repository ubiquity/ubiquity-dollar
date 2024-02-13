// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/**
 * @notice Wrappers over Solidity's array push operations with added check
 */
library SafeAddArray {
    /**
     * @notice Adds `value` to `array`
     * @param array Array to modify
     * @param value Value to add
     */
    function add(uint256[] storage array, uint256 value) internal {
        // slither-disable-next-line uninitialized-local
        uint256 length = array.length;
        for (uint256 i; i < length;) {
            if (array[i] == value) {
                return;
            }
            unchecked {
                ++i;
            }
        }
        array.push(value);
    }

    /**
     * @notice Adds `values` to `array`
     * @param array Array to modify
     * @param values Array of values to add
     */
    function add(uint256[] storage array, uint256[] memory values) internal {
        // slither-disable-next-line uninitialized-local
        for (uint256 i; i < values.length; ) {
            bool exist;
            for (uint256 j; j < array.length; j++) {
                if (array[j] == values[i]) {
                    exist = true;
                    break;
                }
            }
            if (!exist) {
                array.push(values[i]);
            }
            unchecked {
                ++i;
            }
        }
    }
}
