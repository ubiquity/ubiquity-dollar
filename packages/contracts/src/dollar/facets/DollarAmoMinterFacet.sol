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
    /// @param _ucr Address of the UCR contract.
    /// @param _uad Address of the UAD contract.
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

    /// @notice Retrieves the current dollar balances of UAD and collateral.
    /// @return uad_val_e18 Dollar value of UAD.
    /// @return collat_val_e18 Dollar value of the collateral.
    function dollarBalances()
        external
        view
        returns (uint256 uad_val_e18, uint256 collat_val_e18)
    {
        return LibDollarAmoMinter.dollarBalances();
    }

    /// @notice Retrieves all registered AMO addresses.
    /// @return An array of AMO addresses.
    function allAMOAddresses() external view returns (address[] memory) {
        return LibDollarAmoMinter.allAMOAddresses();
    }

    /// @notice Retrieves the number of registered AMOs.
    /// @return The number of AMOs.
    function allAMOsLength() external view returns (uint256) {
        return LibDollarAmoMinter.allAMOsLength();
    }

    /// @notice Retrieves the global UAD tracked amount.
    /// @return The global UAD tracked amount.
    function uadTrackedGlobal() external view returns (int256) {
        return LibDollarAmoMinter.uadTrackedGlobal();
    }

    /// @notice Retrieves the UAD tracked amount for a specific AMO.
    /// @param amo_address Address of the AMO.
    /// @return The UAD tracked amount for the specified AMO.
    function uadTrackedAMO(address amo_address) external view returns (int256) {
        return LibDollarAmoMinter.uadTrackedAMO(amo_address);
    }

    /// @notice Synchronizes the dollar balances across all AMOs.
    function syncDollarBalances() external {
        LibDollarAmoMinter.syncDollarBalances();
    }

    /// @notice Mints UAD for a specific AMO.
    /// @param destination_amo Address of the destination AMO.
    /// @param uad_amount Amount of UAD to mint.
    function mintUadForAMO(
        address destination_amo,
        uint256 uad_amount
    ) external onlyDollarManager {
        LibDollarAmoMinter.mintUadForAMO(destination_amo, uad_amount);
    }

    /// @notice Burns UAD from an AMO.
    /// @param uad_amount Amount of UAD to burn.
    function burnUadFromAMO(uint256 uad_amount) external {
        LibDollarAmoMinter.burnUadFromAMO(uad_amount);
    }

    /// @notice Mints UCR tokens for a specified AMO.
    /// @param destination_amo The address of the AMO where UCR tokens will be minted.
    /// @param ucr_amount The amount of UCR tokens to mint.
    function mintUcrForAMO(
        address destination_amo,
        uint256 ucr_amount
    ) external onlyDollarManager {
        LibDollarAmoMinter.mintUcrForAMO(destination_amo, ucr_amount);
    }

    /// @notice Burns UCR tokens from the caller AMO.
    /// @param ucr_amount The amount of UCR tokens to burn.
    function burnUcrFromAMO(uint256 ucr_amount) external {
        LibDollarAmoMinter.burnUcrFromAMO(ucr_amount);
    }

    /// @notice Transfers collateral to a specified AMO.
    /// @param destination_amo The address of the AMO to receive the collateral.
    /// @param collat_amount The amount of collateral to transfer.
    function giveCollatToAMO(
        address destination_amo,
        uint256 collat_amount
    ) external onlyDollarManager {
        LibDollarAmoMinter.giveCollatToAMO(destination_amo, collat_amount);
    }

    /// @notice Receives collateral from the calling AMO.
    /// @param usdc_amount The amount of USDC collateral to receive.
    function receiveCollatFromAMO(uint256 usdc_amount) external {
        LibDollarAmoMinter.receiveCollatFromAMO(usdc_amount);
    }

    /// @notice Adds a new AMO to the system.
    /// @param amo_address The address of the new AMO to add.
    /// @param sync_too Boolean indicating whether to sync dollar balances immediately after adding the AMO.
    function addAMO(
        address amo_address,
        bool sync_too
    ) external onlyDollarManager {
        LibDollarAmoMinter.addAMO(amo_address, sync_too);
    }

    /// @notice Removes an AMO from the system.
    /// @param amo_address The address of the AMO to remove.
    /// @param sync_too Boolean indicating whether to sync dollar balances immediately after removing the AMO.
    function removeAMO(
        address amo_address,
        bool sync_too
    ) external onlyDollarManager {
        LibDollarAmoMinter.removeAMO(amo_address, sync_too);
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

    /// @notice Sets the UAD minting cap.
    /// @param _uad_mint_cap The new UAD minting cap.
    function setUadMintCap(uint256 _uad_mint_cap) external onlyDollarManager {
        LibDollarAmoMinter.setUadMintCap(_uad_mint_cap);
    }

    /// @notice Sets the UCR minting cap.
    /// @param _ucr_mint_cap The new UCR minting cap.
    function setUcrMintCap(uint256 _ucr_mint_cap) external onlyDollarManager {
        LibDollarAmoMinter.setUcrMintCap(_ucr_mint_cap);
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
    /// @param uad_e18_correction The UAD correction amount.
    /// @param collat_e18_correction The collateral correction amount.
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

    /// @notice Sets the UAD pool and collateral address.
    /// @param _pool_address The address of the UAD pool.
    /// @param _collateral_address The address of the collateral token.
    /// This function updates the pool and collateral addresses in the Dollar AMO Minter system.
    function setUadPool(
        address _pool_address,
        address _collateral_address
    ) external onlyDollarManager {
        LibDollarAmoMinter.setUadPool(_pool_address, _collateral_address);
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
