// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.19;

interface IUbiquityPool {
    function minting_fee() external returns (uint256);
    function redeemCollateralBalances(address addr) external returns (uint256);
    function redemption_fee() external returns (uint256);
    function buyback_fee() external returns (uint256);
    function recollat_fee() external returns (uint256);
    function collatDollarBalance() external returns (uint256);
    function availableExcessCollatDV() external returns (uint256);
    function getCollateralPrice() external returns (uint256);
    function setCollatETHOracle(address _collateral_weth_oracle_address, address _weth_address) external;
    function mint1t1UAD(uint256 collateral_amount, uint256 UAD_out_min) external;
    function mintAlgorithmicUAD(uint256 ubq_amount_d18, uint256 UAD_out_min) external;
    function mintFractionalUAD(uint256 collateral_amount, uint256 ubq_amount, uint256 UAD_out_min) external;
    function redeem1t1UAD(uint256 UAD_amount, uint256 COLLATERAL_out_min) external;
    function redeemFractionalUAD(uint256 UAD_amount, uint256 UBQ_out_min, uint256 COLLATERAL_out_min) external;
    function redeemAlgorithmicUAD(uint256 UAD_amount, uint256 UBQ_out_min) external;
    function collectRedemption() external;
    function recollateralizeUAD(uint256 collateral_amount, uint256 UBQ_out_min) external;
    function buyBackUBQ(uint256 UBQ_amount, uint256 COLLATERAL_out_min) external;
    function toggleMinting() external;
    function toggleRedeeming() external;
    function toggleRecollateralize() external;
    function toggleBuyBack() external;
    function toggleCollateralPrice(uint256 _new_price) external;
    function setPoolParameters(uint256 new_ceiling, uint256 new_bonus_rate, uint256 new_redemption_delay, uint256 new_mint_fee, uint256 new_redeem_fee, uint256 new_buyback_fee, uint256 new_recollat_fee) external;
    function setTimelock(address new_timelock) external;
    function setOwner(address _owner_address) external;
}