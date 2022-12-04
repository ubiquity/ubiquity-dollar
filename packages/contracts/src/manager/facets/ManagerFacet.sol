// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {
    AppStorage,
    Modifiers,
    UBQ_MINTER_ROLE,
    PAUSER_ROLE,
    COUPON_MANAGER_ROLE,
    BONDING_MANAGER_ROLE,
    INCENTIVE_MANAGER_ROLE,
    UBQ_TOKEN_MANAGER_ROLE    
} from "../libraries/LibAppStorage.sol";
import { AccessControlStorage } from "../libraries/AccessControlStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../dollar/interfaces/IUbiquityAlgorithmicDollar.sol";
import "../../dollar/interfaces/ICurveFactory.sol";
import "../../dollar/interfaces/IMetaPool.sol";
import "../../dollar/TWAPOracle.sol";

contract ManagerFacet is Modifiers {

    function setDollarTokenAddress(address _dollarTokenAddress)
        external
        onlyAdmin
    {
        s.dollarTokenAddress = _dollarTokenAddress;
    }

    function setCreditTokenAddress(address _creditTokenAddress)
        external
        onlyAdmin
    {
        s.creditTokenAddress = _creditTokenAddress;
    }

    function setDebtCouponAddress(address _debtCouponAddress)
        external
        onlyAdmin
    {
        s.debtCouponAddress = _debtCouponAddress;
    }

    function setGovernanceTokenAddress(address _governanceTokenAddress)
        external
        onlyAdmin
    {
        s.governanceTokenAddress = _governanceTokenAddress;
    }

    function setSushiSwapPoolAddress(address _sushiSwapPoolAddress)
        external
        onlyAdmin
    {
        s.sushiSwapPoolAddress = _sushiSwapPoolAddress;
    }

    function setUCRCalculatorAddress(address _ucrCalculatorAddress)
        external
        onlyAdmin
    {
        s.ucrCalculatorAddress = _ucrCalculatorAddress;
    }

    function setCouponCalculatorAddress(address _couponCalculatorAddress)
        external
        onlyAdmin
    {
        s.couponCalculatorAddress = _couponCalculatorAddress;
    }

    function setDollarMintingCalculatorAddress(
        address _dollarMintingCalculatorAddress
    ) external onlyAdmin {
        s.dollarMintingCalculatorAddress = _dollarMintingCalculatorAddress;
    }

    function setExcessDollarsDistributor(
        address debtCouponManagerAddress,
        address excessCouponDistributor
    ) external onlyAdmin {
        s._excessDollarDistributors[debtCouponManagerAddress] =
            excessCouponDistributor;
    }

    function setMasterChefAddress(address _masterChefAddress)
        external
        onlyAdmin
    {
        s.masterChefAddress = _masterChefAddress;
    }

    function setFormulasAddress(address _formulasAddress) external onlyAdmin {
        s.formulasAddress = _formulasAddress;
    }

    function setBondingShareAddress(address _bondingShareAddress)
        external
        onlyAdmin
    {
        s.bondingShareAddress = _bondingShareAddress;
    }

    function setStableSwapMetaPoolAddress(address _stableSwapMetaPoolAddress)
        external
        onlyAdmin
    {
        s.stableSwapMetaPoolAddress = _stableSwapMetaPoolAddress;
    }

    function setBondingContractAddress(address _bondingContractAddress)
        external
        onlyAdmin
    {
        s.bondingContractAddress = _bondingContractAddress;
    }

    function setTreasuryAddress(address _treasuryAddress) external onlyAdmin {
        s.treasuryAddress = _treasuryAddress;
    }

    function setIncentiveToUAD(address _account, address _incentiveAddress)
        external
        onlyAdmin
    {
        IUbiquityAlgorithmicDollar(s.dollarTokenAddress).setIncentiveContract(
            _account, _incentiveAddress
        );
    }

    function deployStableSwapPool(
        address _curveFactory,
        address _crvBasePool,
        address _crv3PoolTokenAddress,
        uint256 _amplificationCoefficient,
        uint256 _fee
    ) external onlyAdmin {
        // Create new StableSwap meta pool (uAD <-> 3Crv)
        address metaPool = ICurveFactory(_curveFactory).deploy_metapool(
            _crvBasePool,
            ERC20(s.dollarTokenAddress).name(),
            ERC20(s.dollarTokenAddress).symbol(),
            s.dollarTokenAddress,
            _amplificationCoefficient,
            _fee
        );
        s.stableSwapMetaPoolAddress = metaPool;

        // Approve the newly-deployed meta pool to transfer this contract's funds
        uint256 crv3PoolTokenAmount =
            IERC20(_crv3PoolTokenAddress).balanceOf(address(this));
        uint256 uADTokenAmount =
            IERC20(s.dollarTokenAddress).balanceOf(address(this));

        // safe approve revert if approve from non-zero to non-zero allowance
        IERC20(_crv3PoolTokenAddress).approve(metaPool, 0);
        IERC20(_crv3PoolTokenAddress).approve(metaPool, crv3PoolTokenAmount);

        IERC20(s.dollarTokenAddress).approve(metaPool, 0);
        IERC20(s.dollarTokenAddress).approve(metaPool, uADTokenAmount);

        // coin at index 0 is uAD and index 1 is 3CRV
        require(
            IMetaPool(metaPool).coins(0) == s.dollarTokenAddress
                && IMetaPool(metaPool).coins(1) == _crv3PoolTokenAddress,
            "uADMGR: COIN_ORDER_MISMATCH"
        );
        // Add the initial liquidity to the StableSwap meta pool
        uint256[2] memory amounts = [
            IERC20(s.dollarTokenAddress).balanceOf(address(this)),
            IERC20(_crv3PoolTokenAddress).balanceOf(address(this))
        ];

        // set curve 3Pool address
        s.curve3PoolTokenAddress = _crv3PoolTokenAddress;
        IMetaPool(metaPool).add_liquidity(amounts, 0, msg.sender);
    }

    function getTwapOracleAddress() external view returns (address) {
        return s.twapOracleAddress;
    }

    function getDollarTokenAddress() external view returns (address) {
        return s.dollarTokenAddress;
    }

    function getCreditTokenAddress() external view returns (address) {
        return s.creditTokenAddress;
    }

    function getDebtCouponAddress() external view returns (address) {
        return s.debtCouponAddress;
    }

    function getGovernanceTokenAddress() external view returns (address) {
        return s.governanceTokenAddress;
    }

    function getSushiSwapPoolAddress() external view returns (address) {
        return s.sushiSwapPoolAddress;
    }

    function getUCRCalculatorAddress() external view returns (address) {
        return s.ucrCalculatorAddress;
    }

    function getCouponCalculatorAddress() external view returns (address) {
        return s.couponCalculatorAddress;
    }

    function getDollarMintingCalculatorAddress() external view returns (address) {
        return s.dollarMintingCalculatorAddress;
    }

    function getExcessDollarsDistributor(address _debtCouponManagerAddress)
        external
        view
        returns (address)
    {
        return s._excessDollarDistributors[_debtCouponManagerAddress];
    }

    function getMasterChefAddress() external view returns (address) {
        return s.masterChefAddress;
    }

    function getFormulasAddress() external view returns (address) {
        return s.formulasAddress;
    }

    function getBondingShareAddress() external view returns (address) {
        return s.bondingShareAddress;
    }

    function getStableSwapMetaPoolAddress() external view returns (address) {
        return s.stableSwapMetaPoolAddress;
    }

    function getBondingContractAddress() external view returns (address) {
        return s.bondingContractAddress;
    }

    function getTreasuryAddress() external view returns (address) {
        return s.treasuryAddress;
    }
}