// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LibStabilityPool} from "../libraries/LibStabilityPool.sol";
import {Modifiers} from "../libraries/Modifiers.sol";

contract StabilityPoolFacet is Modifiers {
    function initStabilityPool(
        address _stabilityPool,
        address _lusd,
        address _lqty,
        address _treasury
    ) external onlyOwner {
        LibStabilityPool.init(_stabilityPool, _lusd, _lqty, _treasury);
    }

    function depositToStabilityPool(uint256 _amount) external onlyOwner {
        LibStabilityPool.deposit(_amount);
    }

    function withdrawFromStabilityPool(uint256 _amount) external onlyOwner returns (uint256) {
        return LibStabilityPool.withdraw(_amount);
    }

    function harvestStabilityPoolRewards() external {
        LibStabilityPool.harvest();
    }

    function getStabilityPoolPrincipal() external view returns (uint256) {
        return LibStabilityPool.stabilityPoolStorage().totalPrincipalDeposited;
    }

    function isAutoYieldEnabled() external view returns (bool) {
        return LibStabilityPool.stabilityPoolStorage().isAutoYieldEnabled;
    }
}
