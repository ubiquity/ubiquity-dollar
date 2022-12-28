// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../libraries/LibCollectableDust.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

contract CollectableDustFacet is Modifiers {
    /// Collectable Dust
    function addProtocolToken(address _token) external onlyStakingManager {
        LibCollectableDust.addProtocolToken(_token);
    }

    function removeProtocolToken(address _token) external onlyStakingManager {
        LibCollectableDust.removeProtocolToken(_token);
    }

    function sendDust(
        address _to,
        address _token,
        uint256 _amount
    ) external onlyStakingManager {
        LibCollectableDust.sendDust(_to, _token, _amount);
    }
}
