// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @notice Interface for setting protocol parameters
 */
interface IUbiquityDollarManager is IAccessControl {
    /**
     * @notice Returns name for the "incentive manager" role
     * @return Bytes representation of the role name
     */
    function INCENTIVE_MANAGER_ROLE() external view returns (bytes32);

    /**
     * @notice Returns name for the "governance token minter" role
     * @return Bytes representation of the role name
     */
    function GOVERNANCE_TOKEN_MINTER_ROLE() external view returns (bytes32);

    /**
     * @notice Returns Credit token address
     * @return Credit token address
     */
    function creditTokenAddress() external view returns (address);

    /**
     * @notice Returns treasury address
     * @return Treasury address
     */
    function treasuryAddress() external view returns (address);

    /**
     * @notice Sets Curve TWAP oracle address
     * @param _twapOracleAddress TWAP oracle address
     */
    function setTwapOracleAddress(address _twapOracleAddress) external;

    /**
     * @notice Sets Credit token address
     * @param _creditTokenAddress Credit token address
     */
    function setCreditTokenAddress(address _creditTokenAddress) external;

    /**
     * @notice Sets Credit NFT address
     * @param _creditNftAddress Credit NFT address
     */
    function setCreditNftAddress(address _creditNftAddress) external;

    /**
     * @notice Sets incentive contract `_incentiveAddress` for `_account` address
     * @param _account Address for which to set an incentive contract
     * @param _incentiveAddress Incentive contract address
     */
    function setIncentiveToDollar(
        address _account,
        address _incentiveAddress
    ) external;

    /**
     * @notice Sets Dollar token address
     * @param _dollarTokenAddress Dollar token address
     */
    function setDollarTokenAddress(address _dollarTokenAddress) external;

    /**
     * @notice Sets Governance token address
     * @param _governanceTokenAddress Governance token address
     */
    function setGovernanceTokenAddress(
        address _governanceTokenAddress
    ) external;

    /**
     * @notice Sets Sushi swap pool address (Dollar-Governance)
     * @param _sushiSwapPoolAddress Pool address
     */
    function setSushiSwapPoolAddress(address _sushiSwapPoolAddress) external;

    /**
     * @notice Sets Credit calculator address
     * @param _creditCalculatorAddress Credit calculator address
     */
    function setCreditCalculatorAddress(
        address _creditCalculatorAddress
    ) external;

    /**
     * @notice Sets Credit NFT calculator address
     * @param _creditNftCalculatorAddress Credit NFT calculator address
     */
    function setCreditNftCalculatorAddress(
        address _creditNftCalculatorAddress
    ) external;

    /**
     * @notice Sets Dollar mint calculator address
     * @param _dollarMintCalculatorAddress Dollar mint calculator address
     */
    function setDollarMintCalculatorAddress(
        address _dollarMintCalculatorAddress
    ) external;

    /**
     * @notice Sets excess Dollars distributor address
     * @param creditNftManagerAddress Credit NFT manager address
     * @param dollarMintExcess Dollar distributor address
     */
    function setExcessDollarsDistributor(
        address creditNftManagerAddress,
        address dollarMintExcess
    ) external;

    /**
     * @notice Sets MasterChef address
     * @param _masterChefAddress MasterChef address
     */
    function setMasterChefAddress(address _masterChefAddress) external;

    /**
     * @notice Sets formulas address
     * @param _formulasAddress Formulas address
     */
    function setFormulasAddress(address _formulasAddress) external;

    /**
     * @notice Sets staking share address
     * @param _stakingShareAddress Staking share address
     */
    function setStakingShareAddress(address _stakingShareAddress) external;

    /**
     * @notice Sets Curve Dollar-3CRV MetaPool address
     * @param _stableSwapMetaPoolAddress Curve Dollar-3CRV MetaPool address
     */
    function setStableSwapMetaPoolAddress(
        address _stableSwapMetaPoolAddress
    ) external;

    /**
     * @notice Sets staking contract address
     * @dev Staking contract participants deposit Curve LP tokens
     * for a certain duration to earn Governance tokens and more Curve LP tokens
     * @param _stakingContractAddress Staking contract address
     */
    function setStakingContractAddress(
        address _stakingContractAddress
    ) external;

    /**
     * @notice Sets treasury address
     * @dev Treasury fund is used to maintain the protocol
     * @param _treasuryAddress Treasury address
     */
    function setTreasuryAddress(address _treasuryAddress) external;

    /**
     * @notice Deploys Curve MetaPool [Stablecoin, 3CRV LP]
     * @dev  From the curve documentation for uncollateralized algorithmic
     * stablecoins amplification should be 5-10
     * @param _curveFactory Curve MetaPool factory address
     * @param _crvBasePool Base pool address for MetaPool
     * @param _crv3PoolTokenAddress Curve TriPool address
     * @param _amplificationCoefficient Amplification coefficient. The smaller
     * it is the closer to a constant product we are.
     * @param _fee Trade fee, given as an integer with 1e10 precision
     */
    function deployStableSwapPool(
        address _curveFactory,
        address _crvBasePool,
        address _crv3PoolTokenAddress,
        uint256 _amplificationCoefficient,
        uint256 _fee
    ) external;

    /**
     * @notice Returns excess dollars distributor address
     * @param _creditNftManagerAddress Credit NFT manager address
     * @return Excess dollars distributor address
     */
    function getExcessDollarsDistributor(
        address _creditNftManagerAddress
    ) external view returns (address);

    /**
     * @notice Returns staking address
     * @return Staking address
     */
    function stakingContractAddress() external view returns (address);

    /**
     * @notice Returns staking share address
     * @return Staking share address
     */
    function stakingShareAddress() external view returns (address);

    /**
     * @notice Returns Curve MetaPool address for Dollar-3CRV LP pair
     * @return Curve MetaPool address
     */
    function stableSwapMetaPoolAddress() external view returns (address);

    /**
     * @notice Returns Dollar token address
     * @return Dollar token address
     */
    function dollarTokenAddress() external view returns (address);

    /**
     * @notice Returns Governance token address
     * @return Governance token address
     */
    function governanceTokenAddress() external view returns (address);
}
