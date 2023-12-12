// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IDollarAmoMinter {
    function init(
        address _custodian_address,
        address _timelock_address,
        address _collateral_address,
        address _collateral_token,
        address _pool_address,
        address _credits,
        address _dollar
    ) external;

    function collateralDollarBalance() external view returns (uint256);

    function collateralIndex() external view returns (uint256);

    function dollarBalances()
        external
        view
        returns (uint256 dollar_val_e18, uint256 collat_val_e18);

    function allAmoAddresses() external view returns (address[] memory);

    function allAmosLength() external view returns (uint256);

    function dollarTrackedGlobal() external view returns (int256);

    function dollarTrackedAmo(
        address amo_address
    ) external view returns (int256);

    function syncDollarBalances() external;

    function mintDollarForAmo(
        address destination_amo,
        uint256 dollar_amount
    ) external;

    function burnDollarFromAmo(uint256 dollar_amount) external;

    function mintCreditsForAmo(
        address destination_amo,
        uint256 credits_amount
    ) external;

    function burnCreditsFromAmo(uint256 credits_amount) external;

    function giveCollatToAmo(
        address destination_amo,
        uint256 collat_amount
    ) external;

    function receiveCollatFromAmo(uint256 usdc_amount) external;

    function addAmo(address amo_address, bool sync_too) external;

    function removeAmo(address amo_address, bool sync_too) external;

    function setTimelock(address new_timelock) external;

    function setCustodian(address _custodian_address) external;

    function setDollarMintCap(uint256 _dollar_mint_cap) external;

    function setCreditsMintCap(uint256 _credits_mint_cap) external;

    function setCollatBorrowCap(uint256 _collat_borrow_cap) external;

    function setMinimumCollateralRatio(uint256 _min_cr) external;

    function setAmoCorrectionOffsets(
        address amo_address,
        int256 dollar_e18_correction,
        int256 collat_e18_correction
    ) external;

    function setDollarPool(
        address _pool_address,
        address _collateral_address
    ) external;

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;
}
