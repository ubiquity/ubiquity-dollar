// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// import "@openzeppelin/contracts/utils/address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/utils/i-collectable-dust.sol";

abstract contract CollectableDust is ICollectableDust {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    EnumerableSet.AddressSet internal _protocolTokens;

    // solhint-disable-next-line no-empty-blocks
    constructor() {}

    function _addProtocolToken(address _token) internal {
        require(
            !_protocolTokens.contains(_token),
            "collectable-dust::token-is-part-of-the-protocol"
        );
        require(_protocolTokens.add(_token));
        emit ProtocolTokenAdded(_token);
    }

    function _removeProtocolToken(address _token) internal {
        require(
            _protocolTokens.contains(_token),
            "collectable-dust::token-not-part-of-the-protocol"
        );
        require(_protocolTokens.remove(_token));
        emit ProtocolTokenRemoved(_token);
    }

    function _sendDust(address to, address token, uint256 amount) internal {
        require(
            to != address(0),
            "collectable-dust::cant-send-dust-to-zero-address"
        );
        require(
            !_protocolTokens.contains(token),
            "collectable-dust::token-is-part-of-the-protocol"
        );
        if (token == ETH_ADDRESS) {
            // slither-disable-next-line low-level-calls
            (bool sent, ) = payable(to).call{value: amount}("");
            require(sent, "Failed to transfer Ether");
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
        emit DustSent(to, token, amount);
    }
}
