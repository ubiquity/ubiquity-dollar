// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Modifiers} from "../libraries/LibAppStorage.sol";
import {LibEmission} from "../libraries/LibEmission.sol";

/**
 * @notice Governance token emission facet
 * @dev Allows configuring emissions to ubq.eth when governance tokens are minted to stakers
 */
interface IEmissionFacet {
    event EmissionReceiverSet(address indexed receiver);
    event EmissionRateSet(uint256 indexed rateBps);
    event EmissionsToggled(bool enabled);
    event EmissionMinted(address indexed receiver, uint256 amount);

    function getEmissionReceiver() external view returns (address);
    function getEmissionRate() external view returns (uint256);
    function isEmissionsEnabled() external view returns (bool);
    function setEmissionReceiver(address receiver) external;
    function setEmissionRate(uint256 rateBps) external;
    function setEmissionsEnabled(bool enabled) external;
}

/**
 * @notice Ubiquity governance token emission facet
 */
contract EmissionFacet is IEmissionFacet, Modifiers {
    /// @inheritdoc IEmissionFacet
    function getEmissionReceiver() external view returns (address) {
        return LibEmission.emissionStorage().emissionReceiver;
    }

    /// @inheritdoc IEmissionFacet
    function getEmissionRate() external view returns (uint256) {
        return LibEmission.emissionStorage().emissionRateBps;
    }

    /// @inheritdoc IEmissionFacet
    function isEmissionsEnabled() external view returns (bool) {
        return LibEmission.emissionStorage().emissionsEnabled;
    }

    /// @inheritdoc IEmissionFacet
    function setEmissionReceiver(address receiver) external onlyAdmin {
        LibEmission.setEmissionReceiver(receiver);
    }

    /// @inheritdoc IEmissionFacet
    function setEmissionRate(uint256 rateBps) external onlyAdmin {
        LibEmission.setEmissionRate(rateBps);
    }

    /// @inheritdoc IEmissionFacet
    function setEmissionsEnabled(bool enabled) external onlyAdmin {
        LibEmission.setEmissionsEnabled(enabled);
    }
}
