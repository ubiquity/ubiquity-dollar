// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LibAppStorage} from "./LibAppStorage.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

// import {IBondingCurve} from "../../dollar/interfaces/IBondingCurve.sol";

/**
 * @notice Bonding curve library based on Bancor formula
 * @notice Inspired from Bancor protocol https://github.com/bancorprotocol/contracts
 * @notice Used on UbiquiStick NFT minting
 */
library LibUbiquityAMOPool {
    bytes32 constant AMOPOOL_CONTROL_STORAGE_SLOT =
        bytes32(uint256(keccak256("ubiquity.contracts.amopool.storage")) - 1);

    event CollateralToggled(uint256 col_idx, bool new_state);
    event PoolCeilingSet(uint256 col_idx, uint256 new_ceiling);
    event FeesSet(
        uint256 col_idx,
        uint256 new_mint_fee,
        uint256 new_redeem_fee,
        uint256 new_buyback_fee,
        uint256 new_recollat_fee
    );
    event PoolParametersSet(
        uint256 new_bonus_rate,
        uint256 new_redemption_delay
    );
    event PriceThresholdsSet(
        uint256 new_bonus_rate,
        uint256 new_redemption_delay
    );
    event BbkRctPerHourSet(
        uint256 bbkMaxColE18OutPerHour,
        uint256 rctMaxFxsOutPerHour
    );
    event AMOMinterAdded(address amo_minter_addr);
    event AMOMinterRemoved(address amo_minter_addr);
    event OraclesSet(
        address frax_usd_chainlink_addr,
        address fxs_usd_chainlink_addr
    );
    event CustodianSet(address new_custodian);
    event TimelockSet(address new_timelock);
    event Toggled(uint256 col_idx, uint8 tog_idx);
    event CollateralPriceSet(uint256 col_idx, uint256 new_price);

    struct AmoPoolData {
        address[] collateral_addresses;
        mapping(address => bool) enabled_collaterals;
    }

    /**
     * @notice Returns struct used as a storage for this library
     * @return l Struct used as a storage
     */
    function amoPoolStorage() internal pure returns (AmoPoolData storage l) {
        bytes32 slot = AMOPOOL_CONTROL_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    // function collateral_information(
    //     address _collateral_address
    // ) internal view returns (CollateralInformation memory return_data) {
    //     require(enabled_collaterals[collat_address], "Invalid collateral");

    //     // Get the index
    //     uint256 idx = collateralAddrToIdx[collat_address];

    //     return_data = CollateralInformation(
    //         idx, // [0]
    //         collateral_symbols[idx], // [1]
    //         collat_address, // [2]
    //         enabled_collaterals[collat_address], // [3]
    //         missing_decimals[idx], // [4]
    //         collateral_prices[idx], // [5]
    //         pool_ceilings[idx], // [6]
    //         mintPaused[idx], // [7]
    //         redeemPaused[idx], // [8]
    //         recollateralizePaused[idx], // [9]
    //         buyBackPaused[idx], // [10]
    //         borrowingPaused[idx], // [11]
    //         minting_fee[idx], // [12]
    //         redemption_fee[idx], // [13]
    //         buyback_fee[idx], // [14]
    //         recollat_fee[idx] // [15]
    //     );
    // }

    function allCollaterals() internal view returns (address[] memory) {
        return amoPoolStorage().collateral_addresses;
    }
}
