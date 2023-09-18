// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {Modifiers} from "../libraries/LibAppStorage.sol";
import {LibUbiquityAMOMinter} from "../libraries/LibUbiquityAMOMinter.sol";

import {IUbiquityAMOMinter} from "../../dollar/interfaces/IUbiquityAMOMinter.sol";

/**
 * @notice Ubiquity AMO Pool contract based on Frax Finance
 * @notice Inspired from Frax Finance https://github.com/FraxFinance/frax-solidity
 */
contract UbiquityAMOMinterFacet is IUbiquityAMOMinter {
    function collatDollarBalance() external view returns (uint256) {
        LibUbiquityAMOMinter.collatDollarBalance();
    }

    function dollarBalances()
        public
        view
        returns (uint256 _uAD_val_e18, uint256 _collateral_val_e18)
    {
        LibUbiquityAMOMinter.dollarBalances(_uAD_val_e18, _collateral_val_e18);
    }

    function allAMOAddresses() external view returns (address[] memory) {
        return LibUbiquityAMOMinter.allAMOAddresses;
    }

    function allAMOsLength() external view returns (uint256) {
        return LibUbiquityAMOMinter.allAMOsLength;
    }

    function uADTrackedGlobal() external view returns (int256) {
        return LibUbiquityAMOMinter.uADTrackedGlobal();
    }

    function uADTrackedAMO(
        address _amo_address
    ) external view returns (int256) {
        return LibUbiquityAMOMinter.uADTrackedAMO(_amo_address);
    }

    function syncDollarBalances() public {
        LibUbiquityAMOMinter.syncDollarBalances();
    }

    function giveCollatToAMO(
        address _destination_amo,
        uint256 _collateral_amount
    ) external onlyByOwnGov {
        LibUbiquityAMOMinter.giveCollatToAMO;
    }

    function receiveCollatFromAMO(uint256 usdc_amount) external {
        LibUbiquityAMOMinter.receiveCollatFromAMO;
    }

    function addAMO(address _amo_address, bool sync_too) external onlyByOwnGov {
        LibUbiquityAMOMinter.addAMO;
    }

    function removeAMO(
        address _amo_address,
        bool _sync_too
    ) external onlyByOwnGov {
        LibUbiquityAMOMinter.removeAMO;
    }

    function setTimelock(address _new_timelock) external onlyByOwnGov {
        LibUbiquityAMOMinter.setTimelock(_new_timelock);
    }

    function setCustodian(address _custodian_address) external onlyByOwnGov {
        LibUbiquityAMOMinter.setCustodian(_custodian_address);
    }

    function setUadMintCap(uint256 _uAD_mint_cap) external onlyByOwnGov {
        LibUbiquityAMOMinter.setUadMintCap(_uAD_mint_cap);
    }

    function setuGovMintCap(uint256 _uGov_mint_cap) external onlyByOwnGov {
        LibUbiquityAMOMinter.setuGovMintCap(_uGov_mint_cap);
    }

    function setCollatBorrowCap(
        uint256 _collat_borrow_cap
    ) external onlyByOwnGov {
        LibUbiquityAMOMinter.setCollatBorrowCap(_collat_borrow_cap);
    }

    function setMinimumCollateralRatio(uint256 _min_cr) external onlyByOwnGov {
        LibUbiquityAMOMinter.setMinimumCollateralRatio(_min_cr);
    }

    function setAMOCorrectionOffsets(
        address _amo_address,
        int256 _uAD_e18_correction,
        int256 _collat_e18_correction
    ) external onlyByOwnGov {
        LibUbiquityAMOMinter.setAMOCorrectionOffsets(
            _amo_address,
            _uAD_e18_correction,
            _collat_e18_correction
        );
    }

    function setUadPool(address _pool_address) external onlyByOwnGov {
        LibUbiquityAMOMinter.setUadPool(_pool_address);
    }

    function recoverERC20(
        address _tokenAddress,
        uint256 _tokenAmount
    ) external onlyByOwnGov {
        LibUbiquityAMOMinter.recoverERC20(_tokenAddress, _tokenAmount);
    }

    // Generic proxy
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyByOwnGov returns (bool, bytes memory) {
        LibUbiquityAMOMinter.execute(_to, _value, _data);
    }
}
