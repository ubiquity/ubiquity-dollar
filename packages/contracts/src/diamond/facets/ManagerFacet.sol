// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {Modifiers} from "../libraries/LibAppStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../dollar/interfaces/IUbiquityDollarToken.sol";
import "../../dollar/interfaces/ICurveFactory.sol";
import "../../dollar/interfaces/IMetaPool.sol";
import "../../dollar/core/TWAPOracleDollar3pool.sol";
import "../libraries/LibAccessControl.sol";
import "../libraries/LibUbiquityDollar.sol";

contract ManagerFacet is Modifiers {
    // TODO Add a generic setter for extra addresses that needs to be linked

    function setCreditTokenAddress(
        address _creditTokenAddress
    ) external onlyAdmin {
        s.creditTokenAddress = _creditTokenAddress;
    }

    function setCreditNftAddress(address _creditNftAddress) external onlyAdmin {
        s.creditNftAddress = _creditNftAddress;
    }

    function setGovernanceTokenAddress(
        address _governanceTokenAddress
    ) external onlyAdmin {
        s.governanceTokenAddress = _governanceTokenAddress;
    }

    function setSushiSwapPoolAddress(
        address _sushiSwapPoolAddress
    ) external onlyAdmin {
        s.sushiSwapPoolAddress = _sushiSwapPoolAddress;
    }

    function setCreditCalculatorAddress(
        address _creditCalculatorAddress
    ) external onlyAdmin {
        s.creditCalculatorAddress = _creditCalculatorAddress;
    }

    function setCreditNftCalculatorAddress(
        address _creditNftCalculatorAddress
    ) external onlyAdmin {
        s.creditNftCalculatorAddress = _creditNftCalculatorAddress;
    }

    function setDollarMintCalculatorAddress(
        address _dollarMintCalculatorAddress
    ) external onlyAdmin {
        s.dollarMintCalculatorAddress = _dollarMintCalculatorAddress;
    }

    function setExcessDollarsDistributor(
        address creditNftManagerAddress,
        address dollarMintExcess
    ) external onlyAdmin {
        s._excessDollarDistributors[creditNftManagerAddress] = dollarMintExcess;
    }

    function setMasterChefAddress(
        address _masterChefAddress
    ) external onlyAdmin {
        s.masterChefAddress = _masterChefAddress;
    }

    function setFormulasAddress(address _formulasAddress) external onlyAdmin {
        s.formulasAddress = _formulasAddress;
    }

    function setStakingShareAddress(
        address _stakingShareAddress
    ) external onlyAdmin {
        s.stakingShareAddress = _stakingShareAddress;
    }

    function setStableSwapMetaPoolAddress(
        address _stableSwapMetaPoolAddress
    ) external onlyAdmin {
        s.stableSwapMetaPoolAddress = _stableSwapMetaPoolAddress;
    }

    function setStakingContractAddress(
        address _stakingContractAddress
    ) external onlyAdmin {
        s.stakingContractAddress = _stakingContractAddress;
    }

    function setTreasuryAddress(address _treasuryAddress) external onlyAdmin {
        s.treasuryAddress = _treasuryAddress;
    }

    function setIncentiveToDollar(address _account, address _incentiveAddress)
        external
        onlyAdmin
    {
        LibUbiquityDollar.setIncentiveContract(_account, _incentiveAddress);
    }

    function deployStableSwapPool(
        address _curveFactory,
        address _crvBasePool,
        address _crv3PoolTokenAddress,
        uint256 _amplificationCoefficient,
        uint256 _fee
    ) external onlyAdmin {
        // Create new StableSwap meta pool (uAD <-> 3Crv)
        // slither-disable-next-line reentrancy-no-eth
        address metaPool = ICurveFactory(_curveFactory).deploy_metapool(
            _crvBasePool,
            ERC20(address(this)).name(),
            ERC20(address(this)).symbol(),
            address(this),
            _amplificationCoefficient,
            _fee
        );
        s.stableSwapMetaPoolAddress = metaPool;

        // Approve the newly-deployed meta pool to transfer this contract's funds
        uint256 crv3PoolTokenAmount = IERC20(_crv3PoolTokenAddress).balanceOf(
            address(this)
        );
        uint256 dollarTokenAmount = IERC20(address(this)).balanceOf(
            address(this)
        );

        // safe approve revert if approve from non-zero to non-zero allowance
        IERC20(_crv3PoolTokenAddress).approve(metaPool, 0);
        IERC20(_crv3PoolTokenAddress).approve(metaPool, crv3PoolTokenAmount);

        IERC20(address(this)).approve(metaPool, 0);
        IERC20(address(this)).approve(metaPool, dollarTokenAmount);

        // coin at index 0 is uAD and index 1 is 3CRV
        require(
            IMetaPool(metaPool).coins(0) == address(this) &&
                IMetaPool(metaPool).coins(1) == _crv3PoolTokenAddress,
            "MGR: COIN_ORDER_MISMATCH"
        );
        // Add the initial liquidity to the StableSwap meta pool
        uint256[2] memory amounts = [
            IERC20(address(this)).balanceOf(address(this)),
            IERC20(_crv3PoolTokenAddress).balanceOf(address(this))
        ];

        // set curve 3Pool address
        s.curve3PoolTokenAddress = _crv3PoolTokenAddress;
        IMetaPool(metaPool).add_liquidity(amounts, 0, msg.sender);
    }

    function getTwapOracleAddress() external view returns (address) {
        return address(this);
    }

    function getDollarTokenAddress() external view returns (address) {
        return address(this);
    }

    function getCreditTokenAddress() external view returns (address) {
        return s.creditTokenAddress;
    }

    function getCreditNftAddress() external view returns (address) {
        return s.creditNftAddress;
    }

    function getGovernanceTokenAddress() external view returns (address) {
        return s.governanceTokenAddress;
    }

    function getSushiSwapPoolAddress() external view returns (address) {
        return s.sushiSwapPoolAddress;
    }

    function getCreditCalculatorAddress() external view returns (address) {
        return s.creditCalculatorAddress;
    }

    function getCreditNftCalculatorAddress() external view returns (address) {
        return s.creditNftCalculatorAddress;
    }

    function getDollarMintCalculatorAddress() external view returns (address) {
        return s.dollarMintCalculatorAddress;
    }

    function getExcessDollarsDistributor(
        address _creditNftManagerAddress
    ) external view returns (address) {
        return s._excessDollarDistributors[_creditNftManagerAddress];
    }

    function getMasterChefAddress() external view returns (address) {
        return s.masterChefAddress;
    }

    function getFormulasAddress() external view returns (address) {
        return s.formulasAddress;
    }

    function getStakingShareAddress() external view returns (address) {
        return s.stakingShareAddress;
    }

    function getStableSwapMetaPoolAddress() external view returns (address) {
        return s.stableSwapMetaPoolAddress;
    }

    function getStakingContractAddress() external view returns (address) {
        return s.stakingContractAddress;
    }

    function getTreasuryAddress() external view returns (address) {
        return s.treasuryAddress;
    }
}
