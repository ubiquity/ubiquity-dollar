// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../core/UbiquityDollarToken.sol";
import "../interfaces/IUbiquityPool.sol";
import "../interfaces/IUbiquityDollarToken.sol";
import "../interfaces/IUbiquityCreditToken.sol";
import "../interfaces/IAmo.sol";
import "./Constants.sol";

/// @title Library for Dollar AMO Minter functionality
/// @notice Provides functions for managing AMOs and their interactions with Dollar and Credits tokens.
library LibDollarAmoMinter {
    using SafeERC20 for IERC20;

    bytes32 constant AMOMINTER_CONTROL_STORAGE_SLOT =
        bytes32(uint256(keccak256("ubiquity.contracts.amominter.storage")) - 1);

    /* ========== EVENTS ========== */

    /// @notice Emitted when an AMO is added.
    event AmoAdded(address indexed amo_address);

    /// @notice Emitted when an AMO is removed.
    event AmoRemoved(address indexed amo_address);

    /// @notice Emitted when ERC20 tokens are recovered.
    event Recovered(address indexed token, uint256 amount);

    /* ========== STATE VARIABLES ========== */
    /// @notice Struct to hold AMO minter data.
    struct DollarAmoMinterData {
        // Core
        IUbiquityDollarToken DOLLAR;
        IUbiquityCreditToken CREDITS;
        ERC20 collateral_token;
        IUbiquityPool pool;
        address timelock_address;
        address custodian_address;
        // Collateral related
        address collateral_address;
        uint256 col_idx;
        // AMO addresses
        address[] amos_array;
        mapping(address => bool) amos; // Mapping is also used for faster verification
        // Max amount of collateral the contract can borrow from the UbiquityPool
        int256 collat_borrow_cap;
        // Max amount of dollar and credits this contract can mint
        int256 dollar_mint_cap;
        int256 credits_mint_cap;
        // Minimum collateral ratio needed for new dollar minting
        uint256 min_cr;
        // dollar mint balances
        mapping(address => int256) dollar_mint_balances; // Amount of FRAX the contract minted, by AMO
        int256 dollar_mint_sum; // Across all AMOs
        // credits mint balances
        mapping(address => int256) credits_mint_balances; // Amount of FXS the contract minted, by AMO
        int256 credits_mint_sum; // Across all AMOs
        // Collateral borrowed balances
        mapping(address => int256) collat_borrowed_balances; // Amount of collateral the contract borrowed, by AMO
        int256 collat_borrowed_sum; // Across all AMOs
        // dollar balance related
        uint256 dollarDollarBalanceStored;
        // Collateral balance related
        uint256 missing_decimals;
        uint256 collatDollarBalanceStored;
        // AMO balance corrections
        mapping(address => int256[2]) correction_offsets_amos;
    }

    /**
     * @notice Returns struct used as a storage for this library
     * @return l Struct used as a storage
     */
    function dollarAmoMinterStorage()
        internal
        pure
        returns (DollarAmoMinterData storage l)
    {
        bytes32 slot = AMOMINTER_CONTROL_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /* ========== LIBRARY FUNCTIONS ========== */

    /**
     * @notice Initializes the Dollar AMO Minter with necessary addresses and settings.
     * @dev Sets up the AMO minter with the custodian, timelock, collateral, pool, CREDITS, and DOLLAR Token addresses.
     * @param _custodian_address Address of the custodian.
     * @param _timelock_address Address of the timelock.
     * @param _collateral_address Address of the collateral token.
     * @param _collateral_token ERC20 address of the collateral token.
     * @param _pool_address Address of the Ubiquity Pool.
     * @param _credits Address of the Ubiquity Credit Token.
     * @param _dollar Address of the Ubiquity Dollar Token.
     */
    function init(
        address _custodian_address,
        address _timelock_address,
        address _collateral_address,
        address _collateral_token,
        address _pool_address,
        address _credits,
        address _dollar
    ) internal {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        minterStorage.dollarDollarBalanceStored = 0;
        minterStorage.collatDollarBalanceStored = 0;
        minterStorage.collat_borrowed_sum = 0;
        minterStorage.credits_mint_sum = 0;
        minterStorage.dollar_mint_sum = 0;
        minterStorage.min_cr = 810000;
        minterStorage.credits_mint_cap = int256(100000000e18);
        minterStorage.dollar_mint_cap = int256(100000000e18);
        minterStorage.collat_borrow_cap = int256(10000000e6);
        minterStorage.CREDITS = IUbiquityCreditToken(_credits);
        minterStorage.DOLLAR = IUbiquityDollarToken(_dollar);

        // Pool related
        minterStorage.pool = IUbiquityPool(_pool_address);
        minterStorage.custodian_address = _custodian_address;
        minterStorage.timelock_address = _timelock_address;

        // Collateral related
        minterStorage.collateral_address = _collateral_address;

        uint256 index = minterStorage.pool.getCollateralAddressToIndex(
            _collateral_address
        );

        minterStorage.col_idx = index;
        minterStorage.collateral_token = ERC20(_collateral_token);
        minterStorage.missing_decimals =
            uint256(18) -
            minterStorage.collateral_token.decimals();
    }

    /* ========== MODIFIERS ========== */

    /// @notice Ensures that the provided address is a valid AMO.
    /// @param amo_address Address to be validated as an AMO.
    /// Throws an error if the address is not a registered AMO.
    modifier validAmo(address amo_address) {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        require(minterStorage.amos[amo_address], "Invalid Amo");
        _;
    }

    /* ========== VIEWS ========== */

    /// @notice Gets the dollar balance of the collateral.
    /// @return The dollar value of the collateral held.
    function collateralDollarBalance() internal view returns (uint256) {
        (, uint256 collat_val_e18) = dollarBalances();
        return collat_val_e18;
    }

    /// @notice Retrieves the index of the collateral token.
    /// @return index of the collateral token.
    function collateralIndex() internal view returns (uint256 index) {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        return minterStorage.col_idx;
    }

    /// @notice Provides the current dollar balances of Dollar Token and collateral.
    /// @return dollar_val_e18 The current dollar value of Dollar Token.
    /// @return collat_val_e18 The current dollar value of the collateral.
    function dollarBalances()
        internal
        view
        returns (uint256 dollar_val_e18, uint256 collat_val_e18)
    {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        dollar_val_e18 = minterStorage.dollarDollarBalanceStored;
        collat_val_e18 = minterStorage.collatDollarBalanceStored;
    }

    /// @notice Lists all AMO addresses registered.
    /// @return A list of AMO addresses.
    function allAmoAddresses() internal view returns (address[] memory) {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        return minterStorage.amos_array;
    }

    /// @notice Counts the total number of AMOs registered.
    /// @return The number of AMOs.
    function allAmosLength() internal view returns (uint256) {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        return minterStorage.amos_array.length;
    }

    /// @notice Calculates the global net Ubiquity Dollar Token tracked amount.
    /// @dev Computes the net dollar balance by accounting for minted dollar, borrowed collateral, and missing decimals adjustments.
    /// @return The net global dollar amount tracked, accounting for mints and borrows.
    function dollarTrackedGlobal() internal view returns (int256) {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        return
            int256(minterStorage.dollarDollarBalanceStored) -
            minterStorage.dollar_mint_sum -
            (minterStorage.collat_borrowed_sum *
                int256(10 ** minterStorage.missing_decimals));
    }

    /// @notice Calculates the Ubiquity Dollar tracked amount for a specific AMO.
    /// @dev Retrieves the dollar balance of a given AMO, applies correction offsets, and accounts for mints and borrows.
    /// @param amo_address The address of the AMO for which the balance is being calculated.
    /// @return The net dollar amount tracked for the specified AMO.
    function dollarTrackedAmo(
        address amo_address
    ) internal view returns (int256) {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        (uint256 dollar_val_e18, ) = IAmo(amo_address).dollarBalances();
        int256 dollar_val_e18_corrected = int256(dollar_val_e18) +
            minterStorage.correction_offsets_amos[amo_address][0];
        return
            dollar_val_e18_corrected -
            minterStorage.dollar_mint_balances[amo_address] -
            ((minterStorage.collat_borrowed_balances[amo_address]) *
                int256(10 ** minterStorage.missing_decimals));
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    /// @notice Synchronizes the dollar balances for all AMO.
    /// @dev Aggregates and updates the dollar and collateral dollar values from all AMO.
    /// This function can be called by anyone willing to pay the gas cost.
    function syncDollarBalances() internal {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        uint256 total_dollar_value_d18 = 0;
        uint256 total_collateral_value_d18 = 0;
        for (uint256 i = 0; i < minterStorage.amos_array.length; i++) {
            // Exclude null addresses
            address amo_address = minterStorage.amos_array[i];
            if (amo_address != address(0)) {
                (uint256 dollar_val_e18, uint256 collat_val_e18) = IAmo(
                    amo_address
                ).dollarBalances();
                total_dollar_value_d18 += uint256(
                    int256(dollar_val_e18) +
                        minterStorage.correction_offsets_amos[amo_address][0]
                );
                total_collateral_value_d18 += uint256(
                    int256(collat_val_e18) +
                        minterStorage.correction_offsets_amos[amo_address][1]
                );
            }
        }
        minterStorage.dollarDollarBalanceStored = total_dollar_value_d18;
        minterStorage.collatDollarBalanceStored = total_collateral_value_d18;
    }

    /* ========== OWNER / GOVERNANCE FUNCTIONS ONLY ========== */
    /// @dev These functions are restricted and can only be called by the owner or via timelock to limit risk.

    /// @notice Mints dollar tokens for a specified AMO.
    /// @dev Ensures that the minting does not exceed the mint cap.
    /// @param destination_amo The AMO address that will receive the minted dollar.
    /// @param dollar_amount The amount of dollar to mint.
    function mintDollarForAmo(
        address destination_amo,
        uint256 dollar_amount
    ) internal validAmo(destination_amo) {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        int256 dollar_amt_i256 = int256(dollar_amount);

        // Make sure you aren't minting more than the mint cap
        require(
            (minterStorage.dollar_mint_sum + dollar_amt_i256) <=
                minterStorage.dollar_mint_cap,
            "Mint cap reached"
        );
        minterStorage.dollar_mint_balances[destination_amo] += dollar_amt_i256;
        minterStorage.dollar_mint_sum += dollar_amt_i256;

        // Mint the dollar to the AMO
        minterStorage.DOLLAR.mint(destination_amo, dollar_amount);

        // Sync
        syncDollarBalances();
    }

    /// @notice Burns dollar tokens from the calling AMO.
    /// @param dollar_amount The amount of dollar to burn.
    function burnDollarFromAmo(
        uint256 dollar_amount
    ) internal validAmo(msg.sender) {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        int256 dollar_amt_i256 = int256(dollar_amount);

        // Burn first
        minterStorage.DOLLAR.burnFrom(msg.sender, dollar_amount);

        // Then update the balances
        minterStorage.dollar_mint_balances[msg.sender] -= dollar_amt_i256;
        minterStorage.dollar_mint_sum -= dollar_amt_i256;

        // Sync
        syncDollarBalances();
    }

    /// @notice Mints credits tokens for a specified AMO.
    /// @dev Ensures that the minting does not exceed the mint cap.
    /// @param destination_amo The AMO address that will receive the minted credits.
    /// @param credits_amount The amount of credits to mint.
    function mintCreditsForAmo(
        address destination_amo,
        uint256 credits_amount
    ) internal validAmo(destination_amo) {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        int256 credits_amt_i256 = int256(credits_amount);

        // Make sure you aren't minting more than the mint cap
        require(
            (minterStorage.credits_mint_sum + credits_amt_i256) <=
                minterStorage.credits_mint_cap,
            "Mint cap reached"
        );
        minterStorage.credits_mint_balances[
            destination_amo
        ] += credits_amt_i256;
        minterStorage.credits_mint_sum += credits_amt_i256;

        // Mint the FXS to the AMO
        minterStorage.CREDITS.mint(destination_amo, credits_amount);

        // Sync
        syncDollarBalances();
    }

    /// @notice Burns credits tokens from the calling AMO.
    /// @param credits_amount The amount of credits to burn.
    function burnCreditsFromAmo(
        uint256 credits_amount
    ) internal validAmo(msg.sender) {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        int256 credits_amt_i256 = int256(credits_amount);

        // Burn first
        minterStorage.CREDITS.burnFrom(msg.sender, credits_amount);

        // Then update the balances
        minterStorage.credits_mint_balances[msg.sender] -= credits_amt_i256;
        minterStorage.credits_mint_sum -= credits_amt_i256;

        // Sync
        syncDollarBalances();
    }

    /// @notice Transfers collateral to a specified AMO.
    /// @dev Ensures that the transfer does not exceed the borrow cap.
    /// @param destination_amo The AMO address that will receive the collateral.
    /// @param collat_amount The amount of collateral to transfer.
    function giveCollatToAmo(
        address destination_amo,
        uint256 collat_amount
    ) internal validAmo(destination_amo) {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        int256 collat_amount_i256 = int256(collat_amount);

        require(
            (minterStorage.collat_borrowed_sum + collat_amount_i256) <=
                minterStorage.collat_borrow_cap,
            "Borrow cap"
        );
        minterStorage.collat_borrowed_balances[
            destination_amo
        ] += collat_amount_i256;
        minterStorage.collat_borrowed_sum += collat_amount_i256;

        // Borrow the collateral
        minterStorage.pool.amoMinterBorrow(collat_amount);

        // Give the collateral to the AMO
        IERC20(minterStorage.collateral_address).safeTransfer(
            destination_amo,
            collat_amount
        );

        // Sync
        syncDollarBalances();
    }

    /// @notice Receives collateral back from an AMO.
    /// @param usdc_amount The amount of collateral (USDC) to receive back.
    function receiveCollatFromAmo(
        uint256 usdc_amount
    ) internal validAmo(msg.sender) {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        int256 collat_amt_i256 = int256(usdc_amount);

        // Give back first
        IERC20(minterStorage.collateral_address).safeTransferFrom(
            msg.sender,
            address(minterStorage.pool),
            usdc_amount
        );

        // Then update the balances
        minterStorage.collat_borrowed_balances[msg.sender] -= collat_amt_i256;
        minterStorage.collat_borrowed_sum -= collat_amt_i256;

        // Sync
        syncDollarBalances();
    }

    /* ========== RESTRICTED GOVERNANCE FUNCTIONS ========== */

    /// @notice Adds a new AMO.
    /// @param amo_address The address of the new AMO to add.
    /// @param sync_too Boolean indicating whether to synchronize dollar balances after adding.
    function addAmo(address amo_address, bool sync_too) internal {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        require(amo_address != address(0), "Zero address detected");

        (uint256 dollar_val_e18, uint256 collat_val_e18) = IAmo(amo_address)
            .dollarBalances();
        require(dollar_val_e18 >= 0 && collat_val_e18 >= 0, "Invalid Amo");

        require(
            minterStorage.amos[amo_address] == false,
            "Address already exists"
        );
        minterStorage.amos[amo_address] = true;
        minterStorage.amos_array.push(amo_address);

        // Mint balances
        minterStorage.dollar_mint_balances[amo_address] = 0;
        minterStorage.credits_mint_balances[amo_address] = 0;
        minterStorage.collat_borrowed_balances[amo_address] = 0;

        // Offsets
        minterStorage.correction_offsets_amos[amo_address][0] = 0;
        minterStorage.correction_offsets_amos[amo_address][1] = 0;

        if (sync_too) syncDollarBalances();

        emit AmoAdded(amo_address);
    }

    /// @notice Removes an AMO.
    /// @param amo_address The address of the AMO to remove.
    /// @param sync_too Boolean indicating whether to synchronize dollar balances after removing.
    function removeAmo(address amo_address, bool sync_too) internal {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        require(amo_address != address(0), "Zero address detected");
        require(minterStorage.amos[amo_address] == true, "Address nonexistent");

        // Delete from the mapping
        delete minterStorage.amos[amo_address];

        // 'Delete' from the array by setting the address to 0x0
        for (uint256 i = 0; i < minterStorage.amos_array.length; i++) {
            if (minterStorage.amos_array[i] == amo_address) {
                minterStorage.amos_array[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }

        if (sync_too) syncDollarBalances();

        emit AmoRemoved(amo_address);
    }

    /// @notice Sets the timelock address.
    /// @param new_timelock The new address to be set as the timelock.
    /// @dev This function updates the timelock address and ensures it is not a zero address.
    function setTimelock(address new_timelock) internal {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        require(new_timelock != address(0), "Timelock address cannot be 0");
        minterStorage.timelock_address = new_timelock;
    }

    /// @notice Sets the custodian address.
    /// @param _custodian_address The new address to be set as the custodian.
    /// @dev This function updates the custodian address and ensures it is not a zero address.
    function setCustodian(address _custodian_address) internal {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        require(
            _custodian_address != address(0),
            "Custodian address cannot be 0"
        );
        minterStorage.custodian_address = _custodian_address;
    }

    /// @notice Sets the dollar mint cap.
    /// @param _dollar_mint_cap The new dollar mint cap to be set.
    /// @dev This function updates the dollar mint cap.
    function setDollarMintCap(uint256 _dollar_mint_cap) internal {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        minterStorage.dollar_mint_cap = int256(_dollar_mint_cap);
    }

    /// @notice Sets the credits mint cap.
    /// @param _credits_mint_cap The new credits mint cap to be set.
    /// @dev This function updates the credits mint cap.
    function setCreditsMintCap(uint256 _credits_mint_cap) internal {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        minterStorage.credits_mint_cap = int256(_credits_mint_cap);
    }

    /// @notice Sets the collateral borrow cap.
    /// @param _collat_borrow_cap The new collateral borrow cap to be set.
    /// @dev This function updates the collateral borrow cap.
    function setCollatBorrowCap(uint256 _collat_borrow_cap) internal {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        minterStorage.collat_borrow_cap = int256(_collat_borrow_cap);
    }

    /// @notice Sets the minimum collateral ratio.
    /// @param _min_cr The new minimum collateral ratio to be set.
    /// @dev This function updates the minimum collateral ratio.
    function setMinimumCollateralRatio(uint256 _min_cr) internal {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        minterStorage.min_cr = _min_cr;
    }

    /// @notice Sets correction offsets for a specific AMO.
    /// @param amo_address The address of the AMO for which to set correction offsets.
    /// @param dollar_e18_correction The correction offset for dollar.
    /// @param collat_e18_correction The correction offset for collateral.
    /// @dev This function updates the correction offsets for a given AMO and syncs dollar balances.
    function setAmoCorrectionOffsets(
        address amo_address,
        int256 dollar_e18_correction,
        int256 collat_e18_correction
    ) internal {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        minterStorage.correction_offsets_amos[amo_address][
            0
        ] = dollar_e18_correction;
        minterStorage.correction_offsets_amos[amo_address][
            1
        ] = collat_e18_correction;

        syncDollarBalances();
    }

    /// @notice Sets the pool and collateral address for dollar operations.
    /// @param _pool_address The new pool address to be set.
    /// @param _collateral_address The new collateral address to be set.
    /// @dev This function updates the pool and collateral addresses and ensures they match the system's configuration.
    function setDollarPool(
        address _pool_address,
        address _collateral_address
    ) internal {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        minterStorage.pool = IUbiquityPool(_pool_address);

        uint256 index = minterStorage.pool.getCollateralAddressToIndex(
            _collateral_address
        );
        // Make sure the collaterals match, or balances could get corrupted
        require(index == minterStorage.col_idx, "col_idx mismatch");
    }

    /// @notice Recovers ERC20 tokens accidentally sent to the contract.
    /// @param tokenAddress The address of the ERC20 token to recover.
    /// @param tokenAmount The amount of the ERC20 token to recover.
    /// @dev This function can only be triggered by the owner or governance and transfers the specified token amount to the custodian.
    function recoverERC20(address tokenAddress, uint256 tokenAmount) internal {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        // Can only be triggered by owner or governance
        IERC20(tokenAddress).safeTransfer(
            minterStorage.custodian_address,
            tokenAmount
        );

        emit Recovered(tokenAddress, tokenAmount);
    }
}
