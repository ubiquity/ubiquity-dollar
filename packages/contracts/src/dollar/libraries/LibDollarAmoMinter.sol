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
    event AmoAdded(address indexed amoAddress);

    /// @notice Emitted when an AMO is removed.
    event AmoRemoved(address indexed amoAddress);

    /// @notice Emitted when ERC20 tokens are recovered.
    event Recovered(address indexed token, uint256 amount);

    /* ========== STATE VARIABLES ========== */
    /// @notice Struct to hold AMO minter data.
    struct DollarAmoMinterData {
        // Core
        IUbiquityDollarToken DOLLAR;
        IUbiquityCreditToken CREDITS;
        ERC20 collateralToken;
        IUbiquityPool pool;
        address timelockAddress;
        address custodianAddress;
        // Collateral related
        address collateralAddress;
        uint256 colIdx;
        // AMO addresses
        address[] amosArray;
        mapping(address => bool) amos; // Mapping is also used for faster verification
        // Max amount of collateral the contract can borrow from the UbiquityPool
        int256 collatBorrowCap;
        // Max amount of dollar and credits this contract can mint
        int256 dollarMintCap;
        int256 creditsMintCap;
        // Minimum collateral ratio needed for new dollar minting
        uint256 minCr;
        // dollar mint balances
        mapping(address => int256) dollarMintBalances; // Amount of Dollar the contract minted, by AMO
        int256 dollarMintSum; // Across all AMOs
        // credits mint balances
        mapping(address => int256) creditsMintBalances; // Amount of Credits the contract minted, by AMO
        int256 creditsMintSum; // Across all AMOs
        // Collateral borrowed balances
        mapping(address => int256) collatBorrowedBalances; // Amount of collateral the contract borrowed, by AMO
        int256 collatBorrowedSum; // Across all AMOs
        // dollar balance related
        uint256 dollarDollarBalanceStored;
        // Collateral balance related
        uint256 missingDecimals;
        uint256 collatDollarBalanceStored;
        // AMO balance corrections
        mapping(address => int256[2]) correctionOffsetsAmos;
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
     * @param _custodianAddress Address of the custodian.
     * @param _timelockAddress Address of the timelock.
     * @param _collateralAddress Address of the collateral token.
     * @param _collateralToken ERC20 address of the collateral token.
     * @param _poolAddress Address of the Ubiquity Pool.
     * @param _credits Address of the Ubiquity Credit Token.
     * @param _dollar Address of the Ubiquity Dollar Token.
     */
    function init(
        address _custodianAddress,
        address _timelockAddress,
        address _collateralAddress,
        address _collateralToken,
        address _poolAddress,
        address _credits,
        address _dollar
    ) internal {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        minterStorage.dollarDollarBalanceStored = 0;
        minterStorage.collatDollarBalanceStored = 0;
        minterStorage.collatBorrowedSum = 0;
        minterStorage.creditsMintSum = 0;
        minterStorage.dollarMintSum = 0;
        minterStorage.minCr = 810000;
        minterStorage.creditsMintCap = int256(100000000e18);
        minterStorage.dollarMintCap = int256(100000000e18);
        minterStorage.collatBorrowCap = int256(10000000e6);
        minterStorage.CREDITS = IUbiquityCreditToken(_credits);
        minterStorage.DOLLAR = IUbiquityDollarToken(_dollar);

        // Pool related
        minterStorage.pool = IUbiquityPool(_poolAddress);
        minterStorage.custodianAddress = _custodianAddress;
        minterStorage.timelockAddress = _timelockAddress;

        // Collateral related
        minterStorage.collateralAddress = _collateralAddress;

        uint256 index = minterStorage.pool.getCollateralAddressToIndex(
            _collateralAddress
        );

        minterStorage.colIdx = index;
        minterStorage.collateralToken = ERC20(_collateralToken);
        minterStorage.missingDecimals =
            uint256(18) -
            minterStorage.collateralToken.decimals();
    }

    /* ========== MODIFIERS ========== */

    /// @notice Ensures that the provided address is a valid AMO.
    /// @param _amoAddress Address to be validated as an AMO.
    /// Throws an error if the address is not a registered AMO.
    modifier validAmo(address _amoAddress) {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        require(minterStorage.amos[_amoAddress], "Invalid Amo");
        _;
    }

    /* ========== VIEWS ========== */

    /// @notice Gets the dollar balance of the collateral.
    /// @return The dollar value of the collateral held.
    function collateralDollarBalance() internal view returns (uint256) {
        (, uint256 collatValE18) = dollarBalances();
        return collatValE18;
    }

    /// @notice Retrieves the index of the collateral token.
    /// @return index of the collateral token.
    function collateralIndex() internal view returns (uint256 index) {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        return minterStorage.colIdx;
    }

    /// @notice Provides the current dollar balances of Dollar Token and collateral.
    /// @return dollarValE18 The current dollar value of Dollar Token.
    /// @return collatValE18 The current dollar value of the collateral.
    function dollarBalances()
        internal
        view
        returns (uint256 dollarValE18, uint256 collatValE18)
    {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        dollarValE18 = minterStorage.dollarDollarBalanceStored;
        collatValE18 = minterStorage.collatDollarBalanceStored;
    }

    /// @notice Lists all AMO addresses registered.
    /// @return A list of AMO addresses.
    function allAmoAddresses() internal view returns (address[] memory) {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        return minterStorage.amosArray;
    }

    /// @notice Counts the total number of AMOs registered.
    /// @return The number of AMOs.
    function allAmosLength() internal view returns (uint256) {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        return minterStorage.amosArray.length;
    }

    /// @notice Calculates the global net Ubiquity Dollar Token tracked amount.
    /// @dev Computes the net dollar balance by accounting for minted dollar, borrowed collateral, and missing decimals adjustments.
    /// @return The net global dollar amount tracked, accounting for mints and borrows.
    function dollarTrackedGlobal() internal view returns (int256) {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        return
            int256(minterStorage.dollarDollarBalanceStored) -
            minterStorage.dollarMintSum -
            (minterStorage.collatBorrowedSum *
                int256(10 ** minterStorage.missingDecimals));
    }

    /// @notice Calculates the Ubiquity Dollar tracked amount for a specific AMO.
    /// @dev Retrieves the dollar balance of a given AMO, applies correction offsets, and accounts for mints and borrows.
    /// @param _amoAddress The address of the AMO for which the balance is being calculated.
    /// @return The net dollar amount tracked for the specified AMO.
    function dollarTrackedAmo(
        address _amoAddress
    ) internal view returns (int256) {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        (uint256 dollarValE18, ) = IAmo(_amoAddress).dollarBalances();
        int256 dollarValE18Corrected = int256(dollarValE18) +
            minterStorage.correctionOffsetsAmos[_amoAddress][0];
        return
            dollarValE18Corrected -
            minterStorage.dollarMintBalances[_amoAddress] -
            ((minterStorage.collatBorrowedBalances[_amoAddress]) *
                int256(10 ** minterStorage.missingDecimals));
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    /// @notice Synchronizes the dollar balances for all AMO.
    /// @dev Aggregates and updates the dollar and collateral dollar values from all AMO.
    /// This function can be called by anyone willing to pay the gas cost.
    function syncDollarBalances() internal {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        uint256 totalDollarValueD18 = 0;
        uint256 totalCollateralValueD18 = 0;
        for (uint256 i = 0; i < minterStorage.amosArray.length; i++) {
            // Exclude null addresses
            address amoAddress = minterStorage.amosArray[i];
            if (amoAddress != address(0)) {
                (uint256 dollarValE18, uint256 collatValE18) = IAmo(amoAddress)
                    .dollarBalances();
                totalDollarValueD18 += uint256(
                    int256(dollarValE18) +
                        minterStorage.correctionOffsetsAmos[amoAddress][0]
                );
                totalCollateralValueD18 += uint256(
                    int256(collatValE18) +
                        minterStorage.correctionOffsetsAmos[amoAddress][1]
                );
            }
        }
        minterStorage.dollarDollarBalanceStored = totalDollarValueD18;
        minterStorage.collatDollarBalanceStored = totalCollateralValueD18;
    }

    /* ========== OWNER / GOVERNANCE FUNCTIONS ONLY ========== */
    /// @dev These functions are restricted and can only be called by the owner or via timelock to limit risk.

    /// @notice Mints dollar tokens for a specified AMO.
    /// @dev Ensures that the minting does not exceed the mint cap.
    /// @param _destinationAmo The AMO address that will receive the minted dollar.
    /// @param _dollarAmount The amount of dollar to mint.
    function mintDollarForAmo(
        address _destinationAmo,
        uint256 _dollarAmount
    ) internal validAmo(_destinationAmo) {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        int256 dollarAmtI256 = int256(_dollarAmount);

        // Make sure you aren't minting more than the mint cap
        require(
            (minterStorage.dollarMintSum + dollarAmtI256) <=
                minterStorage.dollarMintCap,
            "Mint cap reached"
        );
        minterStorage.dollarMintBalances[_destinationAmo] += dollarAmtI256;
        minterStorage.dollarMintSum += dollarAmtI256;

        // Mint the dollar to the AMO
        minterStorage.DOLLAR.mint(_destinationAmo, _dollarAmount);

        // Sync
        syncDollarBalances();
    }

    /// @notice Burns dollar tokens from the calling AMO.
    /// @param _dollarAmount The amount of dollar to burn.
    function burnDollarFromAmo(
        uint256 _dollarAmount
    ) internal validAmo(msg.sender) {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        int256 dollarAmtI256 = int256(_dollarAmount);

        // Burn first
        minterStorage.DOLLAR.burnFrom(msg.sender, _dollarAmount);

        // Then update the balances
        minterStorage.dollarMintBalances[msg.sender] -= dollarAmtI256;
        minterStorage.dollarMintSum -= dollarAmtI256;

        // Sync
        syncDollarBalances();
    }

    /// @notice Mints credits tokens for a specified AMO.
    /// @dev Ensures that the minting does not exceed the mint cap.
    /// @param _destinationAmo The AMO address that will receive the minted credits.
    /// @param _creditsAmount The amount of credits to mint.
    function mintCreditsForAmo(
        address _destinationAmo,
        uint256 _creditsAmount
    ) internal validAmo(_destinationAmo) {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        int256 creditsAmtI256 = int256(_creditsAmount);

        // Make sure you aren't minting more than the mint cap
        require(
            (minterStorage.creditsMintSum + creditsAmtI256) <=
                minterStorage.creditsMintCap,
            "Mint cap reached"
        );
        minterStorage.creditsMintBalances[_destinationAmo] += creditsAmtI256;
        minterStorage.creditsMintSum += creditsAmtI256;

        // Mint the FXS to the AMO
        minterStorage.CREDITS.mint(_destinationAmo, _creditsAmount);

        // Sync
        syncDollarBalances();
    }

    /// @notice Burns credits tokens from the calling AMO.
    /// @param _creditsAmount The amount of credits to burn.
    function burnCreditsFromAmo(
        uint256 _creditsAmount
    ) internal validAmo(msg.sender) {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        int256 creditsAmtI256 = int256(_creditsAmount);

        // Burn first
        minterStorage.CREDITS.burnFrom(msg.sender, _creditsAmount);

        // Then update the balances
        minterStorage.creditsMintBalances[msg.sender] -= creditsAmtI256;
        minterStorage.creditsMintSum -= creditsAmtI256;

        // Sync
        syncDollarBalances();
    }

    /// @notice Transfers collateral to a specified AMO.
    /// @dev Ensures that the transfer does not exceed the borrow cap.
    /// @param _destinationAmo The AMO address that will receive the collateral.
    /// @param _collatAmount The amount of collateral to transfer.
    function giveCollatToAmo(
        address _destinationAmo,
        uint256 _collatAmount
    ) internal validAmo(_destinationAmo) {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        int256 collatAmountI256 = int256(_collatAmount);

        require(
            (minterStorage.collatBorrowedSum + collatAmountI256) <=
                minterStorage.collatBorrowCap,
            "Borrow cap"
        );
        minterStorage.collatBorrowedBalances[
            _destinationAmo
        ] += collatAmountI256;
        minterStorage.collatBorrowedSum += collatAmountI256;

        // Borrow the collateral
        minterStorage.pool.amoMinterBorrow(_collatAmount);

        // Give the collateral to the AMO
        IERC20(minterStorage.collateralAddress).safeTransfer(
            _destinationAmo,
            _collatAmount
        );

        // Sync
        syncDollarBalances();
    }

    /// @notice Receives collateral back from an AMO.
    /// @param _usdcAmount The amount of collateral (USDC) to receive back.
    function receiveCollatFromAmo(
        uint256 _usdcAmount
    ) internal validAmo(msg.sender) {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        int256 collatAmtI256 = int256(_usdcAmount);

        // Give back first
        IERC20(minterStorage.collateralAddress).safeTransferFrom(
            msg.sender,
            address(minterStorage.pool),
            _usdcAmount
        );

        // Then update the balances
        minterStorage.collatBorrowedBalances[msg.sender] -= collatAmtI256;
        minterStorage.collatBorrowedSum -= collatAmtI256;

        // Sync
        syncDollarBalances();
    }

    /* ========== RESTRICTED GOVERNANCE FUNCTIONS ========== */

    /// @notice Adds a new AMO.
    /// @param _amoAddress The address of the new AMO to add.
    /// @param _syncToo Boolean indicating whether to synchronize dollar balances after adding.
    function addAmo(address _amoAddress, bool _syncToo) internal {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        require(_amoAddress != address(0), "Zero address detected");

        (uint256 dollarValE18, uint256 collatValE18) = IAmo(_amoAddress)
            .dollarBalances();
        require(dollarValE18 >= 0 && collatValE18 >= 0, "Invalid Amo");

        require(
            minterStorage.amos[_amoAddress] == false,
            "Address already exists"
        );
        minterStorage.amos[_amoAddress] = true;
        minterStorage.amosArray.push(_amoAddress);

        // Mint balances
        minterStorage.dollarMintBalances[_amoAddress] = 0;
        minterStorage.creditsMintBalances[_amoAddress] = 0;
        minterStorage.collatBorrowedBalances[_amoAddress] = 0;

        // Offsets
        minterStorage.correctionOffsetsAmos[_amoAddress][0] = 0;
        minterStorage.correctionOffsetsAmos[_amoAddress][1] = 0;

        if (_syncToo) syncDollarBalances();

        emit AmoAdded(_amoAddress);
    }

    /// @notice Removes an AMO.
    /// @param _amoAddress The address of the AMO to remove.
    /// @param _syncToo Boolean indicating whether to synchronize dollar balances after removing.
    function removeAmo(address _amoAddress, bool _syncToo) internal {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        require(_amoAddress != address(0), "Zero address detected");
        require(minterStorage.amos[_amoAddress] == true, "Address nonexistent");

        // Delete from the mapping
        delete minterStorage.amos[_amoAddress];

        // 'Delete' from the array by setting the address to 0x0
        for (uint256 i = 0; i < minterStorage.amosArray.length; i++) {
            if (minterStorage.amosArray[i] == _amoAddress) {
                minterStorage.amosArray[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }

        if (_syncToo) syncDollarBalances();

        emit AmoRemoved(_amoAddress);
    }

    /// @notice Sets the timelock address.
    /// @param _newTimelock The new address to be set as the timelock.
    /// @dev This function updates the timelock address and ensures it is not a zero address.
    function setTimelock(address _newTimelock) internal {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        require(_newTimelock != address(0), "Timelock address cannot be 0");
        minterStorage.timelockAddress = _newTimelock;
    }

    /// @notice Sets the custodian address.
    /// @param _custodianAddress The new address to be set as the custodian.
    /// @dev This function updates the custodian address and ensures it is not a zero address.
    function setCustodian(address _custodianAddress) internal {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        require(
            _custodianAddress != address(0),
            "Custodian address cannot be 0"
        );
        minterStorage.custodianAddress = _custodianAddress;
    }

    /// @notice Sets the dollar mint cap.
    /// @param _dollarMintCap The new dollar mint cap to be set.
    /// @dev This function updates the dollar mint cap.
    function setDollarMintCap(uint256 _dollarMintCap) internal {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        minterStorage.dollarMintCap = int256(_dollarMintCap);
    }

    /// @notice Sets the credits mint cap.
    /// @param _creditsMintCap The new credits mint cap to be set.
    /// @dev This function updates the credits mint cap.
    function setCreditsMintCap(uint256 _creditsMintCap) internal {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        minterStorage.creditsMintCap = int256(_creditsMintCap);
    }

    /// @notice Sets the collateral borrow cap.
    /// @param _collatBorrowCap The new collateral borrow cap to be set.
    /// @dev This function updates the collateral borrow cap.
    function setCollatBorrowCap(uint256 _collatBorrowCap) internal {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        minterStorage.collatBorrowCap = int256(_collatBorrowCap);
    }

    /// @notice Sets the minimum collateral ratio.
    /// @param _minCr The new minimum collateral ratio to be set.
    /// @dev This function updates the minimum collateral ratio.
    function setMinimumCollateralRatio(uint256 _minCr) internal {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        minterStorage.minCr = _minCr;
    }

    /// @notice Sets correction offsets for a specific AMO.
    /// @param _amoAddress The address of the AMO for which to set correction offsets.
    /// @param _dollarE18Correction The correction offset for dollar.
    /// @param _collatE18Correction The correction offset for collateral.
    /// @dev This function updates the correction offsets for a given AMO and syncs dollar balances.
    function setAmoCorrectionOffsets(
        address _amoAddress,
        int256 _dollarE18Correction,
        int256 _collatE18Correction
    ) internal {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        minterStorage.correctionOffsetsAmos[_amoAddress][
            0
        ] = _dollarE18Correction;
        minterStorage.correctionOffsetsAmos[_amoAddress][
            1
        ] = _collatE18Correction;

        syncDollarBalances();
    }

    /// @notice Sets the pool and collateral address for dollar operations.
    /// @param _poolAddress The new pool address to be set.
    /// @param _collateralAddress The new collateral address to be set.
    /// @dev This function updates the pool and collateral addresses and ensures they match the system's configuration.
    function setDollarPool(
        address _poolAddress,
        address _collateralAddress
    ) internal {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        minterStorage.pool = IUbiquityPool(_poolAddress);

        uint256 index = minterStorage.pool.getCollateralAddressToIndex(
            _collateralAddress
        );
        // Make sure the collaterals match, or balances could get corrupted
        require(index == minterStorage.colIdx, "colIdx mismatch");
    }

    /// @notice Recovers ERC20 tokens accidentally sent to the contract.
    /// @param _tokenAddress The address of the ERC20 token to recover.
    /// @param _tokenAmount The amount of the ERC20 token to recover.
    /// @dev This function can only be triggered by the owner or governance and transfers the specified token amount to the custodian.
    function recoverERC20(
        address _tokenAddress,
        uint256 _tokenAmount
    ) internal {
        DollarAmoMinterData storage minterStorage = dollarAmoMinterStorage();

        // Can only be triggered by owner or governance
        IERC20(_tokenAddress).safeTransfer(
            minterStorage.custodianAddress,
            _tokenAmount
        );

        emit Recovered(_tokenAddress, _tokenAmount);
    }
}
