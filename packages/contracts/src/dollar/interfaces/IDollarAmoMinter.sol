// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title IDollarAmoMinter Interface
/// @notice Interface for the Dollar AMO Minter contract.
interface IDollarAmoMinter {
    /// @notice Initializes the Dollar AMO Minter with necessary addresses.
    /// @param _custodianAddress Address of the custodian.
    /// @param _timelockAddress Address of the timelock.
    /// @param _collateralAddress Address of the collateral.
    /// @param _collateralToken ERC20 address of the collateral token.
    /// @param _poolAddress Address of the liquidity pool.
    /// @param _credits Address of the credit token.
    /// @param _dollar Address of the dollar token.
    function init(
        address _custodianAddress,
        address _timelockAddress,
        address _collateralAddress,
        address _collateralToken,
        address _poolAddress,
        address _credits,
        address _dollar
    ) external;

    /// @notice Gets the dollar balance of the collateral.
    /// @return The dollar value of the collateral.
    function collateralDollarBalance() external view returns (uint256);

    /// @notice Retrieves the index of the collateral token.
    /// @return The index of the collateral token.
    function collateralIndex() external view returns (uint256);

    /// @notice Provides the current dollar balances of the dollar and collateral tokens.
    /// @return dollarValE18 The dollar value of the dollar token.
    /// @return collatValE18 The dollar value of the collateral token.
    function dollarBalances()
        external
        view
        returns (uint256 dollarValE18, uint256 collatValE18);

    /// @notice Lists all AMO addresses registered in the system.
    /// @return A list of AMO addresses.
    function allAmoAddresses() external view returns (address[] memory);

    /// @notice Counts the total number of AMOs registered in the system.
    /// @return The number of AMOs.
    function allAmosLength() external view returns (uint256);

    /// @notice Retrieves the global net dollar amount tracked by the system.
    /// @return The net global dollar amount, considering all relevant factors.
    function dollarTrackedGlobal() external view returns (int256);

    /// @notice Retrieves the net dollar amount tracked for a specific AMO.
    /// @param _amoAddress The address of the AMO for which the balance is being calculated.
    /// @return The net dollar amount tracked for the specified AMO.
    function dollarTrackedAmo(
        address _amoAddress
    ) external view returns (int256);

    /// @notice Synchronizes the dollar balances across all AMOs.
    /// @dev This function aggregates and updates the system's view of dollar balances from all AMOs.
    function syncDollarBalances() external;

    /// @notice Mints dollar tokens for a specific AMO.
    /// @param _destinationAmo The address of the destination AMO.
    /// @param _dollarAmount The amount of dollar tokens to mint.
    function mintDollarForAmo(
        address _destinationAmo,
        uint256 _dollarAmount
    ) external;

    /// @notice Burns dollar tokens from the calling AMO.
    /// @param _dollarAmount The amount of dollar tokens to burn.
    function burnDollarFromAmo(uint256 _dollarAmount) external;

    /// @notice Mints credit tokens for a specific AMO.
    /// @param _destinationAmo The address of the destination AMO.
    /// @param _creditsAmount The amount of credit tokens to mint.
    function mintCreditsForAmo(
        address _destinationAmo,
        uint256 _creditsAmount
    ) external;

    /// @notice Burns credit tokens from the calling AMO.
    /// @param _creditsAmount The amount of credit tokens to burn.
    function burnCreditsFromAmo(uint256 _creditsAmount) external;

    /// @notice Transfers collateral to a specified AMO.
    /// @param _destinationAmo The address of the destination AMO to receive the collateral.
    /// @param _collatAmount The amount of collateral to transfer.
    function giveCollatToAmo(
        address _destinationAmo,
        uint256 _collatAmount
    ) external;

    /// @notice Receives collateral back from an AMO.
    /// @param _usdcAmount The amount of collateral (USDC) to receive back.
    function receiveCollatFromAmo(uint256 _usdcAmount) external;

    /// @notice Adds a new AMO to the system.
    /// @param _amoAddress The address of the new AMO to add.
    /// @param _syncToo Boolean indicating whether to synchronize dollar balances after adding.
    function addAmo(address _amoAddress, bool _syncToo) external;

    /// @notice Removes an AMO from the system.
    /// @param _amoAddress The address of the AMO to remove.
    /// @param _syncToo Boolean indicating whether to synchronize dollar balances after removing.
    function removeAmo(address _amoAddress, bool _syncToo) external;

    /// @notice Sets a new timelock address.
    /// @param _newTimelock The address of the new timelock.
    function setTimelock(address _newTimelock) external;

    /// @notice Returns the timelock address.
    function timelockAddress() external view returns (address _timelockAddr);

    /// @notice Sets the custodian address.
    /// @param _custodianAddress The address of the custodian.
    function setCustodian(address _custodianAddress) external;

    /// @notice Returns the custodian address.
    function custodianAddress() external view returns (address _custodianAddr);

    /// @notice Sets the dollar mint cap.
    /// @param _dollarMintCap The new dollar mint cap to be set.
    function setDollarMintCap(uint256 _dollarMintCap) external;

    /// @notice Sets the credit tokens mint cap.
    /// @param _creditsMintCap The new mint cap for credit tokens.
    function setCreditsMintCap(uint256 _creditsMintCap) external;

    /// @notice Sets the collateral borrow cap.
    /// @param _collatBorrowCap The new borrow cap for collateral.
    function setCollatBorrowCap(uint256 _collatBorrowCap) external;

    /// @notice Sets the minimum collateral ratio.
    /// @param _minCr The new minimum collateral ratio.
    function setMinimumCollateralRatio(uint256 _minCr) external;

    /// @notice Sets correction offsets for a specific AMO.
    /// @param _amoAddress The address of the AMO for which to set correction offsets.
    /// @param _dollarE18Correction The correction offset for dollar value.
    /// @param _collatE18Correction The correction offset for collateral value.
    function setAmoCorrectionOffsets(
        address _amoAddress,
        int256 _dollarE18Correction,
        int256 _collatE18Correction
    ) external;

    /// @notice Sets the dollar pool and collateral address.
    /// @param _poolAddress The address of the new dollar pool.
    /// @param _collateralAddress The address of the new collateral token.
    function setDollarPool(
        address _poolAddress,
        address _collateralAddress
    ) external;

    /// @notice Recovers ERC20 tokens accidentally sent to the contract.
    /// @param _tokenAddress The address of the ERC20 token to recover.
    /// @param _tokenAmount The amount of the ERC20 token to recover.
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external;
}
