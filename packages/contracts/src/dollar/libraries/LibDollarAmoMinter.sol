// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../core/UbiquityDollarToken.sol";
import "../interfaces/IUbiquityPool.sol";
import "../interfaces/IUbiquityDollarToken.sol";
import "../interfaces/IUbiquityCreditToken.sol";
import "../interfaces/IAMO.sol";
import "./Constants.sol";
import "../utils/TransferHelper.sol";

library LibDollarAmoMinter {
    bytes32 constant AMOMINTER_CONTROL_STORAGE_SLOT =
        bytes32(uint256(keccak256("ubiquity.contracts.amominter.storage")) - 1);

    /* ========== EVENTS ========== */

    event AMOAdded(address amo_address);
    event AMORemoved(address amo_address);
    event Recovered(address token, uint256 amount);

    /* ========== STATE VARIABLES ========== */
    struct DollarAmoMinterData {
        // Core
        IUbiquityDollarToken UAD;
        IUbiquityCreditToken UCR;
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
        // Max amount of uad and ucr this contract can mint
        int256 uad_mint_cap;
        int256 ucr_mint_cap;
        // Minimum collateral ratio needed for new uad minting
        uint256 min_cr;
        // uad mint balances
        mapping(address => int256) uad_mint_balances; // Amount of FRAX the contract minted, by AMO
        int256 uad_mint_sum; // Across all AMOs
        // ucr mint balances
        mapping(address => int256) ucr_mint_balances; // Amount of FXS the contract minted, by AMO
        int256 ucr_mint_sum; // Across all AMOs
        // Collateral borrowed balances
        mapping(address => int256) collat_borrowed_balances; // Amount of collateral the contract borrowed, by AMO
        int256 collat_borrowed_sum; // Across all AMOs
        // uad balance related
        uint256 uadDollarBalanceStored;
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

    function init(
        address _custodian_address,
        address _timelock_address,
        address _collateral_address,
        address _collateral_token,
        address _pool_address,
        address _ucr,
        address _uad
    ) internal {
        dollarAmoMinterStorage().uadDollarBalanceStored = 0;
        dollarAmoMinterStorage().collatDollarBalanceStored = 0;
        dollarAmoMinterStorage().collat_borrowed_sum = 0;
        dollarAmoMinterStorage().ucr_mint_sum = 0;
        dollarAmoMinterStorage().uad_mint_sum = 0;
        dollarAmoMinterStorage().min_cr = 810000;
        dollarAmoMinterStorage().ucr_mint_cap = int256(100000000e18);
        dollarAmoMinterStorage().uad_mint_cap = int256(100000000e18);
        dollarAmoMinterStorage().collat_borrow_cap = int256(10000000e6);
        dollarAmoMinterStorage().UCR = IUbiquityCreditToken(_ucr);
        dollarAmoMinterStorage().UAD = IUbiquityDollarToken(_uad);

        // Pool related
        dollarAmoMinterStorage().pool = IUbiquityPool(_pool_address);
        dollarAmoMinterStorage().custodian_address = _custodian_address;
        dollarAmoMinterStorage().timelock_address = _timelock_address;

        // Collateral related
        dollarAmoMinterStorage().collateral_address = _collateral_address;

        uint256 index = dollarAmoMinterStorage()
            .pool
            .getCollateralAddressToIndex(_collateral_address);

        dollarAmoMinterStorage().col_idx = index;
        dollarAmoMinterStorage().collateral_token = ERC20(_collateral_token);
        dollarAmoMinterStorage().missing_decimals =
            uint(18) -
            dollarAmoMinterStorage().collateral_token.decimals();
    }

    /* ========== MODIFIERS ========== */

    modifier validAMO(address amo_address) {
        require(dollarAmoMinterStorage().amos[amo_address], "Invalid AMO");
        _;
    }

    /* ========== VIEWS ========== */

    function collateralDollarBalance() internal view returns (uint256) {
        (, uint256 collat_val_e18) = dollarBalances();
        return collat_val_e18;
    }

    function collateralIndex() internal view returns (uint256 index) {
        return dollarAmoMinterStorage().col_idx;
    }

    function dollarBalances()
        internal
        view
        returns (uint256 uad_val_e18, uint256 collat_val_e18)
    {
        uad_val_e18 = dollarAmoMinterStorage().uadDollarBalanceStored;
        collat_val_e18 = dollarAmoMinterStorage().collatDollarBalanceStored;
    }

    function allAMOAddresses() internal view returns (address[] memory) {
        return dollarAmoMinterStorage().amos_array;
    }

    function allAMOsLength() internal view returns (uint256) {
        return dollarAmoMinterStorage().amos_array.length;
    }

    function uadTrackedGlobal() internal view returns (int256) {
        return
            int256(dollarAmoMinterStorage().uadDollarBalanceStored) -
            dollarAmoMinterStorage().uad_mint_sum -
            (dollarAmoMinterStorage().collat_borrowed_sum *
                int256(10 ** dollarAmoMinterStorage().missing_decimals));
    }

    function uadTrackedAMO(address amo_address) internal view returns (int256) {
        (uint256 uad_val_e18, ) = IAMO(amo_address).dollarBalances();
        int256 uad_val_e18_corrected = int256(uad_val_e18) +
            dollarAmoMinterStorage().correction_offsets_amos[amo_address][0];
        return
            uad_val_e18_corrected -
            dollarAmoMinterStorage().uad_mint_balances[amo_address] -
            ((dollarAmoMinterStorage().collat_borrowed_balances[amo_address]) *
                int256(10 ** dollarAmoMinterStorage().missing_decimals));
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // Callable by anyone willing to pay the gas
    function syncDollarBalances() internal {
        uint256 total_uad_value_d18 = 0;
        uint256 total_collateral_value_d18 = 0;
        for (uint i = 0; i < dollarAmoMinterStorage().amos_array.length; i++) {
            // Exclude null addresses
            address amo_address = dollarAmoMinterStorage().amos_array[i];
            if (amo_address != address(0)) {
                (uint256 uad_val_e18, uint256 collat_val_e18) = IAMO(
                    amo_address
                ).dollarBalances();
                total_uad_value_d18 += uint256(
                    int256(uad_val_e18) +
                        dollarAmoMinterStorage().correction_offsets_amos[
                            amo_address
                        ][0]
                );
                total_collateral_value_d18 += uint256(
                    int256(collat_val_e18) +
                        dollarAmoMinterStorage().correction_offsets_amos[
                            amo_address
                        ][1]
                );
            }
        }
        dollarAmoMinterStorage().uadDollarBalanceStored = total_uad_value_d18;
        dollarAmoMinterStorage()
            .collatDollarBalanceStored = total_collateral_value_d18;
    }

    /* ========== OWNER / GOVERNANCE FUNCTIONS ONLY ========== */
    // Only owner or timelock can call, to limit risk

    // ------------------------------------------------------------------
    // ------------------------------ UAD -------------------------------
    // ------------------------------------------------------------------

    // This contract is essentially marked as a 'pool' so it can call OnlyPools functions like pool_mint and pool_burn_from
    // on the main UAD contract
    function mintUadForAMO(
        address destination_amo,
        uint256 uad_amount
    ) internal validAMO(destination_amo) {
        int256 uad_amt_i256 = int256(uad_amount);

        // Make sure you aren't minting more than the mint cap
        require(
            (dollarAmoMinterStorage().uad_mint_sum + uad_amt_i256) <=
                dollarAmoMinterStorage().uad_mint_cap,
            "Mint cap reached"
        );
        dollarAmoMinterStorage().uad_mint_balances[
            destination_amo
        ] += uad_amt_i256;
        dollarAmoMinterStorage().uad_mint_sum += uad_amt_i256;

        // Mint the FRAX to the AMO
        dollarAmoMinterStorage().UAD.mint(destination_amo, uad_amount);

        // Sync
        syncDollarBalances();
    }

    function burnUadFromAMO(uint256 uad_amount) internal validAMO(msg.sender) {
        int256 uad_amt_i256 = int256(uad_amount);

        // Burn first
        dollarAmoMinterStorage().UAD.burnFrom(msg.sender, uad_amount);

        // Then update the balances
        dollarAmoMinterStorage().uad_mint_balances[msg.sender] -= uad_amt_i256;
        dollarAmoMinterStorage().uad_mint_sum -= uad_amt_i256;

        // Sync
        syncDollarBalances();
    }

    // ------------------------------------------------------------------
    // ------------------------------- UCR ------------------------------
    // ------------------------------------------------------------------

    function mintUcrForAMO(
        address destination_amo,
        uint256 ucr_amount
    ) internal validAMO(destination_amo) {
        int256 ucr_amt_i256 = int256(ucr_amount);

        // Make sure you aren't minting more than the mint cap
        require(
            (dollarAmoMinterStorage().ucr_mint_sum + ucr_amt_i256) <=
                dollarAmoMinterStorage().ucr_mint_cap,
            "Mint cap reached"
        );
        dollarAmoMinterStorage().ucr_mint_balances[
            destination_amo
        ] += ucr_amt_i256;
        dollarAmoMinterStorage().ucr_mint_sum += ucr_amt_i256;

        // Mint the FXS to the AMO
        dollarAmoMinterStorage().UCR.mint(destination_amo, ucr_amount);

        // Sync
        syncDollarBalances();
    }

    function burnUcrFromAMO(uint256 ucr_amount) internal validAMO(msg.sender) {
        int256 ucr_amt_i256 = int256(ucr_amount);

        // Burn first
        dollarAmoMinterStorage().UCR.burnFrom(msg.sender, ucr_amount);

        // Then update the balances
        dollarAmoMinterStorage().ucr_mint_balances[msg.sender] -= ucr_amt_i256;
        dollarAmoMinterStorage().ucr_mint_sum -= ucr_amt_i256;

        // Sync
        syncDollarBalances();
    }

    // ------------------------------------------------------------------
    // --------------------------- Collateral ---------------------------
    // ------------------------------------------------------------------

    function giveCollatToAMO(
        address destination_amo,
        uint256 collat_amount
    ) internal validAMO(destination_amo) {
        int256 collat_amount_i256 = int256(collat_amount);

        require(
            (dollarAmoMinterStorage().collat_borrowed_sum +
                collat_amount_i256) <=
                dollarAmoMinterStorage().collat_borrow_cap,
            "Borrow cap"
        );
        dollarAmoMinterStorage().collat_borrowed_balances[
            destination_amo
        ] += collat_amount_i256;
        dollarAmoMinterStorage().collat_borrowed_sum += collat_amount_i256;

        // Borrow the collateral
        dollarAmoMinterStorage().pool.amoMinterBorrow(collat_amount);

        // Give the collateral to the AMO
        TransferHelper.safeTransfer(
            dollarAmoMinterStorage().collateral_address,
            destination_amo,
            collat_amount
        );

        // Sync
        syncDollarBalances();
    }

    function receiveCollatFromAMO(
        uint256 usdc_amount
    ) internal validAMO(msg.sender) {
        int256 collat_amt_i256 = int256(usdc_amount);

        // Give back first
        TransferHelper.safeTransferFrom(
            dollarAmoMinterStorage().collateral_address,
            msg.sender,
            address(dollarAmoMinterStorage().pool),
            usdc_amount
        );

        // Then update the balances
        dollarAmoMinterStorage().collat_borrowed_balances[
            msg.sender
        ] -= collat_amt_i256;
        dollarAmoMinterStorage().collat_borrowed_sum -= collat_amt_i256;

        // Sync
        syncDollarBalances();
    }

    /* ========== RESTRICTED GOVERNANCE FUNCTIONS ========== */

    // Adds an AMO
    function addAMO(address amo_address, bool sync_too) internal {
        require(amo_address != address(0), "Zero address detected");

        (uint256 uad_val_e18, uint256 collat_val_e18) = IAMO(amo_address)
            .dollarBalances();
        require(uad_val_e18 >= 0 && collat_val_e18 >= 0, "Invalid AMO");

        require(
            dollarAmoMinterStorage().amos[amo_address] == false,
            "Address already exists"
        );
        dollarAmoMinterStorage().amos[amo_address] = true;
        dollarAmoMinterStorage().amos_array.push(amo_address);

        // Mint balances
        dollarAmoMinterStorage().uad_mint_balances[amo_address] = 0;
        dollarAmoMinterStorage().ucr_mint_balances[amo_address] = 0;
        dollarAmoMinterStorage().collat_borrowed_balances[amo_address] = 0;

        // Offsets
        dollarAmoMinterStorage().correction_offsets_amos[amo_address][0] = 0;
        dollarAmoMinterStorage().correction_offsets_amos[amo_address][1] = 0;

        if (sync_too) syncDollarBalances();

        emit AMOAdded(amo_address);
    }

    // Removes an AMO
    function removeAMO(address amo_address, bool sync_too) internal {
        require(amo_address != address(0), "Zero address detected");
        require(
            dollarAmoMinterStorage().amos[amo_address] == true,
            "Address nonexistent"
        );

        // Delete from the mapping
        delete dollarAmoMinterStorage().amos[amo_address];

        // 'Delete' from the array by setting the address to 0x0
        for (uint i = 0; i < dollarAmoMinterStorage().amos_array.length; i++) {
            if (dollarAmoMinterStorage().amos_array[i] == amo_address) {
                dollarAmoMinterStorage().amos_array[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }

        if (sync_too) syncDollarBalances();

        emit AMORemoved(amo_address);
    }

    function setTimelock(address new_timelock) internal {
        require(new_timelock != address(0), "Timelock address cannot be 0");
        dollarAmoMinterStorage().timelock_address = new_timelock;
    }

    function setCustodian(address _custodian_address) internal {
        require(
            _custodian_address != address(0),
            "Custodian address cannot be 0"
        );
        dollarAmoMinterStorage().custodian_address = _custodian_address;
    }

    function setUadMintCap(uint256 _uad_mint_cap) internal {
        dollarAmoMinterStorage().uad_mint_cap = int256(_uad_mint_cap);
    }

    function setUcrMintCap(uint256 _ucr_mint_cap) internal {
        dollarAmoMinterStorage().ucr_mint_cap = int256(_ucr_mint_cap);
    }

    function setCollatBorrowCap(uint256 _collat_borrow_cap) internal {
        dollarAmoMinterStorage().collat_borrow_cap = int256(_collat_borrow_cap);
    }

    function setMinimumCollateralRatio(uint256 _min_cr) internal {
        dollarAmoMinterStorage().min_cr = _min_cr;
    }

    function setAMOCorrectionOffsets(
        address amo_address,
        int256 uad_e18_correction,
        int256 collat_e18_correction
    ) internal {
        dollarAmoMinterStorage().correction_offsets_amos[amo_address][
            0
        ] = uad_e18_correction;
        dollarAmoMinterStorage().correction_offsets_amos[amo_address][
            1
        ] = collat_e18_correction;

        syncDollarBalances();
    }

    function setUadPool(
        address _pool_address,
        address _collateral_address
    ) internal {
        dollarAmoMinterStorage().pool = IUbiquityPool(_pool_address);

        uint256 index = dollarAmoMinterStorage()
            .pool
            .getCollateralAddressToIndex(_collateral_address);
        // Make sure the collaterals match, or balances could get corrupted
        require(index == dollarAmoMinterStorage().col_idx, "col_idx mismatch");
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) internal {
        // Can only be triggered by owner or governance
        TransferHelper.safeTransfer(
            tokenAddress,
            dollarAmoMinterStorage().custodian_address,
            tokenAmount
        );

        emit Recovered(tokenAddress, tokenAmount);
    }
}
