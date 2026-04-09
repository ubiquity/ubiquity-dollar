// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20Ubiquity} from "../interfaces/IERC20Ubiquity.sol";
import {AppStorage, LibAppStorage} from "./LibAppStorage.sol";

/**
 * @notice Library for governance token emissions to ubq.eth
 * @dev For every 1 governance token minted to stakers, an additional
 *      configurable percentage is minted to ubq.eth
 */
library LibEmission {
    /// @notice Storage slot for emission data
    bytes32 constant EMISSION_STORAGE_POSITION =
        bytes32(uint256(keccak256("ubiquity.contracts.emission.storage")) - 1) &
            ~bytes32(uint256(0xff));

    /// @notice Emission storage struct
    struct EmissionStorage {
        /// @notice Address receiving emission tokens (ubq.eth)
        address emissionReceiver;
        /// @notice Emission rate in basis points (5000 = 50%, i.e. 0.5 tokens per 1 token)
        uint256 emissionRateBps;
        /// @notice Whether emissions are enabled
        bool emissionsEnabled;
    }

    //===========
    // Events
    //===========

    event EmissionReceiverSet(address indexed receiver);
    event EmissionRateSet(uint256 indexed rateBps);
    event EmissionsToggled(bool enabled);
    event EmissionMinted(address indexed receiver, uint256 amount);

    /**
     * @notice Returns emission storage
     */
    function emissionStorage()
        internal
        pure
        returns (EmissionStorage storage es)
    {
        bytes32 position = EMISSION_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }

    /**
     * @notice Mints emission tokens to the receiver
     * @param governanceTokenAmount Amount of governance tokens minted to stakers
     */
    function mintEmission(uint256 governanceTokenAmount) internal {
        EmissionStorage storage es = emissionStorage();
        if (!es.emissionsEnabled || es.emissionRateBps == 0 || governanceTokenAmount == 0) {
            return;
        }

        AppStorage storage store = LibAppStorage.appStorage();
        uint256 emissionAmount = (governanceTokenAmount * es.emissionRateBps) / 10000;

        if (emissionAmount > 0) {
            IERC20Ubiquity(store.governanceTokenAddress).mint(
                es.emissionReceiver,
                emissionAmount
            );
            emit EmissionMinted(es.emissionReceiver, emissionAmount);
        }
    }

    /**
     * @notice Sets the emission receiver address
     * @param receiver New emission receiver address
     */
    function setEmissionReceiver(address receiver) internal {
        emissionStorage().emissionReceiver = receiver;
        emit EmissionReceiverSet(receiver);
    }

    /**
     * @notice Sets the emission rate in basis points
     * @param rateBps Emission rate (5000 = 50%)
     */
    function setEmissionRate(uint256 rateBps) internal {
        require(rateBps <= 10000, "Emission: rate too high");
        emissionStorage().emissionRateBps = rateBps;
        emit EmissionRateSet(rateBps);
    }

    /**
     * @notice Toggles emissions on/off
     * @param enabled Whether emissions are enabled
     */
    function setEmissionsEnabled(bool enabled) internal {
        emissionStorage().emissionsEnabled = enabled;
        emit EmissionsToggled(enabled);
    }

    /**
     * @notice Initializes emission with default ubq.eth address and 50% rate
     */
    function initEmission() internal {
        EmissionStorage storage es = emissionStorage();
        if (es.emissionReceiver == address(0)) {
            // ubq.eth resolved address
            es.emissionReceiver = 0x1eD3fE18BdcF1D0625E3E5C59E35b7e410EEbc56;
            es.emissionRateBps = 5000; // 50%
            es.emissionsEnabled = true;
            emit EmissionReceiverSet(es.emissionReceiver);
            emit EmissionRateSet(es.emissionRateBps);
            emit EmissionsToggled(true);
        }
    }
}
