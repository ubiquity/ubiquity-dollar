// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IUbiquityDollarToken.sol";
import "../interfaces/IRariComptroller.sol";
import "../interfaces/IDollarAmoMinter.sol";
import "../interfaces/ICErc20Delegator.sol";
import "./Constants.sol";

/// @title LibFuseRariAmoStrategy
/// @notice A library for managing and interacting with Fuse Rari AMO strategies.
/// @dev This library includes functions for initializing the strategy, managing pools, and handling allocations and balances.
library LibFuseRariAmoStrategy {
    using SafeERC20 for IERC20;

    /// @dev Constant to define the storage slot of the control data.
    bytes32 constant FUSERARIAMO_CONTROL_STORAGE_SLOT =
        bytes32(
            uint256(keccak256("ubiquity.contracts.fuserariamo.storage")) - 1
        );

    /* ========== EVENTS ========== */

    /// @notice Emitted when a new Fuse pool is added.
    /// @param token The address of the token for the added pool.
    event FusePoolAdded(address token);

    /// @notice Emitted when a Fuse pool is removed.
    /// @param token The address of the token for the removed pool.
    event FusePoolRemoved(address token);

    /// @notice Emitted when a new borrow pool is added in the Fuse strategy.
    /// @param token The address of the token for the added borrow pool.
    event BorrowFusePoolAdded(address token);

    /// @notice Emitted when a borrow pool is removed from the Fuse strategy.
    /// @param token The address of the token for the removed borrow pool.
    event BorrowFusePoolRemoved(address token);

    /// @notice Emitted when tokens are recovered.
    /// @param token The address of the recovered token.
    /// @param amount The amount of the recovered token.
    event Recovered(address token, uint256 amount);

    /// @dev Struct to store the data related to the Strategy.
    struct FuseRariAmoStrategyData {
        IUbiquityDollarToken DOLLAR;
        IDollarAmoMinter amoMinter;
        uint256 globalDollarCollateralRatio;
        address timelockAddress;
        address custodianAddress;
        address[] fusePoolsArray;
        address[] fuseBorrowPoolsArray;
        mapping(address => bool) fusePools;
        mapping(address => bool) fuseBorrowPools;
    }

    /// @dev Returns the storage instance for the AMO Strategy.
    /// @return l The storage instance of the AMO Strategy.
    function fuseRariAmoStrategyStorage()
        internal
        pure
        returns (FuseRariAmoStrategyData storage l)
    {
        bytes32 slot = FUSERARIAMO_CONTROL_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @notice Modifier to check if the pool address is a valid pool.
    /// @param _poolAddress The address of the pool to check.
    modifier validPool(address _poolAddress) {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        require(strategyStorage.fusePools[_poolAddress], "Invalid pool");
        _;
    }

    /// @notice Modifier to check if the borrow pool address is valid.
    /// @param _borrowPoolAddress The address of the borrow pool to check.
    modifier validBorrowPool(address _borrowPoolAddress) {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        require(
            strategyStorage.fuseBorrowPools[_borrowPoolAddress],
            "Invalid borrow pool"
        );
        _;
    }

    /// @notice Initializes the AMO Strategy with the given parameters.
    /// @dev Sets up the initial state of the strategy, including pools, AMO minter, and collateral ratio.
    /// @param _dollar Address of the Ubiquity Dollar Token contract.
    /// @param _initialUnitrollers Array of addresses for the initial unitrollers.
    /// @param _initialFusePools Array of addresses for the initial Fuse pools.
    /// @param _amoMinterAddress Address of the AMO Minter contract.
    /// @param _globalDollarCollateralRatio Initial global dollar collateral ratio.
    function initialize(
        address _dollar,
        address[] memory _initialUnitrollers,
        address[] memory _initialFusePools,
        address _amoMinterAddress,
        uint256 _globalDollarCollateralRatio
    ) internal {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        strategyStorage.fusePoolsArray = _initialFusePools;
        for (uint256 i = 0; i < strategyStorage.fusePoolsArray.length; i++) {
            // Set the pools as valid
            strategyStorage.fusePools[_initialFusePools[i]] = true;

            // Enter markets
            address[] memory cTokens = new address[](1);
            cTokens[0] = strategyStorage.fusePoolsArray[i];
            IRariComptroller(_initialUnitrollers[i]).enterMarkets(cTokens);

            strategyStorage.DOLLAR = IUbiquityDollarToken(_dollar);
            strategyStorage.amoMinter = IDollarAmoMinter(_amoMinterAddress);
            strategyStorage.custodianAddress = strategyStorage
                .amoMinter
                .custodianAddress();
            strategyStorage.timelockAddress = strategyStorage
                .amoMinter
                .timelockAddress();

            strategyStorage
                .globalDollarCollateralRatio = _globalDollarCollateralRatio;
        }
    }

    /// @notice Shows the allocations of the strategy in terms of dollar balance and sum of Fuse pool tallies.
    /// @dev Returns an array containing the dollar balance, sum of Fuse pool tallies, and total DOLLAR value.
    /// @return allocations An array of three elements: dollar balance, sum of Fuse pool tallies, and total DOLLAR value.
    function showAllocations()
        internal
        view
        returns (uint256[3] memory allocations)
    {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        allocations[0] = strategyStorage.DOLLAR.balanceOf(address(this));

        uint256 sumFusePoolTally = 0;
        for (uint i = 0; i < strategyStorage.fusePoolsArray.length; i++) {
            // Make sure the pool is enabled first
            address poolAddress = strategyStorage.fusePoolsArray[i];
            if (strategyStorage.fusePools[poolAddress]) {
                sumFusePoolTally = sumFusePoolTally + dollarInPoolByPoolId(i);
            }
        }
        allocations[1] = sumFusePoolTally;

        allocations[2] = allocations[0] + allocations[1]; // Total Dollar value
    }

    /// @notice Provides the dollar and collateral values of the strategy.
    /// @dev Returns the total dollar value and its corresponding collateral value.
    /// @return dollarVal Total dollar value in the strategy.
    /// @return collatVal Corresponding collateral value for the total dollar value.
    function dollarBalancesStrategy()
        internal
        view
        returns (uint256 dollarVal, uint256 collatVal)
    {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        dollarVal = showAllocations()[2];
        collatVal =
            (dollarVal) *
            (strategyStorage.globalDollarCollateralRatio /
                UBIQUITY_POOL_PRICE_PRECISION);
    }

    /// @notice Retrieves all pool addresses involved in the strategy.
    /// @dev Returns an array of addresses representing all the Fuse pools.
    /// @return An array of addresses for each pool in the strategy.
    function allPoolAddresses() internal view returns (address[] memory) {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        return strategyStorage.fusePoolsArray;
    }

    /// @notice Gets the total number of pools in the strategy.
    /// @dev Returns the length of the array containing all Fuse pool addresses.
    /// @return The number of pools in the strategy.
    function allPoolsLength() internal view returns (uint256) {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        return strategyStorage.fusePoolsArray.length;
    }

    /// @notice Converts a pool address to its corresponding index in the pool array.
    /// @dev Finds the index of the given pool address in the fusePools Array.
    /// @param _poolAddress The address of the pool to find.
    /// @return The index of the given pool address in the fusePools Array.
    function poolAddrToId(
        address _poolAddress
    ) internal view returns (uint256) {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        for (uint i = 0; i < strategyStorage.fusePoolsArray.length; i++) {
            if (strategyStorage.fusePoolsArray[i] == _poolAddress) {
                return i;
            }
        }
        revert("Pool not found");
    }

    /// @notice Calculates the dollar value in a specific pool by its ID.
    /// @dev Multiplies the cToken balance by the exchange rate to get the dollar value.
    /// @param _poolId The ID of the pool to calculate the dollar value for.
    /// @return The dollar value in the specified pool.
    function dollarInPoolByPoolId(
        uint256 _poolId
    ) internal view returns (uint256) {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        ICErc20Delegator delegator = ICErc20Delegator(
            strategyStorage.fusePoolsArray[_poolId]
        );
        uint256 cTokenBalance = delegator.balanceOf(address(this));
        return cTokenBalance * (delegator.exchangeRateStored() / (1e18));
    }

    /// @notice Calculates the dollar value in a specific pool by its address.
    /// @dev Converts the pool address to its ID and then calculates the dollar value.
    /// @param _poolAddress The address of the pool to calculate the dollar value for.
    /// @return The dollar value in the specified pool.
    function dollarInPoolByPoolAddr(
        address _poolAddress
    ) internal view returns (uint256) {
        uint256 poolId = poolAddrToId(_poolAddress);
        return dollarInPoolByPoolId(poolId);
    }

    /// @notice Retrieves all borrow pool addresses involved in the strategy.
    /// @dev Returns an array of addresses representing all the Fuse borrow pools.
    /// @return An array of addresses for each borrow pool in the strategy.
    function allBorrowPoolAddresses() internal view returns (address[] memory) {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        return strategyStorage.fuseBorrowPoolsArray;
    }

    /// @notice Gets the total number of borrow pools in the strategy.
    /// @dev Returns the length of the array containing all Fuse borrow pool addresses.
    /// @return The number of borrow pools in the strategy.
    function allBorrowPoolsLength() internal view returns (uint256) {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        return strategyStorage.fuseBorrowPoolsArray.length;
    }

    /// @notice Converts a borrow pool address to its corresponding index in the borrow pool array.
    /// @dev Finds the index of the given borrow pool address in the fuseBorrowPoolsArray.
    /// @param _poolAddress The address of the borrow pool to find.
    /// @return The index of the given borrow pool address in the fuseBorrowPoolsArray.
    function borrowPoolAddrToId(
        address _poolAddress
    ) internal view returns (uint256) {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        for (uint i = 0; i < strategyStorage.fuseBorrowPoolsArray.length; i++) {
            if (strategyStorage.fuseBorrowPoolsArray[i] == _poolAddress) {
                return i;
            }
        }
        revert("Pool not found");
    }

    function deptToPoolByPoolId(
        uint256 _poolId
    ) internal view returns (uint256) {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        ICErc20Delegator delegator = ICErc20Delegator(
            strategyStorage.fuseBorrowPoolsArray[_poolId]
        );
        uint256 debt_bal = delegator.borrowBalanceStored(address(this));
        return debt_bal * (delegator.exchangeRateStored() / 1e18);
    }

    function debtToPoolByPoolAddr(
        address _poolAddress
    ) internal view returns (uint256) {
        uint256 poolId = borrowPoolAddrToId(_poolAddress);
        return deptToPoolByPoolId(poolId);
    }

    function assetDeptToPoolByPoolId(
        uint256 _poolId
    ) internal view returns (uint256) {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        ICErc20Delegator delegator = ICErc20Delegator(
            strategyStorage.fuseBorrowPoolsArray[_poolId]
        );
        (, , uint debtBal, ) = delegator.getAccountSnapshot(address(this));
        return debtBal;
    }

    function assetDebtToPoolByPoolAddr(
        address _poolAddress
    ) internal view returns (uint256) {
        uint256 poolId = borrowPoolAddrToId(_poolAddress);
        return assetDeptToPoolByPoolId(poolId);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /* ---------------------------------------------------- */
    /* ----------------------- Rari ----------------------- */
    /* ---------------------------------------------------- */

    /// @notice IRariComptroller can vary
    function enterMarkets(
        address _comptrollerAddress,
        address _poolAddress
    ) internal validPool(_poolAddress) {
        address[] memory cTokens = new address[](1);
        cTokens[0] = _poolAddress;
        IRariComptroller(_comptrollerAddress).enterMarkets(cTokens);
    }

    /// @notice E18
    function lendToPool(
        address _poolAddress,
        uint256 _lendAmount
    ) internal validPool(_poolAddress) {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        uint256 poolId = poolAddrToId(_poolAddress);
        strategyStorage.DOLLAR.approve(_poolAddress, _lendAmount);
        ICErc20Delegator(strategyStorage.fusePoolsArray[poolId]).mint(
            _lendAmount
        );
    }

    /// @notice E18
    function redeemFromPool(
        address _poolAddress,
        uint256 _redeemAmount
    ) internal validPool(_poolAddress) {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        uint256 poolId = poolAddrToId(_poolAddress);
        ICErc20Delegator(strategyStorage.fusePoolsArray[poolId])
            .redeemUnderlying(_redeemAmount);
    }

    /// @notice Auto compounds interest
    function accrueInterest() internal {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        for (uint i = 0; i < strategyStorage.fusePoolsArray.length; i++) {
            // Make sure the pool is enabled first
            address pool_address = strategyStorage.fusePoolsArray[i];
            if (strategyStorage.fusePools[pool_address]) {
                ICErc20Delegator(strategyStorage.fusePoolsArray[i])
                    .accrueInterest();
            }
        }
    }

    /// @notice Borrow from pool
    function borrowFromPool(
        address _poolAddress,
        uint256 _borrowAmount
    ) internal validBorrowPool(_poolAddress) {
        ICErc20Delegator(_poolAddress).borrow(_borrowAmount);
    }

    /// @notice Repay borrowed asset to pool
    function repayToPool(
        address _poolAddress,
        uint256 _repayAmount
    ) internal validBorrowPool(_poolAddress) {
        ICErc20Delegator delegator = ICErc20Delegator(_poolAddress);
        ERC20(delegator.underlying()).approve(_poolAddress, _repayAmount);
        delegator.repayBorrow(_repayAmount);
    }

    /// @notice Auto compounds interest for borrow pools
    function accrueBorrowInterest() internal {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        for (uint i = 0; i < strategyStorage.fuseBorrowPoolsArray.length; i++) {
            // Make sure the pool is enabled first
            address poolAddress = strategyStorage.fuseBorrowPoolsArray[i];
            if (strategyStorage.fuseBorrowPools[poolAddress]) {
                ICErc20Delegator(strategyStorage.fuseBorrowPoolsArray[i])
                    .accrueInterest();
            }
        }
    }

    /* ========== Burns and givebacks ========== */

    // Burn unneeded or excess DOLLAR. Goes through the minter
    function burnDollarStrategy(uint256 _dollarAmount) internal {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        strategyStorage.DOLLAR.approve(
            address(strategyStorage.amoMinter),
            _dollarAmount
        );
        strategyStorage.amoMinter.burnDollarFromAmo(_dollarAmount);
    }

    /* ========== OWNER / GOVERNANCE FUNCTIONS ONLY ========== */
    // Only owner or timelock can call, to limit risk

    // Add a fuse pool
    function addFusePool(address _poolAddress) internal {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        require(_poolAddress != address(0), "Zero address detected");

        require(
            strategyStorage.fusePools[_poolAddress] == false,
            "Address already exists"
        );
        strategyStorage.fusePools[_poolAddress] = true;
        strategyStorage.fusePoolsArray.push(_poolAddress);

        emit FusePoolAdded(_poolAddress);
    }

    // Remove a fuse pool
    function removeFusePool(address _poolAddress) internal {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        require(_poolAddress != address(0), "Zero address detected");
        require(
            strategyStorage.fusePools[_poolAddress] == true,
            "Address nonexistent"
        );

        // Delete from the mapping
        delete strategyStorage.fusePools[_poolAddress];

        // 'Delete' from the array by setting the address to 0x0
        for (uint i = 0; i < strategyStorage.fusePoolsArray.length; i++) {
            if (strategyStorage.fusePoolsArray[i] == _poolAddress) {
                strategyStorage.fusePoolsArray[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }

        emit FusePoolRemoved(_poolAddress);
    }

    // Add a fuse pool for borrowing
    function addBorrowFusePool(address _poolAddress) internal {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        require(_poolAddress != address(0), "Zero address detected");
        require(
            strategyStorage.fuseBorrowPools[_poolAddress] == false,
            "Address already exists"
        );
        strategyStorage.fuseBorrowPools[_poolAddress] = true;
        strategyStorage.fuseBorrowPoolsArray.push(_poolAddress);

        emit BorrowFusePoolAdded(_poolAddress);
    }

    // Remove a borrow fuse pool
    function removeBorrowFusePool(address _poolAddress) internal {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        require(_poolAddress != address(0), "Zero address detected");
        require(
            strategyStorage.fuseBorrowPools[_poolAddress] == true,
            "Address nonexistent"
        );

        // Delete from the mapping
        delete strategyStorage.fuseBorrowPools[_poolAddress];

        // 'Delete' from the array by setting the address to 0x0
        for (uint i = 0; i < strategyStorage.fuseBorrowPoolsArray.length; i++) {
            if (strategyStorage.fuseBorrowPoolsArray[i] == _poolAddress) {
                strategyStorage.fuseBorrowPoolsArray[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }

        emit BorrowFusePoolRemoved(_poolAddress);
    }

    function setAmoMinter(address _amoMinterAddress) internal {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        strategyStorage.amoMinter = IDollarAmoMinter(_amoMinterAddress);

        // Get the custodian and timelock addresses from the minter
        strategyStorage.custodianAddress = strategyStorage
            .amoMinter
            .custodianAddress();
        strategyStorage.timelockAddress = strategyStorage
            .amoMinter
            .timelockAddress();

        // Make sure the new addresses are not address(0)
        require(
            strategyStorage.custodianAddress != address(0) &&
                strategyStorage.timelockAddress != address(0),
            "Invalid custodian or timelock"
        );
    }

    function amoMinterAddress() internal view returns (address) {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        return address(strategyStorage.amoMinter);
    }
}
