// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;

import 'openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol';
import 'openzeppelin-contracts/contracts/access/IAccessControl.sol';

/// @title UAD Manager interface
/// @author Ubiquity Algorithmic Manager
interface IUbiquityAlgorithmicDollarManager is IAccessControl {
  function autoRedeemTokenAddress() external view returns (address);

  function treasuryAddress() external view returns (address);

  function INCENTIVE_MANAGER_ROLE() external view returns (bytes32);

  function UBQ_MINTER_ROLE() external view returns (bytes32);

  // TODO Add a generic setter for extra addresses that needs to be linked
  function setTwapOracleAddress(address _twapOracleAddress) external;

  function setuARTokenAddress(address _uarTokenAddress) external;

  function setDebtCouponAddress(address _debtCouponAddress) external;

  function setIncentiveToUAD(address _account, address _incentiveAddress) external;

  function setDollarTokenAddress(address _dollarTokenAddress) external;

  function setGovernanceTokenAddress(address _governanceTokenAddress) external;

  function setSushiSwapPoolAddress(address _sushiSwapPoolAddress) external;

  function setUARCalculatorAddress(address _uarCalculatorAddress) external;

  function setCouponCalculatorAddress(address _couponCalculatorAddress) external;

  function setDollarMintingCalculatorAddress(address _dollarMintingCalculatorAddress) external;

  function setExcessDollarsDistributor(
    address debtCouponManagerAddress,
    address excessCouponDistributor
  ) external;

  function setMasterChefAddress(address _masterChefAddress) external;

  function setFormulasAddress(address _formulasAddress) external;

  function setBondingShareAddress(address _bondingShareAddress) external;

  function setStableSwapMetaPoolAddress(address _stableSwapMetaPoolAddress) external;

  /**
    @notice set the bonding bontract smart contract address
    @dev bonding contract participants deposit  curve LP token
         for a certain duration to earn uGOV and more curve LP token
    @param _bondingContractAddress bonding contract address
     */
  function setBondingContractAddress(address _bondingContractAddress) external;

  /**
    @notice set the treasury address
    @dev the treasury fund is used to maintain the protocol
    @param _treasuryAddress treasury fund address
     */
  function setTreasuryAddress(address _treasuryAddress) external;

  /**
    @notice deploy a new Curve metapools for uAD Token uAD/3Pool
    @dev  From the curve documentation for uncollateralized algorithmic
    stablecoins amplification should be 5-10
    @param _curveFactory MetaPool factory address
    @param _crvBasePool Address of the base pool to use within the new metapool.
    @param _crv3PoolTokenAddress curve 3Pool token Address
    @param _amplificationCoefficient amplification coefficient. The smaller
     it is the closer to a constant product we are.
    @param _fee Trade fee, given as an integer with 1e10 precision.
    */
  function deployStableSwapPool(
    address _curveFactory,
    address _crvBasePool,
    address _crv3PoolTokenAddress,
    uint _amplificationCoefficient,
    uint _fee
  ) external;

  function getExcessDollarsDistributor(address _debtCouponManagerAddress)
    external
    view
    returns (address);
}
