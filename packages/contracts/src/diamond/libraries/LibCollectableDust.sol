// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EnumerableSet} from "./EnumerableSet.sol";
import {AddressUtils} from "./AddressUtils.sol";
import {UintUtils} from "./UintUtils.sol";
import {LibAppStorage} from "./LibAppStorage.sol";
import "./Constants.sol";

library LibCollectableDust {
    using SafeERC20 for IERC20;
    using AddressUtils for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using UintUtils for uint256;
    event DustSent(address _to, address token, uint256 amount);
    event ProtocolTokenAdded(address _token);
    event ProtocolTokenRemoved(address _token);

    struct Tokens {
        EnumerableSet.AddressSet protocolTokens;
    }
    bytes32 constant COLLECTABLE_DUST_CONTROL_STORAGE_SLOT =
        keccak256("ubiquity.contracts.collectable.dust.storage");

    function collectableDustStorage() internal pure returns (Tokens storage l) {
        bytes32 slot = COLLECTABLE_DUST_CONTROL_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function addProtocolToken(address _token) internal {
        require(
            !collectableDustStorage().protocolTokens.contains(_token),
            "collectable-dust::token-is-part-of-the-protocol"
        );
        collectableDustStorage().protocolTokens.add(_token);
        emit ProtocolTokenAdded(_token);
    }

    function removeProtocolToken(address _token) internal {
        require(
            collectableDustStorage().protocolTokens.contains(_token),
            "collectable-dust::token-not-part-of-the-protocol"
        );
        collectableDustStorage().protocolTokens.remove(_token);
        emit ProtocolTokenRemoved(_token);
    }

    function sendDust(
        address _to,
        address _token,
        uint256 _amount
    ) internal {
        require(
            _to != address(0),
            "collectable-dust::cant-send-dust-to-zero-address"
        );
        require(
            !collectableDustStorage().protocolTokens.contains(_token),
            "collectable-dust::token-is-part-of-the-protocol"
        );
        if (_token == ETH_ADDRESS) {
            payable(_to).transfer(_amount);
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }
        emit DustSent(_to, _token, _amount);
    }
}
