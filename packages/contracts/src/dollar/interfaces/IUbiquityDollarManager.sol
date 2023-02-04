// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/IAccessControl.sol";

/// @title Ubiquity Dollar Manager interface
/// @author Ubiquity DAO
interface IUbiquityDollarManager is IAccessControl {
    // TODO Add a generic setter for extra addresses that needs to be linked

    function INCENTIVE_MANAGER_ROLE() external view returns (bytes32);

    function GOVERNANCE_TOKEN_MINTER_ROLE() external view returns (bytes32);

    function creditTokenAddress() external view returns (address);

    function treasuryAddress() external view returns (address);

    function setTwapOracleAddress(address _twapOracleAddress) external;

    function setCreditTokenAddress(address _creditTokenAddress) external;

    function setCreditNftAddress(address _creditNftAddress) external;

    function setIncentiveToDollar(
        address _account,
        address _incentiveAddress
    ) external;

    function setDollarTokenAddress(address _dollarTokenAddress) external;

    function setGovernanceTokenAddress(
        address _governanceTokenAddress
    ) external;

    function setSushiSwapPoolAddress(address _sushiSwapPoolAddress) external;

    function setCreditCalculatorAddress(
        address _creditCalculatorAddress
    ) external;

    function setCreditNftCalculatorAddress(
        address _creditNftCalculatorAddress
    ) external;

    function setDollarMintCalculatorAddress(
        address _dollarMintCalculatorAddress
    ) external;

    function setExcessDollarsDistributor(
        address creditNftManagerAddress,
        address dollarMintExcess
    ) external;

    function setMasterChefAddress(address _masterChefAddress) external;

    function setFormulasAddress(address _formulasAddress) external;

    function setStakingTokenAddress(address _stakingTokenAddress) external;

    function setStableSwapMetaPoolAddress(
        address _stableSwapMetaPoolAddress
    ) external;

    /**
     * @notice set the staking smart contract address
     * @dev staking contract participants deposit  curve LP token
     * for a certain duration to earn Governance Token and more curve LP token
     * @param _stakingAddress staking contract address
     */
    function setStakingContractAddress(address _stakingAddress) external;

    /**
     * @notice set the treasury address
     * @dev the treasury fund is used to maintain the protocol
     * @param _treasuryAddress treasury fund address
     */
    function setTreasuryAddress(address _treasuryAddress) external;

    /**
     * @notice deploy a new Curve metapools for Ubiquity Dollar Token UbiquityDollar/3Pool
     * @dev  From the curve documentation for uncollateralized algorithmic
     * stablecoins amplification should be 5-10
     * @param _curveFactory MetaPool factory address
     * @param _crvBasePool Address of the base pool to use within the new metapool.
     * @param _crv3PoolTokenAddress curve 3Pool token Address
     * @param _amplificationCoefficient amplification coefficient. The smaller
     * it is the closer to a constant product we are.
     * @param _fee Trade fee, given as an integer with 1e10 precision.
     */
    function deployStableSwapPool(
        address _curveFactory,
        address _crvBasePool,
        address _crv3PoolTokenAddress,
        uint256 _amplificationCoefficient,
        uint256 _fee
    ) external;

    function getExcessDollarsDistributor(
        address _creditNftManagerAddress
    ) external view returns (address);

    function stakingAddress() external view returns (address);

    function stakingTokenAddress() external view returns (address);

    function stableSwapMetaPoolAddress() external view returns (address);

    function dollarTokenAddress() external view returns (address);

    function governanceTokenAddress() external view returns (address);
}
