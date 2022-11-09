// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

/**
 * @dev Wrappers over Solidity's array push operations with added check
 *
 */
library SafeAddArray {
    function add(uint256[] storage array, uint256 value) internal {
        for (uint256 i; i < array.length; i++) {
            if (array[i] == value) {
                return;
            }
        }
        array.push(value);
    }

    function add(uint256[] storage array, uint256[] memory values) internal {
        for (uint256 i; i < values.length; i++) {
            bool exist = false;
            for (uint256 j; j < array.length; j++) {
                if (array[j] == values[i]) {
                    exist = true;
                    break;
                }
            }
            if (!exist) {
                array.push(values[i]);
            }
        }
    }
}
