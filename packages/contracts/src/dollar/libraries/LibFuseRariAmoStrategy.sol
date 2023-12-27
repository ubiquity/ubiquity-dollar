// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IUbiquityDollarToken.sol";
import "../interfaces/IRariComptroller.sol";
import "../interfaces/IDollarAmoMinter.sol";
import "../interfaces/ICErc20Delegator.sol";
import "./Constants.sol";

library LibFuseRariAmoStrategy {
    using SafeERC20 for IERC20;

    bytes32 constant FUSERARIAMO_CONTROL_STORAGE_SLOT =
        bytes32(
            uint256(keccak256("ubiquity.contracts.fuserariamo.storage")) - 1
        );

    /* ========== EVENTS ========== */

    event FusePoolAdded(address token);
    event FusePoolRemoved(address token);
    event BorrowFusePoolAdded(address token);
    event BorrowFusePoolRemoved(address token);
    event Recovered(address token, uint256 amount);

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

    modifier validPool(address _poolAddress) {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        require(strategyStorage.fusePools[_poolAddress], "Invalid pool");
        _;
    }

    modifier validBorrowPool(address _borrowPoolAddress) {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        require(
            strategyStorage.fuseBorrowPools[_borrowPoolAddress],
            "Invalid borrow pool"
        );
        _;
    }

    function init(
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

        allocations[2] = allocations[0] + allocations[1]; // Total FRAX value
    }

    function dollarBalances()
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

    function allPoolAddresses() internal view returns (address[] memory) {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        return strategyStorage.fusePoolsArray;
    }

    function allPoolsLength() internal view returns (uint256) {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        return strategyStorage.fusePoolsArray.length;
    }

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

    function dollarInPoolByPoolAddr(
        address _poolAddress
    ) internal view returns (uint256) {
        uint256 poolId = poolAddrToId(_poolAddress);
        return dollarInPoolByPoolId(poolId);
    }

    // function mintedBalance() public view returns (int256) {
    //     return amo_minter.frax_mint_balances(address(this));
    // }

    // // Backwards compatibility
    // function accumulatedProfit() public view returns (int256) {
    //     return int256(showAllocations()[2]) - mintedBalance();
    // }

    function allBorrowPoolAddresses() internal view returns (address[] memory) {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        return strategyStorage.fuseBorrowPoolsArray;
    }

    function allBorrowPoolsLength() internal view returns (uint256) {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        return strategyStorage.fuseBorrowPoolsArray.length;
    }

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
    function burnDollar(uint256 _dollarAmount) internal {
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

    function recoverERC20(
        address _tokenAddress,
        uint256 _tokenAmount
    ) internal {
        IERC20(_tokenAddress).safeTransfer(msg.sender, _tokenAmount);

        emit Recovered(_tokenAddress, _tokenAmount);
    }
}
