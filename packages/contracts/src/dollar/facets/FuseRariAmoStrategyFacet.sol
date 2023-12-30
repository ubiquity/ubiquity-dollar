// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LibFuseRariAmoStrategy} from "../libraries/LibFuseRariAmoStrategy.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

contract FuseRariAmoStrategyFacet is Modifiers {
    function initialize(
        address _dollar,
        address[] memory _initialUnitrollers,
        address[] memory _initialFusePools,
        address _amoMinterAddress,
        uint256 _globalDollarCollateralRatio
    ) external {
        LibFuseRariAmoStrategy.initialize(
            _dollar,
            _initialUnitrollers,
            _initialFusePools,
            _amoMinterAddress,
            _globalDollarCollateralRatio
        );
    }

    function showAllocations()
        external
        view
        returns (uint256[3] memory allocations)
    {
        return LibFuseRariAmoStrategy.showAllocations();
    }

    function dollarBalancesStrategy()
        external
        view
        returns (uint256 dollarVal, uint256 collatVal)
    {
        return LibFuseRariAmoStrategy.dollarBalancesStrategy();
    }

    function allPoolAddresses() external view returns (address[] memory) {
        return LibFuseRariAmoStrategy.allPoolAddresses();
    }

    function allPoolsLength() external view returns (uint256) {
        return LibFuseRariAmoStrategy.allPoolsLength();
    }

    function poolAddrToId(
        address _poolAddress
    ) external view returns (uint256) {
        return LibFuseRariAmoStrategy.poolAddrToId(_poolAddress);
    }

    function dollarInPoolByPoolId(
        uint256 _poolId
    ) external view returns (uint256) {
        return LibFuseRariAmoStrategy.dollarInPoolByPoolId(_poolId);
    }

    function dollarInPoolByPoolAddr(
        address _poolAddress
    ) external view returns (uint256) {
        return LibFuseRariAmoStrategy.dollarInPoolByPoolAddr(_poolAddress);
    }

    // function mintedBalance() public view returns (int256) {
    //     return amo_minter.dollar_mint_balances(address(this));
    // }

    // // Backwards compatibility
    // function accumulatedProfit() public view returns (int256) {
    //     return int256(showAllocations()[2]) - mintedBalance();
    // }

    function allBorrowPoolAddresses() external view returns (address[] memory) {
        return LibFuseRariAmoStrategy.allBorrowPoolAddresses();
    }

    function allBorrowPoolsLength() external view returns (uint256) {
        return LibFuseRariAmoStrategy.allBorrowPoolsLength();
    }

    function borrowPoolAddrToId(
        address _poolAddress
    ) external view returns (uint256) {
        return LibFuseRariAmoStrategy.borrowPoolAddrToId(_poolAddress);
    }

    function deptToPoolByPoolId(
        uint256 _poolId
    ) external view returns (uint256) {
        return LibFuseRariAmoStrategy.deptToPoolByPoolId(_poolId);
    }

    function debtToPoolByPoolAddr(
        address _poolAddress
    ) external view returns (uint256) {
        return LibFuseRariAmoStrategy.debtToPoolByPoolAddr(_poolAddress);
    }

    function assetDeptToPoolByPoolId(
        uint256 _poolId
    ) external view returns (uint256) {
        return LibFuseRariAmoStrategy.assetDeptToPoolByPoolId(_poolId);
    }

    function assetDebtToPoolByPoolAddr(
        address _poolAddress
    ) external view returns (uint256) {
        return LibFuseRariAmoStrategy.assetDebtToPoolByPoolAddr(_poolAddress);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /* ---------------------------------------------------- */
    /* ----------------------- Rari ----------------------- */
    /* ---------------------------------------------------- */

    /// @notice IRariComptroller can vary
    function enterMarkets(
        address _comptrollerAddress,
        address _poolAddress
    ) external {
        LibFuseRariAmoStrategy.enterMarkets(_comptrollerAddress, _poolAddress);
    }

    /// @notice E18
    function lendToPool(address _poolAddress, uint256 _lendAmount) external {
        LibFuseRariAmoStrategy.lendToPool(_poolAddress, _lendAmount);
    }

    /// @notice E18
    function redeemFromPool(
        address _poolAddress,
        uint256 _redeemAmount
    ) external {
        LibFuseRariAmoStrategy.redeemFromPool(_poolAddress, _redeemAmount);
    }

    /// @notice Auto compounds interest
    function accrueInterest() external {
        LibFuseRariAmoStrategy.accrueInterest();
    }

    /// @notice Borrow from pool
    function borrowFromPool(
        address _poolAddress,
        uint256 _borrowAmount
    ) external {
        LibFuseRariAmoStrategy.borrowFromPool(_poolAddress, _borrowAmount);
    }

    /// @notice Repay borrowed asset to pool
    function repayToPool(address _poolAddress, uint256 _repayAmount) external {
        LibFuseRariAmoStrategy.repayToPool(_poolAddress, _repayAmount);
    }

    /// @notice Auto compounds interest for borrow pools
    function accrueBorrowInterest() external {
        LibFuseRariAmoStrategy.accrueBorrowInterest();
    }

    /* ========== Burns and givebacks ========== */

    // Burn unneeded or excess DOLLAR. Goes through the minter
    function burnDollarStrategy(uint256 _dollarAmount) external {
        LibFuseRariAmoStrategy.burnDollarStrategy(_dollarAmount);
    }

    /* ========== OWNER / GOVERNANCE FUNCTIONS ONLY ========== */
    // Only owner or timelock can call, to limit risk

    // Add a fuse pool
    function addFusePool(address _poolAddress) external {
        LibFuseRariAmoStrategy.addFusePool(_poolAddress);
    }

    // Remove a fuse pool
    function removeFusePool(address _poolAddress) external {
        LibFuseRariAmoStrategy.removeFusePool(_poolAddress);
    }

    // Add a fuse pool for borrowing
    function addBorrowFusePool(address _poolAddress) external {
        LibFuseRariAmoStrategy.addBorrowFusePool(_poolAddress);
    }

    // Remove a borrow fuse pool
    function removeBorrowFusePool(address _poolAddress) external {
        LibFuseRariAmoStrategy.removeBorrowFusePool(_poolAddress);
    }

    function setAmoMinter(address _amoMinterAddress) external {
        LibFuseRariAmoStrategy.setAmoMinter(_amoMinterAddress);
    }

    function amoMinterAddress() external view returns (address) {
        return LibFuseRariAmoStrategy.amoMinterAddress();
    }
}
