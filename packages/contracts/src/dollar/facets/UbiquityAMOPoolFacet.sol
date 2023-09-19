// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {Modifiers} from "../libraries/LibAppStorage.sol";
import {LibUbiquityAMOPool} from "../libraries/LibUbiquityAMOPool.sol";

import {IUbiquityAMOPool} from "../../dollar/interfaces/IUbiquityAMOPool.sol";

/**
 * @notice Ubiquity AMO Pool contract based on Frax Finance
 * @notice Inspired from Frax Finance https://github.com/FraxFinance/frax-solidity
 */
contract UbiquityAMOPoolFacet is Modifiers, IUbiquityAMOPool {
    // function collateral_information(
    //     address _collateral_address
    // ) external view returns (CollateralInformation memory return_data) {
    //     return LibUbiquityAMOPool.collateral_information();
    // }

    function allCollaterals() external view returns (address[] memory) {
        return LibUbiquityAMOPool.allCollaterals();
    }

    function getUADPrice() public view returns (uint256) {
        return LibUbiquityAMOPool.getUADPrice();
    }

    function getGovTokenPrice() public view returns (uint256) {
        return LibUbiquityAMOPool.getGovTokenPrice();
    }

    function getUADInCollateral(
        uint256 _col_idx,
        uint256 _uad_amount
    ) public view returns (uint256) {
        return LibUbiquityAMOPool.getUADInCollateral();
    }

    function freeCollatBalance(uint256 _col_idx) public view returns (uint256) {
        return LibUbiquityAMOPool.getUADInCollateral();
    }

    function collatDollarBalance() external view returns (uint256) {
        return LibUbiquityAMOPool.collateralDollarBalance();
    }

    function buybackAvailableCollateral() external view returns (uint256) {
        return LibUbiquityAMOPool.buybackAvailableCollateral();
    }

    function recollateralizeColAvailableE18() external view returns (uint256) {
        return LibUbiquityAMOPool.recollateralizeColAvailableE18();
    }

    function recollateralizeAvailableGovToken() public view returns (uint256) {
        return LibUbiquityAMOPool.recollateralizeAvailableGovToken();
    }

    function curEpochHr() public view returns (uint256) {
        return LibUbiquityAMOPool.curEpochHr();
    }

    function mintUad(
        uint256 _col_idx,
        uint256 _uad_amt,
        uint256 _uad_out_min,
        uint256 _max_collateral_in,
        uint256 _max_gov_token_in,
        bool _one_to_one_override
    )
        external
        returns (
            uint256 total_uad_mint,
            uint256 collateral_needed,
            uint256 gov_token_needed
        )
    {
        return
            LibUbiquityAMOPool.mintUad(
                _col_idx,
                _uad_amt,
                _uad_out_min,
                _max_collateral_in,
                _max_gov_token_in,
                _one_to_one_override
            );
    }

    function redeemUad(
        uint256 _col_idx,
        uint256 _uad_amount,
        uint256 _gov_token_out_min,
        uint256 _col_out_min
    ) external returns (uint256 collateral_out, uint256 gov_token_out) {
        return
            LibUbiquityAMOPool.redeemUad(
                _col_idx,
                _uad_amount,
                _gov_token_out_min,
                _col_out_min
            );
    }

    function collectRedemption(
        uint256 _col_idx
    ) external returns (uint256 gov_token_amount, uint256 collateral_amount) {
        return LibUbiquityAMOPool.collectRedemption(_col_idx);
    }

    function buyBackGovToken(
        uint256 _col_idx,
        uint256 _gov_token_amount,
        uint256 _col_out_min
    ) external returns (uint256 col_out) {
        return
            LibUbiquityAMOPool.buyBackGovToken(
                _col_idx,
                _gov_token_amount,
                _col_out_min
            );
    }

    function recollateralize(
        uint256 _col_idx,
        uint256 _collateral_amount,
        uint256 _gov_token_out_min
    ) external returns (uint256 gov_token_out) {
        return
            LibUbiquityAMOPool.recollateralize(
                _col_idx,
                _collateral_amount,
                _gov_token_out_min
            );
    }

    function amoMinterBorrow(uint256 _collateral_amount) external onlyMinter {
        LibUbiquityAMOPool.amoMinterBorrow(_collateral_amount);
    }

    /* ========== RESTRICTED FUNCTIONS, CUSTODIAN CAN CALL TOO ========== */

    function toggleProtocol(
        uint256 _col_idx,
        uint8 _tog_idx
    ) external onlyGovCustodian {
        LibUbiquityAMOPool.toggleProtocol(_col_idx, _tog_idx);
    }

    /* ========== RESTRICTED FUNCTIONS, GOVERNANCE ONLY ========== */

    function addAMOMinter(address _amo_minter_addr) external onlyTokenManager {
        LibUbiquityAMOPool.addAMOMinter(_amo_minter_addr);
    }

    function removeAMOMinter(
        address _amo_minter_addr
    ) external onlyTokenManager {
        LibUbiquityAMOPool.removeAMOMinter(_amo_minter_addr);
    }

    function setCollateralPrice(
        uint256 _col_idx,
        uint256 _new_price
    ) external onlyTokenManager {
        LibUbiquityAMOPool.setCollateralPrice(_col_idx, _new_price);
    }

    function toggleCollateral(uint256 _col_idx) external onlyTokenManager {
        LibUbiquityAMOPool.toggleCollateral(_col_idx);
    }

    function setPoolCeiling(
        uint256 _col_idx,
        uint256 _new_ceiling
    ) external onlyTokenManager {
        LibUbiquityAMOPool.setPoolCeiling(_col_idx, _new_ceiling);
    }

    function setFees(
        uint256 _col_idx,
        uint256 _new_mint_fee,
        uint256 _new_redeem_fee,
        uint256 _new_buyback_fee,
        uint256 _new_collateral_fee
    ) external onlyTokenManager {
        LibUbiquityAMOPool.setFees(
            _col_idx,
            _new_mint_fee,
            _new_redeem_fee,
            _new_buyback_fee,
            _new_collateral_fee
        );
    }

    function setPoolParameters(
        uint256 _new_bonus_rate,
        uint256 _new_redemption_delay
    ) external onlyTokenManager {
        LibUbiquityAMOPool.setPoolParameters(
            _new_bonus_rate,
            _new_redemption_delay
        );
    }

    function setPriceThresholds(
        uint256 _new_mint_price_threshold,
        uint256 _new_redeem_price_threshold
    ) external onlyTokenManager {
        LibUbiquityAMOPool.setPriceThresholds(
            _new_mint_price_threshold,
            _new_redeem_price_threshold
        );
    }

    function setBbkRctPerHour(
        uint256 _bbkMaxColE18OutPerHour,
        uint256 _rctMaxFxsOutPerHour
    ) external onlyTokenManager {
        LibUbiquityAMOPool.setBbkRctPerHour(
            _bbkMaxColE18OutPerHour,
            _rctMaxFxsOutPerHour
        );
    }

    function setOracles(
        address _uad_usd_chainlink_addr,
        address _gov_token_usd_chainlink_addr
    ) external onlyTokenManager {
        LibUbiquityAMOPool.setOracles(
            _uad_usd_chainlink_addr,
            _gov_token_usd_chainlink_addr
        );
    }

    function setCustodian(address _new_custodian) external onlyTokenManager {
        LibUbiquityAMOPool.setCustodian(_new_custodian);
    }

    function setTimelock(address _new_timelock) external onlyTokenManager {
        LibUbiquityAMOPool.setTimelock(_new_timelock);
    }
}
