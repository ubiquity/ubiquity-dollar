// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../libraries/LibCollectableDust.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";
import {ICollectableDust} from "../../dollar/interfaces/utils/ICollectableDust.sol";

/// @notice Contract for collecting dust (i.e. not part of a protocol) tokens sent to a contract
contract CollectableDustFacet is ICollectableDust, Modifiers {
    /// @inheritdoc ICollectableDust
    function addProtocolToken(address _token) external onlyStakingManager {
        LibCollectableDust.addProtocolToken(_token);
    }

    /// @inheritdoc ICollectableDust
    function removeProtocolToken(address _token) external onlyStakingManager {
        LibCollectableDust.removeProtocolToken(_token);
    }

    /// @inheritdoc ICollectableDust
    function sendDust(
        address _to,
        address _token,
        uint256 _amount
    ) external onlyStakingManager {
        LibCollectableDust.sendDust(_to, _token, _amount);
    }
}
