// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IDollarAmoMinter {
    function init(
        address _custodian_address,
        address _timelock_address,
        address _collateral_address,
        address _collateral_token,
        address _pool_address,
        address _ucr,
        address _uad
    ) external;

    function collateralDollarBalance() external view returns (uint256);

    function collateralIndex() external view returns (uint256);

    function dollarBalances()
        external
        view
        returns (uint256 uad_val_e18, uint256 collat_val_e18);

    function allAMOAddresses() external view returns (address[] memory);

    function allAMOsLength() external view returns (uint256);

    function uadTrackedGlobal() external view returns (int256);

    function uadTrackedAMO(address amo_address) external view returns (int256);

    function syncDollarBalances() external;

    function mintUadForAMO(
        address destination_amo,
        uint256 uad_amount
    ) external;

    function burnUadFromAMO(uint256 uad_amount) external;

    function mintUcrForAMO(
        address destination_amo,
        uint256 ucr_amount
    ) external;

    function burnUcrFromAMO(uint256 ucr_amount) external;

    function giveCollatToAMO(
        address destination_amo,
        uint256 collat_amount
    ) external;

    function receiveCollatFromAMO(uint256 usdc_amount) external;

    function addAMO(address amo_address, bool sync_too) external;

    function removeAMO(address amo_address, bool sync_too) external;

    function setTimelock(address new_timelock) external;

    function setCustodian(address _custodian_address) external;

    function setUadMintCap(uint256 _uad_mint_cap) external;

    function setUcrMintCap(uint256 _ucr_mint_cap) external;

    function setCollatBorrowCap(uint256 _collat_borrow_cap) external;

    function setMinimumCollateralRatio(uint256 _min_cr) external;

    function setAMOCorrectionOffsets(
        address amo_address,
        int256 uad_e18_correction,
        int256 collat_e18_correction
    ) external;

    function setUadPool(
        address _pool_address,
        address _collateral_address
    ) external;

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;
}
