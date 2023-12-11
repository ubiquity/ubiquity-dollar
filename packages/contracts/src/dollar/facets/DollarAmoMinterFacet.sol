// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LibDollarAmoMinter} from "../libraries/LibDollarAmoMinter.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

import {IDollarAmoMinter} from "../interfaces/IDollarAmoMinter.sol";

contract DollarAmoMinterFacet is Modifiers, IDollarAmoMinter {
    function init(
        address _custodian_address,
        address _timelock_address,
        address _collateral_address,
        address _collateral_token,
        address _pool_address,
        address _ucr,
        address _uad
    ) external {
        LibDollarAmoMinter.init(
            _custodian_address,
            _timelock_address,
            _collateral_address,
            _collateral_token,
            _pool_address,
            _ucr,
            _uad
        );
    }

    function collateralDollarBalance() external view returns (uint256) {
        return LibDollarAmoMinter.collateralDollarBalance();
    }

    function collateralIndex() external view returns (uint256 index) {
        return LibDollarAmoMinter.collateralIndex();
    }

    function dollarBalances()
        external
        view
        returns (uint256 uad_val_e18, uint256 collat_val_e18)
    {
        return LibDollarAmoMinter.dollarBalances();
    }

    function allAMOAddresses() external view returns (address[] memory) {
        return LibDollarAmoMinter.allAMOAddresses();
    }

    function allAMOsLength() external view returns (uint256) {
        return LibDollarAmoMinter.allAMOsLength();
    }

    function uadTrackedGlobal() external view returns (int256) {
        return LibDollarAmoMinter.uadTrackedGlobal();
    }

    function uadTrackedAMO(address amo_address) external view returns (int256) {
        return LibDollarAmoMinter.uadTrackedAMO(amo_address);
    }

    function syncDollarBalances() external {
        LibDollarAmoMinter.syncDollarBalances();
    }

    function mintUadForAMO(
        address destination_amo,
        uint256 uad_amount
    ) external onlyDollarManager {
        LibDollarAmoMinter.mintUadForAMO(destination_amo, uad_amount);
    }

    function burnUadFromAMO(uint256 uad_amount) external {
        LibDollarAmoMinter.burnUadFromAMO(uad_amount);
    }

    function mintUcrForAMO(
        address destination_amo,
        uint256 ucr_amount
    ) external onlyDollarManager {
        LibDollarAmoMinter.mintUcrForAMO(destination_amo, ucr_amount);
    }

    function burnUcrFromAMO(uint256 ucr_amount) external {
        LibDollarAmoMinter.burnUcrFromAMO(ucr_amount);
    }

    function giveCollatToAMO(
        address destination_amo,
        uint256 collat_amount
    ) external onlyDollarManager {
        LibDollarAmoMinter.giveCollatToAMO(destination_amo, collat_amount);
    }

    function receiveCollatFromAMO(uint256 usdc_amount) external {
        LibDollarAmoMinter.receiveCollatFromAMO(usdc_amount);
    }

    function addAMO(
        address amo_address,
        bool sync_too
    ) external onlyDollarManager {
        LibDollarAmoMinter.addAMO(amo_address, sync_too);
    }

    function removeAMO(
        address amo_address,
        bool sync_too
    ) external onlyDollarManager {
        LibDollarAmoMinter.removeAMO(amo_address, sync_too);
    }

    function setTimelock(address new_timelock) external onlyDollarManager {
        LibDollarAmoMinter.setTimelock(new_timelock);
    }

    function setCustodian(
        address _custodian_address
    ) external onlyDollarManager {
        LibDollarAmoMinter.setCustodian(_custodian_address);
    }

    function setUadMintCap(uint256 _uad_mint_cap) external onlyDollarManager {
        LibDollarAmoMinter.setUadMintCap(_uad_mint_cap);
    }

    function setUcrMintCap(uint256 _ucr_mint_cap) external onlyDollarManager {
        LibDollarAmoMinter.setUcrMintCap(_ucr_mint_cap);
    }

    function setCollatBorrowCap(
        uint256 _collat_borrow_cap
    ) external onlyDollarManager {
        LibDollarAmoMinter.setCollatBorrowCap(_collat_borrow_cap);
    }

    function setMinimumCollateralRatio(
        uint256 _min_cr
    ) external onlyDollarManager {
        LibDollarAmoMinter.setMinimumCollateralRatio(_min_cr);
    }

    function setAMOCorrectionOffsets(
        address amo_address,
        int256 uad_e18_correction,
        int256 collat_e18_correction
    ) external onlyDollarManager {
        LibDollarAmoMinter.setAMOCorrectionOffsets(
            amo_address,
            uad_e18_correction,
            collat_e18_correction
        );
    }

    function setUadPool(
        address _pool_address,
        address _collateral_address
    ) external onlyDollarManager {
        LibDollarAmoMinter.setUadPool(_pool_address, _collateral_address);
    }

    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount
    ) external onlyDollarManager {
        LibDollarAmoMinter.recoverERC20(tokenAddress, tokenAmount);
    }
}
