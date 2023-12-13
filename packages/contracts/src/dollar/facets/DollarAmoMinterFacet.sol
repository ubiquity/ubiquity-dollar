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
    /// @param _custodianAddress Address of the custodian.
    /// @param _timelockAddress Address of the timelock.
    /// @param _collateralAddress Address of the collateral token.
    /// @param _collateralToken ERC20 address of the collateral token.
    /// @param _poolAddress Address of the pool.
    /// @param _credits Address of the credits contract.
    /// @param _dollar Address of the dollar contract.
    function init(
        address _custodianAddress,
        address _timelockAddress,
        address _collateralAddress,
        address _collateralToken,
        address _poolAddress,
        address _credits,
        address _dollar
    ) external {
        LibDollarAmoMinter.init(
            _custodianAddress,
            _timelockAddress,
            _collateralAddress,
            _collateralToken,
            _poolAddress,
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
    /// @return dollarValE18 Dollar value of dollar.
    /// @return collatValE18 Dollar value of the collateral.
    function dollarBalances()
        external
        view
        returns (uint256 dollarValE18, uint256 collatValE18)
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
    /// @param _amoAddress Address of the AMO.
    /// @return The dollar tracked amount for the specified AMO.
    function dollarTrackedAmo(
        address _amoAddress
    ) external view returns (int256) {
        return LibDollarAmoMinter.dollarTrackedAmo(_amoAddress);
    }

    /// @notice Synchronizes the dollar balances across all AMOs.
    function syncDollarBalances() external {
        LibDollarAmoMinter.syncDollarBalances();
    }

    /// @notice Mints dollar for a specific AMO.
    /// @param _destinationAmo Address of the destination AMO.
    /// @param _dollarAmount Amount of dollar to mint.
    function mintDollarForAmo(
        address _destinationAmo,
        uint256 _dollarAmount
    ) external onlyDollarManager {
        LibDollarAmoMinter.mintDollarForAmo(_destinationAmo, _dollarAmount);
    }

    /// @notice Burns dollar from an AMO.
    /// @param _dollarAmount Amount of dollar to burn.
    function burnDollarFromAmo(uint256 _dollarAmount) external {
        LibDollarAmoMinter.burnDollarFromAmo(_dollarAmount);
    }

    /// @notice Mints credits tokens for a specified AMO.
    /// @param _destinationAmo The address of the AMO where credits tokens will be minted.
    /// @param _creditsAmount The amount of credits tokens to mint.
    function mintCreditsForAmo(
        address _destinationAmo,
        uint256 _creditsAmount
    ) external onlyDollarManager {
        LibDollarAmoMinter.mintCreditsForAmo(_destinationAmo, _creditsAmount);
    }

    /// @notice Burns credits tokens from the caller AMO.
    /// @param _creditsAmount The amount of credits tokens to burn.
    function burnCreditsFromAmo(uint256 _creditsAmount) external {
        LibDollarAmoMinter.burnCreditsFromAmo(_creditsAmount);
    }

    /// @notice Transfers collateral to a specified AMO.
    /// @param _destinationAmo The address of the AMO to receive the collateral.
    /// @param _collatAmount The amount of collateral to transfer.
    function giveCollatToAmo(
        address _destinationAmo,
        uint256 _collatAmount
    ) external onlyDollarManager {
        LibDollarAmoMinter.giveCollatToAmo(_destinationAmo, _collatAmount);
    }

    /// @notice Receives collateral from the calling AMO.
    /// @param _usdcAmount The amount of USDC collateral to receive.
    function receiveCollatFromAmo(uint256 _usdcAmount) external {
        LibDollarAmoMinter.receiveCollatFromAmo(_usdcAmount);
    }

    /// @notice Adds a new AMO to the system.
    /// @param _amoAddress The address of the new AMO to add.
    /// @param _syncToo Boolean indicating whether to sync dollar balances immediately after adding the AMO.
    function addAmo(
        address _amoAddress,
        bool _syncToo
    ) external onlyDollarManager {
        LibDollarAmoMinter.addAmo(_amoAddress, _syncToo);
    }

    /// @notice Removes an AMO from the system.
    /// @param _amoAddress The address of the AMO to remove.
    /// @param _syncToo Boolean indicating whether to sync dollar balances immediately after removing the AMO.
    function removeAmo(
        address _amoAddress,
        bool _syncToo
    ) external onlyDollarManager {
        LibDollarAmoMinter.removeAmo(_amoAddress, _syncToo);
    }

    /// @notice Sets a new timelock address.
    /// @param _newTimelock The address of the new timelock.
    function setTimelock(address _newTimelock) external onlyDollarManager {
        LibDollarAmoMinter.setTimelock(_newTimelock);
    }

    /// @notice Sets the custodian address.
    /// @param _custodianAddress The address of the custodian.
    function setCustodian(
        address _custodianAddress
    ) external onlyDollarManager {
        LibDollarAmoMinter.setCustodian(_custodianAddress);
    }

    /// @notice Sets the dollar minting cap.
    /// @param _dollarMintCap The new dollar minting cap.
    function setDollarMintCap(
        uint256 _dollarMintCap
    ) external onlyDollarManager {
        LibDollarAmoMinter.setDollarMintCap(_dollarMintCap);
    }

    /// @notice Sets the credits minting cap.
    /// @param _creditsMintCap The new credits minting cap.
    function setCreditsMintCap(
        uint256 _creditsMintCap
    ) external onlyDollarManager {
        LibDollarAmoMinter.setCreditsMintCap(_creditsMintCap);
    }

    /// @notice Sets the collateral borrowing cap.
    /// @param _collatBorrowCap The new collateral borrowing cap.
    function setCollatBorrowCap(
        uint256 _collatBorrowCap
    ) external onlyDollarManager {
        LibDollarAmoMinter.setCollatBorrowCap(_collatBorrowCap);
    }

    /// @notice Sets the minimum collateral ratio.
    /// @param _minCr The new minimum collateral ratio.
    function setMinimumCollateralRatio(
        uint256 _minCr
    ) external onlyDollarManager {
        LibDollarAmoMinter.setMinimumCollateralRatio(_minCr);
    }

    /// @notice Sets correction offsets for a specific AMO.
    /// @param _amoAddress The address of the AMO.
    /// @param _dollarE18Correction The dollar correction amount.
    /// @param _collatE18Correction The collateral correction amount.
    function setAmoCorrectionOffsets(
        address _amoAddress,
        int256 _dollarE18Correction,
        int256 _collatE18Correction
    ) external onlyDollarManager {
        LibDollarAmoMinter.setAmoCorrectionOffsets(
            _amoAddress,
            _dollarE18Correction,
            _collatE18Correction
        );
    }

    /// @notice Sets the dollar pool and collateral address.
    /// @param _poolAddress The address of the dollar pool.
    /// @param _collateralAddress The address of the collateral token.
    /// This function updates the pool and collateral addresses in the Dollar AMO Minter system.
    function setDollarPool(
        address _poolAddress,
        address _collateralAddress
    ) external onlyDollarManager {
        LibDollarAmoMinter.setDollarPool(_poolAddress, _collateralAddress);
    }

    /// @notice Recovers ERC20 tokens accidentally sent to the contract.
    /// @param _tokenAddress The address of the ERC20 token to recover.
    /// @param _tokenAmount The amount of the ERC20 token to recover.
    /// This function allows the recovery of ERC20 tokens that have been mistakenly sent to the contract's address.
    /// It is restricted to only be callable by the Dollar Manager.
    function recoverERC20(
        address _tokenAddress,
        uint256 _tokenAmount
    ) external onlyDollarManager {
        LibDollarAmoMinter.recoverERC20(_tokenAddress, _tokenAmount);
    }
}
