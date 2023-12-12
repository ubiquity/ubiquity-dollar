// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LibDollarAmoMinter} from "../libraries/LibDollarAmoMinter.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

import {IDollarAmoMinter} from "../interfaces/IDollarAmoMinter.sol";

/// @title Dollar AMO Minter Facet
/// @notice Facet contract for minting and managing the Dollar AMO.
/// This contract acts as a facet of a diamond and interacts with the LibDollarAmoMinter library.
contract DollarAmoMinterFacet is Modifiers, IDollarAmoMinter {
    /// @notice Initializes the Dollar AMO Minter contract.
    /// @param _custodian_address Address of the custodian.
    /// @param _timelock_address Address of the timelock.
    /// @param _collateral_address Address of the collateral token.
    /// @param _collateral_token ERC20 address of the collateral token.
    /// @param _pool_address Address of the pool.
    /// @param _credits Address of the credits contract.
    /// @param _dollar Address of the dollar contract.
    function init(
        address _custodian_address,
        address _timelock_address,
        address _collateral_address,
        address _collateral_token,
        address _pool_address,
        address _credits,
        address _dollar
    ) external {
        LibDollarAmoMinter.init(
            _custodian_address,
            _timelock_address,
            _collateral_address,
            _collateral_token,
            _pool_address,
            _credits,
            _dollar
        );
    }

    /// @notice Retrieves the current dollar balance of the collateral.
    /// @return uint256 The dollar balance of the collateral.
    function collateralDollarBalance() external view returns (uint256) {
        return LibDollarAmoMinter.collateralDollarBalance();
    }

    /// @notice Retrieves the index of the collateral token.
    /// @return index The index of the collateral token.
    function collateralIndex() external view returns (uint256 index) {
        return LibDollarAmoMinter.collateralIndex();
    }

    /// @notice Retrieves the current dollar balances of dollar and collateral.
    /// @return dollar_val_e18 Dollar value of dollar.
    /// @return collat_val_e18 Dollar value of the collateral.
    function dollarBalances()
        external
        view
        returns (uint256 dollar_val_e18, uint256 collat_val_e18)
    {
        return LibDollarAmoMinter.dollarBalances();
    }

    /// @notice Retrieves all registered AMO addresses.
    /// @return An array of AMO addresses.
    function allAmoAddresses() external view returns (address[] memory) {
        return LibDollarAmoMinter.allAmoAddresses();
    }

    /// @notice Retrieves the number of registered AMOs.
    /// @return The number of AMOs.
    function allAmosLength() external view returns (uint256) {
        return LibDollarAmoMinter.allAmosLength();
    }

    /// @notice Retrieves the global dollar tracked amount.
    /// @return The global dollar tracked amount.
    function dollarTrackedGlobal() external view returns (int256) {
        return LibDollarAmoMinter.dollarTrackedGlobal();
    }

    /// @notice Retrieves the dollar tracked amount for a specific AMO.
    /// @param amo_address Address of the AMO.
    /// @return The dollar tracked amount for the specified AMO.
    function dollarTrackedAmo(
        address amo_address
    ) external view returns (int256) {
        return LibDollarAmoMinter.dollarTrackedAmo(amo_address);
    }

    /// @notice Synchronizes the dollar balances across all AMOs.
    function syncDollarBalances() external {
        LibDollarAmoMinter.syncDollarBalances();
    }

    /// @notice Mints dollar for a specific AMO.
    /// @param destination_amo Address of the destination AMO.
    /// @param dollar_amount Amount of dollar to mint.
    function mintDollarForAmo(
        address destination_amo,
        uint256 dollar_amount
    ) external onlyDollarManager {
        LibDollarAmoMinter.mintDollarForAmo(destination_amo, dollar_amount);
    }

    /// @notice Burns dollar from an AMO.
    /// @param dollar_amount Amount of dollar to burn.
    function burnDollarFromAmo(uint256 dollar_amount) external {
        LibDollarAmoMinter.burnDollarFromAmo(dollar_amount);
    }

    /// @notice Mints credits tokens for a specified AMO.
    /// @param destination_amo The address of the AMO where credits tokens will be minted.
    /// @param credits_amount The amount of credits tokens to mint.
    function mintCreditsForAmo(
        address destination_amo,
        uint256 credits_amount
    ) external onlyDollarManager {
        LibDollarAmoMinter.mintCreditsForAmo(destination_amo, credits_amount);
    }

    /// @notice Burns credits tokens from the caller AMO.
    /// @param credits_amount The amount of credits tokens to burn.
    function burnCreditsFromAmo(uint256 credits_amount) external {
        LibDollarAmoMinter.burnCreditsFromAmo(credits_amount);
    }

    /// @notice Transfers collateral to a specified AMO.
    /// @param destination_amo The address of the AMO to receive the collateral.
    /// @param collat_amount The amount of collateral to transfer.
    function giveCollatToAmo(
        address destination_amo,
        uint256 collat_amount
    ) external onlyDollarManager {
        LibDollarAmoMinter.giveCollatToAmo(destination_amo, collat_amount);
    }

    /// @notice Receives collateral from the calling AMO.
    /// @param usdc_amount The amount of USDC collateral to receive.
    function receiveCollatFromAmo(uint256 usdc_amount) external {
        LibDollarAmoMinter.receiveCollatFromAmo(usdc_amount);
    }

    /// @notice Adds a new AMO to the system.
    /// @param amo_address The address of the new AMO to add.
    /// @param sync_too Boolean indicating whether to sync dollar balances immediately after adding the AMO.
    function addAmo(
        address amo_address,
        bool sync_too
    ) external onlyDollarManager {
        LibDollarAmoMinter.addAmo(amo_address, sync_too);
    }

    /// @notice Removes an AMO from the system.
    /// @param amo_address The address of the AMO to remove.
    /// @param sync_too Boolean indicating whether to sync dollar balances immediately after removing the AMO.
    function removeAmo(
        address amo_address,
        bool sync_too
    ) external onlyDollarManager {
        LibDollarAmoMinter.removeAmo(amo_address, sync_too);
    }

    /// @notice Sets a new timelock address.
    /// @param new_timelock The address of the new timelock.
    function setTimelock(address new_timelock) external onlyDollarManager {
        LibDollarAmoMinter.setTimelock(new_timelock);
    }

    /// @notice Sets the custodian address.
    /// @param _custodian_address The address of the custodian.
    function setCustodian(
        address _custodian_address
    ) external onlyDollarManager {
        LibDollarAmoMinter.setCustodian(_custodian_address);
    }

    /// @notice Sets the dollar minting cap.
    /// @param _dollar_mint_cap The new dollar minting cap.
    function setDollarMintCap(
        uint256 _dollar_mint_cap
    ) external onlyDollarManager {
        LibDollarAmoMinter.setDollarMintCap(_dollar_mint_cap);
    }

    /// @notice Sets the credits minting cap.
    /// @param _credits_mint_cap The new credits minting cap.
    function setCreditsMintCap(
        uint256 _credits_mint_cap
    ) external onlyDollarManager {
        LibDollarAmoMinter.setCreditsMintCap(_credits_mint_cap);
    }

    /// @notice Sets the collateral borrowing cap.
    /// @param _collat_borrow_cap The new collateral borrowing cap.
    function setCollatBorrowCap(
        uint256 _collat_borrow_cap
    ) external onlyDollarManager {
        LibDollarAmoMinter.setCollatBorrowCap(_collat_borrow_cap);
    }

    /// @notice Sets the minimum collateral ratio.
    /// @param _min_cr The new minimum collateral ratio.
    function setMinimumCollateralRatio(
        uint256 _min_cr
    ) external onlyDollarManager {
        LibDollarAmoMinter.setMinimumCollateralRatio(_min_cr);
    }

    /// @notice Sets correction offsets for a specific AMO.
    /// @param amo_address The address of the AMO.
    /// @param dollar_e18_correction The dollar correction amount.
    /// @param collat_e18_correction The collateral correction amount.
    function setAmoCorrectionOffsets(
        address amo_address,
        int256 dollar_e18_correction,
        int256 collat_e18_correction
    ) external onlyDollarManager {
        LibDollarAmoMinter.setAmoCorrectionOffsets(
            amo_address,
            dollar_e18_correction,
            collat_e18_correction
        );
    }

    /// @notice Sets the dollar pool and collateral address.
    /// @param _pool_address The address of the dollar pool.
    /// @param _collateral_address The address of the collateral token.
    /// This function updates the pool and collateral addresses in the Dollar AMO Minter system.
    function setDollarPool(
        address _pool_address,
        address _collateral_address
    ) external onlyDollarManager {
        LibDollarAmoMinter.setDollarPool(_pool_address, _collateral_address);
    }

    /// @notice Recovers ERC20 tokens accidentally sent to the contract.
    /// @param tokenAddress The address of the ERC20 token to recover.
    /// @param tokenAmount The amount of the ERC20 token to recover.
    /// This function allows the recovery of ERC20 tokens that have been mistakenly sent to the contract's address.
    /// It is restricted to only be callable by the Dollar Manager.
    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount
    ) external onlyDollarManager {
        LibDollarAmoMinter.recoverERC20(tokenAddress, tokenAmount);
    }
}
