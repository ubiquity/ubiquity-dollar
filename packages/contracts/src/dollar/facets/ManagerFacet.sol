// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {Modifiers} from "../libraries/LibAppStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../dollar/interfaces/IUbiquityDollarToken.sol";
import "../../dollar/interfaces/ICurveFactory.sol";
import "../../dollar/interfaces/IMetaPool.sol";
import "../libraries/LibAccessControl.sol";

contract ManagerFacet is Modifiers {
    // TODO Add a generic setter for extra addresses that needs to be linked

    function setCreditTokenAddress(
        address _creditTokenAddress
    ) external onlyAdmin {
        store.creditTokenAddress = _creditTokenAddress;
    }

    // set dollar token address
    function setDollarTokenAddress(
        address _dollarTokenAddress
    ) external onlyAdmin {
        store.dollarTokenAddress = _dollarTokenAddress;
    }

    function setCreditNftAddress(address _creditNftAddress) external onlyAdmin {
        store.creditNftAddress = _creditNftAddress;
    }

    function setGovernanceTokenAddress(
        address _governanceTokenAddress
    ) external onlyAdmin {
        store.governanceTokenAddress = _governanceTokenAddress;
    }

    function setSushiSwapPoolAddress(
        address _sushiSwapPoolAddress
    ) external onlyAdmin {
        store.sushiSwapPoolAddress = _sushiSwapPoolAddress;
    }

    function setDollarMintCalculatorAddress(
        address _dollarMintCalculatorAddress
    ) external onlyAdmin {
        store.dollarMintCalculatorAddress = _dollarMintCalculatorAddress;
    }

    function setExcessDollarsDistributor(
        address creditNftManagerAddress,
        address dollarMintExcess
    ) external onlyAdmin {
        store._excessDollarDistributors[
            creditNftManagerAddress
        ] = dollarMintExcess;
    }

    function setMasterChefAddress(
        address _masterChefAddress
    ) external onlyAdmin {
        store.masterChefAddress = _masterChefAddress;
    }

    function setFormulasAddress(address _formulasAddress) external onlyAdmin {
        store.formulasAddress = _formulasAddress;
    }

    function setStakingShareAddress(
        address _stakingShareAddress
    ) external onlyAdmin {
        store.stakingShareAddress = _stakingShareAddress;
    }

    function setStableSwapMetaPoolAddress(
        address _stableSwapMetaPoolAddress
    ) external onlyAdmin {
        store.stableSwapMetaPoolAddress = _stableSwapMetaPoolAddress;
    }

    function setStakingContractAddress(
        address _stakingContractAddress
    ) external onlyAdmin {
        store.stakingContractAddress = _stakingContractAddress;
    }

    function setBondingCurveAddress(
        address _bondingCurveAddress
    ) external onlyAdmin {
        store.bondingCurveAddress = _bondingCurveAddress;
    }

    function setBancorFormulaAddress(
        address _bancorFormulaAddress
    ) external onlyAdmin {
        store.bancorFormulaAddress = _bancorFormulaAddress;
    }

    function setTreasuryAddress(address _treasuryAddress) external onlyAdmin {
        store.treasuryAddress = _treasuryAddress;
    }

    function setIncentiveToDollar(
        address _account,
        address _incentiveAddress
    ) external onlyAdmin {
        IUbiquityDollarToken dollar = IUbiquityDollarToken(
            store.dollarTokenAddress
        );
        dollar.setIncentiveContract(_account, _incentiveAddress);
    }

    function deployStableSwapPool(
        address _curveFactory,
        address _crvBasePool,
        address _crv3PoolTokenAddress,
        uint256 _amplificationCoefficient,
        uint256 _fee
    ) external onlyAdmin {
        // Create new StableSwap meta pool (Dollar <-> 3Crv)
        // slither-disable-next-line reentrancy-no-eth
        address metaPool = ICurveFactory(_curveFactory).deploy_metapool(
            _crvBasePool,
            ERC20(store.dollarTokenAddress).name(),
            ERC20(store.dollarTokenAddress).symbol(),
            store.dollarTokenAddress,
            _amplificationCoefficient,
            _fee
        );
        store.stableSwapMetaPoolAddress = metaPool;
        // Approve the newly-deployed meta pool to transfer this contract's funds
        uint256 crv3PoolTokenAmount = IERC20(_crv3PoolTokenAddress).balanceOf(
            address(this)
        );
        uint256 dollarTokenAmount = IERC20(store.dollarTokenAddress).balanceOf(
            address(this)
        );
        // safe approve revert if approve from non-zero to non-zero allowance
        IERC20(_crv3PoolTokenAddress).approve(metaPool, 0);
        IERC20(_crv3PoolTokenAddress).approve(metaPool, crv3PoolTokenAmount);

        IERC20(store.dollarTokenAddress).approve(metaPool, 0);
        IERC20(store.dollarTokenAddress).approve(metaPool, dollarTokenAmount);

        // coin at index 0 is Dollar and index 1 is 3CRV
        require(
            IMetaPool(metaPool).coins(0) == store.dollarTokenAddress &&
                IMetaPool(metaPool).coins(1) == _crv3PoolTokenAddress,
            "MGR: COIN_ORDER_MISMATCH"
        );
        // Add the initial liquidity to the StableSwap meta pool
        uint256[2] memory amounts = [
            IERC20(store.dollarTokenAddress).balanceOf(address(this)),
            IERC20(_crv3PoolTokenAddress).balanceOf(address(this))
        ];
        // set curve 3Pool address
        store.curve3PoolTokenAddress = _crv3PoolTokenAddress;
        IMetaPool(metaPool).add_liquidity(amounts, 0, msg.sender);
    }

    function twapOracleAddress() external view returns (address) {
        return address(this);
    }

    function dollarTokenAddress() external view returns (address) {
        return store.dollarTokenAddress;
    }

    function creditTokenAddress() external view returns (address) {
        return store.creditTokenAddress;
    }

    function creditNftAddress() external view returns (address) {
        return store.creditNftAddress;
    }

    function governanceTokenAddress() external view returns (address) {
        return store.governanceTokenAddress;
    }

    function sushiSwapPoolAddress() external view returns (address) {
        return store.sushiSwapPoolAddress;
    }

    function creditCalculatorAddress() external view returns (address) {
        return address(this);
    }

    function creditNFTCalculatorAddress() external view returns (address) {
        return address(this);
    }

    function dollarMintCalculatorAddress() external view returns (address) {
        return store.dollarMintCalculatorAddress;
    }

    function excessDollarsDistributor(
        address _creditNftManagerAddress
    ) external view returns (address) {
        return store._excessDollarDistributors[_creditNftManagerAddress];
    }

    function masterChefAddress() external view returns (address) {
        return store.masterChefAddress;
    }

    function formulasAddress() external view returns (address) {
        return store.formulasAddress;
    }

    function stakingShareAddress() external view returns (address) {
        return store.stakingShareAddress;
    }

    function stableSwapMetaPoolAddress() external view returns (address) {
        return store.stableSwapMetaPoolAddress;
    }

    function stakingContractAddress() external view returns (address) {
        return store.stakingContractAddress;
    }

    function bondingCurveAddress() external view returns (address) {
        return store.bondingCurveAddress;
    }

    function setBancorFormularAddress() external view returns (address) {
        return store.bancorFormulaAddress;
    }

    function treasuryAddress() external view returns (address) {
        return store.treasuryAddress;
    }

    function curve3PoolTokenAddress() external view returns (address) {
        return store.curve3PoolTokenAddress;
    }
}
