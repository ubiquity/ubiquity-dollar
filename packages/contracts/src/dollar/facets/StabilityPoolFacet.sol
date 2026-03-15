// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import {IStabilityPoolFacet} from "../interfaces/IStabilityPoolFacet.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";
import {LibStabilityPool} from "../libraries/LibStabilityPool.sol";

/**
 * @notice Stability Pool facet
 * @notice Manages LUSD deposits into the Liquity V1 Stability Pool,
 *         enabling ~6.28% APR yield generation on protocol-held LUSD collateral.
 *         Operations are piggybacked on user mint/redeem transactions for gas efficiency.
 *
 * @dev Deposit flow (on mint):
 *      1. User mints Ubiquity Dollars depositing LUSD collateral
 *      2. Diamond calls depositToStabilityPool() with the received LUSD
 *      3. LUSD is forwarded to Liquity Stability Pool via provideToSP()
 *
 * @dev Withdraw flow (on redeem):
 *      1. User redeems Ubiquity Dollars for LUSD collateral
 *      2. Diamond calls withdrawFromStabilityPool() for the required LUSD
 *      3. LUSD is pulled from Liquity Stability Pool via withdrawFromSP()
 *      4. ETH/LQTY gains are automatically harvested and sent to treasury
 *
 * @dev Harvest flow (standalone or piggybacked):
 *      1. Calls withdrawFromSP(0) to trigger gain collection
 *      2. ETH gains from liquidation absorptions are forwarded to treasury
 *      3. LQTY rewards are forwarded to treasury for buyback/compounding
 */
contract StabilityPoolFacet is IStabilityPoolFacet, Modifiers {
    //=====================
    // Views
    //=====================

    /// @inheritdoc IStabilityPoolFacet
    function getPoolBalance() external view returns (uint256) {
        return LibStabilityPool.getPoolBalance();
    }

    /// @inheritdoc IStabilityPoolFacet
    function getTotalPrincipal() external view returns (uint256) {
        return LibStabilityPool.getTotalPrincipal();
    }

    /// @inheritdoc IStabilityPoolFacet
    function getETHGain() external view returns (uint256) {
        return LibStabilityPool.getETHGain();
    }

    /// @inheritdoc IStabilityPoolFacet
    function getLQTYGain() external view returns (uint256) {
        return LibStabilityPool.getLQTYGain();
    }

    //====================
    // Public functions
    //====================

    /// @inheritdoc IStabilityPoolFacet
    function depositToStabilityPool(
        uint256 amount
    ) external nonReentrant onlyAdmin {
        LibStabilityPool.depositToPool(amount);
    }

    /// @inheritdoc IStabilityPoolFacet
    function withdrawFromStabilityPool(
        uint256 amount
    ) external nonReentrant onlyAdmin {
        LibStabilityPool.withdrawFromPool(amount);
    }

    /// @inheritdoc IStabilityPoolFacet
    function harvestGains() external nonReentrant onlyAdmin {
        LibStabilityPool.harvestGains();
    }

    //========================
    // Restricted functions
    //========================

    /// @inheritdoc IStabilityPoolFacet
    function setStabilityPoolAddress(
        address stabilityPool
    ) external onlyAdmin {
        LibStabilityPool.setStabilityPoolAddress(stabilityPool);
    }

    /// @inheritdoc IStabilityPoolFacet
    function setLusdTokenAddress(address lusdToken) external onlyAdmin {
        LibStabilityPool.setLusdTokenAddress(lusdToken);
    }

    /// @inheritdoc IStabilityPoolFacet
    function setLqtyTokenAddress(address lqtyToken) external onlyAdmin {
        LibStabilityPool.setLqtyTokenAddress(lqtyToken);
    }

    /// @inheritdoc IStabilityPoolFacet
    function setProtocolTreasury(address treasury) external onlyAdmin {
        LibStabilityPool.setProtocolTreasury(treasury);
    }

    /// @inheritdoc IStabilityPoolFacet
    function setFrontEndTag(address frontEndTag) external onlyAdmin {
        LibStabilityPool.setFrontEndTag(frontEndTag);
    }

    /// @notice Required to receive ETH gains from the Stability Pool
    receive() external payable {}
}
