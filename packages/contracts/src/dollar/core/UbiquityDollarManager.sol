// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IUbiquityDollarToken.sol";
import "../interfaces/ICurveFactory.sol";
import "../interfaces/IMetaPool.sol";

import "./TWAPOracleDollar3pool.sol";

/// @title A central config for the Ubiquity Dollar system. Also acts as a central
/// access control manager.
/// @notice For storing constants. For storing variables and allowing them to
/// be changed by the admin (governance)
/// @dev This should be used as a central access control manager which other
/// contracts use to check permissions
contract UbiquityDollarManager is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant GOVERNANCE_TOKEN_MINTER_ROLE =
        keccak256("GOVERNANCE_TOKEN_MINTER_ROLE");
    bytes32 public constant GOVERNANCE_TOKEN_BURNER_ROLE =
        keccak256("GOVERNANCE_TOKEN_BURNER_ROLE");

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant CREDIT_NFT_MANAGER_ROLE =
        keccak256("CREDIT_NFT_MANAGER_ROLE");
    bytes32 public constant STAKING_MANAGER_ROLE =
        keccak256("STAKING_MANAGER_ROLE");
    bytes32 public constant INCENTIVE_MANAGER_ROLE =
        keccak256("INCENTIVE_MANAGER");
    bytes32 public constant GOVERNANCE_TOKEN_MANAGER_ROLE =
        keccak256("GOVERNANCE_TOKEN_MANAGER_ROLE");
    address public twapOracleAddress;
    address public creditNFTAddress;
    address public dollarTokenAddress;
    address public creditNFTCalculatorAddress;
    address public dollarMintCalculatorAddress;
    address public stakingShareAddress;
    address public stakingContractAddress;
    address public stableSwapMetaPoolAddress;
    address public curve3PoolTokenAddress; // 3CRV
    address public treasuryAddress;
    address public governanceTokenAddress;
    address public sushiSwapPoolAddress; // sushi pool UbiquityDollar-GovernanceToken
    address public masterChefAddress;
    address public formulasAddress;
    address public creditTokenAddress;
    address public creditCalculatorAddress;

    //key = address of CreditNFTManager, value = DollarMintExcess
    mapping(address => address) private _excessDollarDistributors;

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "uADMGR: Caller is not admin"
        );
        _;
    }

    constructor(address _admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(GOVERNANCE_TOKEN_MINTER_ROLE, _admin);
        _setupRole(PAUSER_ROLE, _admin);
        _setupRole(CREDIT_NFT_MANAGER_ROLE, _admin);
        _setupRole(STAKING_MANAGER_ROLE, _admin);
        _setupRole(INCENTIVE_MANAGER_ROLE, _admin);
        _setupRole(GOVERNANCE_TOKEN_MANAGER_ROLE, address(this));
    }

    // TODO Add a generic setter for extra addresses that needs to be linked
    function setTwapOracleAddress(address _twapOracleAddress)
        external
        onlyAdmin
    {
        twapOracleAddress = _twapOracleAddress;
        // to be removed

        TWAPOracleDollar3pool oracle = TWAPOracleDollar3pool(twapOracleAddress);
        oracle.update();
    }

    function setuARTokenAddress(address _uarTokenAddress) external onlyAdmin {
        autoRedeemTokenAddress = _uarTokenAddress;
    }

    function setCreditNFTAddress(address _creditNFTAddress)
        external
        onlyAdmin
    {
        creditNFTAddress = _creditNFTAddress;
    }

    function setIncentiveToDollar(address _account, address _incentiveAddress)
        external
        onlyAdmin
    {
        IUbiquityDollarToken(dollarTokenAddress).setIncentiveContract(
            _account, _incentiveAddress
        );
    }

    function setDollarTokenAddress(address _dollarTokenAddress)
        external
        onlyAdmin
    {
        dollarTokenAddress = _dollarTokenAddress;
    }

    function setGovernanceTokenAddress(address _governanceTokenAddress)
        external
        onlyAdmin
    {
        governanceTokenAddress = _governanceTokenAddress;
    }

    function setSushiSwapPoolAddress(address _sushiSwapPoolAddress)
        external
        onlyAdmin
    {
        sushiSwapPoolAddress = _sushiSwapPoolAddress;
    }

    function setCreditCalculatorAddress(address _creditCalculatorAddress)
        external
        onlyAdmin
    {
        creditCalculatorAddress = _creditCalculatorAddress;
    }

    function setCreditNFTCalculatorAddress(address _creditNFTCalculatorAddress)
        external
        onlyAdmin
    {
        creditNFTCalculatorAddress = _creditNFTCalculatorAddress;
    }

    function setDollarMintCalculatorAddress(
        address _dollarMintCalculatorAddress
    ) external onlyAdmin {
        dollarMintCalculatorAddress = _dollarMintCalculatorAddress;
    }

    function setExcessDollarsDistributor(
        address creditNFTManagerAddress,
        address dollarMintExcess
    ) external onlyAdmin {
        _excessDollarDistributors[debtCouponManagerAddress] =
            excessCouponDistributor;
    }

    function setMasterChefAddress(address _masterChefAddress)
        external
        onlyAdmin
    {
        masterChefAddress = _masterChefAddress;
    }

    function setFormulasAddress(address _formulasAddress) external onlyAdmin {
        formulasAddress = _formulasAddress;
    }

    function setStakingShareAddress(address _stakingShareAddress)
        external
        onlyAdmin
    {
        stakingShareAddress = _stakingShareAddress;
    }

    function setStableSwapMetaPoolAddress(address _stableSwapMetaPoolAddress)
        external
        onlyAdmin
    {
        stableSwapMetaPoolAddress = _stableSwapMetaPoolAddress;
    }

    /**
     * @notice set the staking smart contract address
     * @dev staking contract participants deposit  curve LP token
     * for a certain duration to earn Governance Tokens and more curve LP token
     * @param _stakingContractAddress staking contract address
     */
    function setStakingContractAddress(address _stakingContractAddress)
        external
        onlyAdmin
    {
        stakingContractAddress = _stakingContractAddress;
    }

    /**
     * @notice set the treasury address
     * @dev the treasury fund is used to maintain the protocol
     * @param _treasuryAddress treasury fund address
     */
    function setTreasuryAddress(address _treasuryAddress) external onlyAdmin {
        treasuryAddress = _treasuryAddress;
    }

    /**
     * @notice deploy a new Curve metapools for Dollar Token Dollar/3Pool
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
    ) external onlyAdmin {
        // Create new StableSwap meta pool (uAD <-> 3Crv)
        address metaPool = ICurveFactory(_curveFactory).deploy_metapool(
            _crvBasePool,
            ERC20(dollarTokenAddress).name(),
            ERC20(dollarTokenAddress).symbol(),
            dollarTokenAddress,
            _amplificationCoefficient,
            _fee
        );
        stableSwapMetaPoolAddress = metaPool;

        // Approve the newly-deployed meta pool to transfer this contract's funds
        uint256 crv3PoolTokenAmount =
            IERC20(_crv3PoolTokenAddress).balanceOf(address(this));
        uint256 dollarTokenAmount =
            IERC20(dollarTokenAddress).balanceOf(address(this));

        // safe approve revert if approve from non-zero to non-zero allowance
        IERC20(_crv3PoolTokenAddress).safeApprove(metaPool, 0);
        IERC20(_crv3PoolTokenAddress).safeApprove(metaPool, crv3PoolTokenAmount);

        IERC20(dollarTokenAddress).safeApprove(metaPool, 0);
        IERC20(dollarTokenAddress).safeApprove(metaPool, dollarTokenAmount);

        // coin at index 0 is Ubiquity Dollar and index 1 is 3CRV
        require(
            IMetaPool(metaPool).coins(0) == dollarTokenAddress
                && IMetaPool(metaPool).coins(1) == _crv3PoolTokenAddress,
            "MGR: COIN_ORDER_MISMATCH"
        );
        // Add the initial liquidity to the StableSwap meta pool
        uint256[2] memory amounts = [
            IERC20(dollarTokenAddress).balanceOf(address(this)),
            IERC20(_crv3PoolTokenAddress).balanceOf(address(this))
        ];

        // set curve 3Pool address
        curve3PoolTokenAddress = _crv3PoolTokenAddress;
        IMetaPool(metaPool).add_liquidity(amounts, 0, msg.sender);
    }

    function getExcessDollarsDistributor(address _creditNFTManagerAddress)
        external
        view
        returns (address)
    {
        return _excessDollarDistributors[_creditNFTManagerAddress];
    }
}