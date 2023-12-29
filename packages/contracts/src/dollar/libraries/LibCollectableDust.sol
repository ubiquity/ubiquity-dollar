// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {AddressUtils} from "./AddressUtils.sol";
import {UintUtils} from "./UintUtils.sol";
import {LibAppStorage} from "./LibAppStorage.sol";
import "./Constants.sol";

/// @notice Library for collecting dust (i.e. not part of a protocol) tokens sent to a contract
library LibCollectableDust {
    using SafeERC20 for IERC20;
    using AddressUtils for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using UintUtils for uint256;

    /// @notice Emitted when dust tokens are sent to the `_to` address
    event DustSent(address _to, address token, uint256 amount);

    /// @notice Emitted when token is added to a protocol
    event ProtocolTokenAdded(address _token);

    /// @notice Emitted when token is removed from a protocol
    event ProtocolTokenRemoved(address _token);

    /// @notice Struct used as a storage for the current library
    struct Tokens {
        EnumerableSet.AddressSet protocolTokens;
    }

    /// @notice Storage slot used to store data for this library
    bytes32 constant COLLECTABLE_DUST_CONTROL_STORAGE_SLOT =
        bytes32(
            uint256(keccak256("ubiquity.contracts.collectable.dust.storage")) -
                1
        );

    /**
     * @notice Returns struct used as a storage for this library
     * @return l Struct used as a storage
     */
    function collectableDustStorage() internal pure returns (Tokens storage l) {
        bytes32 slot = COLLECTABLE_DUST_CONTROL_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /**
     * @notice Adds token address to a protocol
     * @param _token Token address to add
     */
    function addProtocolToken(address _token) internal {
        require(
            !collectableDustStorage().protocolTokens.contains(_token),
            "collectable-dust::token-is-part-of-the-protocol"
        );
        collectableDustStorage().protocolTokens.add(_token);
        emit ProtocolTokenAdded(_token);
    }

    /**
     * @notice Removes token address from a protocol
     * @param _token Token address to remove
     */
    function removeProtocolToken(address _token) internal {
        require(
            collectableDustStorage().protocolTokens.contains(_token),
            "collectable-dust::token-not-part-of-the-protocol"
        );
        collectableDustStorage().protocolTokens.remove(_token);
        emit ProtocolTokenRemoved(_token);
    }

    /**
     * @notice Sends dust tokens (which are not part of a protocol) to the `_to` address
     * @param _to Tokens receiver address
     * @param _token Token address to send
     * @param _amount Amount of tokens to send
     */
    function sendDust(address _to, address _token, uint256 _amount) internal {
        require(
            _to != address(0),
            "collectable-dust::cant-send-dust-to-zero-address"
        );
        require(
            !collectableDustStorage().protocolTokens.contains(_token),
            "collectable-dust::token-is-part-of-the-protocol"
        );
        if (_token == ETH_ADDRESS) {
            (bool result, ) = _to.call{value: _amount}("");
            require(result, "Failed to send Ether");
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }
        emit DustSent(_to, _token, _amount);
    }
}
