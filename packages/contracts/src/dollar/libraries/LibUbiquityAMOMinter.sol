// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LibAppStorage} from "./LibAppStorage.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";
import "../interfaces/IAMO.sol";

/**
 * @notice Bonding curve library based on Bancor formula
 * @notice Inspired from Bancor protocol https://github.com/bancorprotocol/contracts
 * @notice Used on UbiquiStick NFT minting
 */
library LibUbiquityAMOMinter {
    bytes32 constant AMOMINTER_CONTROL_STORAGE_SLOT =
        bytes32(uint256(keccak256("ubiquity.contracts.amominter.storage")) - 1);

    struct AmoPoolData {
        uint256 uadDollarBalanceStored;
        uint256 collatDollarBalanceStored;
        uint256 missing_decimals;
        int256 uad_mint_sum;
        int256 collat_borrowed_sum;
        address[] amos_array;
        mapping(address => int256[2]) correction_offsets_amos;
        mapping(address => int256) uad_mint_balances;
        mapping(address => int256) collat_borrowed_balances;
    }

    /**
     * @notice Returns struct used as a storage for this library
     * @return l Struct used as a storage
     */
    function amoMinterStorage() internal pure returns (AmoPoolData storage l) {
        bytes32 slot = AMOMINTER_CONTROL_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function collatDollarBalance() external view returns (uint256) {
        (, uint256 collat_val_e18) = dollarBalances();
        return collat_val_e18;
    }

    function dollarBalances()
        internal
        view
        returns (uint256 uad_val_e18, uint256 collat_val_e18)
    {
        uad_val_e18 = amoMinterStorage().uadDollarBalanceStored;
        collat_val_e18 = amoMinterStorage().collatDollarBalanceStored;
    }

    function allAMOAddresses() internal view returns (address[] memory) {
        return amoMinterStorage().amos_array;
    }

    function allAMOsLength() internal view returns (uint256) {
        return amoMinterStorage().amos_array.length;
    }

    function uADTrackedGlobal() internal view returns (int256) {
        return
            int256(amoMinterStorage().uadDollarBalanceStored) -
            amoMinterStorage().uad_mint_sum -
            (amoMinterStorage().collat_borrowed_sum *
                int256(10 ** amoMinterStorage().missing_decimals));
    }

    function uADTrackedAMO(
        address _amo_address
    ) external view returns (int256) {
        (uint256 uad_val_e18, ) = IAMO(_amo_address).dollarBalances();
        int256 uad_val_e18_corrected = int256(uad_val_e18) +
            amoMinterStorage().correction_offsets_amos[_amo_address][0];
        return
            uad_val_e18_corrected -
            amoMinterStorage().uad_mint_balances[_amo_address] -
            ((amoMinterStorage().collat_borrowed_balances[_amo_address]) *
                int256(10 ** amoMinterStorage().missing_decimals));
    }
}
