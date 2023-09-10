// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {UintUtils} from "./UintUtils.sol";

/**
 * @notice Address utils
 * @dev https://github.com/solidstate-network/solidstate-solidity/blob/master/contracts/utils/AddressUtils.sol
 */
library AddressUtils {
    using UintUtils for uint256;

    /// @notice Thrown on insufficient balance
    error AddressUtils__InsufficientBalance();

    /// @notice Thrown when target address has no code
    error AddressUtils__NotContract();

    /// @notice Thrown when sending ETH failed
    error AddressUtils__SendValueFailed();

    /**
     * @notice Converts address to string
     * @param account Address to convert
     * @return String representation of `account`
     */
    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    /**
     * @notice Checks whether `account` has code
     * @dev NOTICE: NOT SAFE, can be circumvented in the `constructor()`
     * @param account Address to check
     * @return Whether `account` has code
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @notice Sends ETH to `account`
     * @param account Address where to send ETH
     * @param amount Amount of ETH to send
     */
    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{value: amount}("");
        if (!success) revert AddressUtils__SendValueFailed();
    }

    /**
     * @notice Calls `target` with `data`
     * @param target Target address
     * @param data Data to pass
     * @return Response bytes
     */
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCall(target, data, "AddressUtils: failed low-level call");
    }

    /**
     * @notice Calls `target` with `data`
     * @param target Target address
     * @param data Data to pass
     * @param error Text error
     * @return Response bytes
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    /**
     * @notice Calls `target` with `data`
     * @param target Target address
     * @param data Data to pass
     * @param value Amount of ETH to send
     * @return Response bytes
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "AddressUtils: failed low-level call with value"
            );
    }

    /**
     * @notice Calls `target` with `data`
     * @param target Target address
     * @param data Data to pass
     * @param value Amount of ETH to send
     * @param error Text error
     * @return Response bytes
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        if (value > address(this).balance) {
            revert AddressUtils__InsufficientBalance();
        }
        return _functionCallWithValue(target, data, value, error);
    }

    /**
     * @notice Calls `target` with `data`
     * @param target Target address
     * @param data Data to pass
     * @param value Amount of ETH to send
     * @param error Text error
     * @return Response bytes
     */
    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        if (!isContract(target)) revert AddressUtils__NotContract();

        (bool success, bytes memory returnData) = target.call{value: value}(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}
