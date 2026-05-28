// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @notice Factory allows the permissionless deployment of up to
 * eight-coin plain pools (ex: DAI-USDT-USDC) and metapools (ex: USDT-3CRV).
 * Liquidity pool and LP token share the same contract.
 */
interface ICurveStableSwapFactoryNG {
    /**
     * @notice Deploys a stableswap NG metapool
     * @param _base_pool Address of the base pool to pair the token with. For tripool (DAI-USDT-USDC) use its pool
     * address at 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7.
     * @param _name Name of the new metapool, ex: `Dollar/3CRV`
     * @param _symbol Symbol for the new metapool’s LP token - will be concatenated with the base pool symbol, ex: `Dollar3CRV`
     * @param _coin Address of the coin being used in the metapool, ex: use Dollar token address
     * @param _A Amplification coefficient. If set to 0 then bonding curve acts like Uniswap. Any >0 value
     * makes the bonding curve to swap at 1:1 constant price, the more `_A` the longer the constant price period.
     * Curve recommends set it to 100 for crypto collateralizard stablecoins. This parameter can be updated later.
     * @param _fee Trade fee, given as an integer with 1e10 precision, ex: 4000000 = 0.04% fee
     * @param _offpeg_fee_multiplier Off-peg multiplier. Curve recommends set it to `20000000000`. This parameter can be updated
     * later. More info: https://docs.curve.fi/stableswap-exchange/stableswap-ng/pools/overview/#dynamic-fees
     * @param _ma_exp_time MA time; set as time_in_seconds / ln(2), ex: 866 = 600 seconds, 2597 = 1800 seconds.
     * This parameter can be updated later.
     * @param _implementation_idx Index of the metapool implementation to use. Can be retrieved
     * via `ICurveStableSwapFactoryNG.metapool_implementations()`. There is only 1 metapool implementation right now
     * so use index `0`.
     * @param _asset_type Asset type of the pool as an integer. Available asset type indexes:
     * - 0: Standard ERC20 token with no additional features
     * - 1: Oracle - token with rate oracle (e.g. wstETH)
     * - 2: Rebasing - token with rebase (e.g. stETH)
     * - 3: ERC4626 - token with convertToAssets method (e.g. sDAI)
     * Dollar is a standard ERC20 token so we should use asset type with index `0`.
     * @param _method_id First four bytes of the Keccak-256 hash of the function signatures of
     * the oracle addresses that give rate oracles. This is applied only to asset type `1` (Oracle).
     * For Dollar token deployment set empty.
     * @param _oracle Rate oracle address. This is applied only to asset type `1` (Oracle).
     * For Dollar token deployment set empty address.
     * @return Deployed metapool address
     */
    function deploy_metapool(
        address _base_pool,
        string memory _name,
        string memory _symbol,
        address _coin,
        uint256 _A,
        uint256 _fee,
        uint256 _offpeg_fee_multiplier,
        uint256 _ma_exp_time,
        uint256 _implementation_idx,
        uint8 _asset_type,
        bytes4 _method_id,
        address _oracle
    ) external returns (address);

    /**
     * @notice Deploys a new plain pool
     * @param _name Name of the new plain pool, ex: "LUSD/Dollar"
     * @param _symbol Symbol for the new pool's LP token, ex: "LUSDDollar"
     * @param _coins Array of addresses of the coins being used in the pool
     * @param _A Amplification coefficient. If set to 0 then bonding curve acts like Uniswap. Any >0 value
     * makes the bonding curve to swap at 1:1 constant price, the more `_A` the longer the constant price period.
     * Curve recommends set it to 100 for crypto collateralizard stablecoins. This parameter can be updated later.
     * @param _fee Trade fee, given as an integer with 1e10 precision, ex: 4000000 = 0.04% fee
     * @param _offpeg_fee_multiplier Off-peg multiplier. Curve recommends set it to `20000000000`. This parameter can be updated
     * later. More info: https://docs.curve.fi/stableswap-exchange/stableswap-ng/pools/overview/#dynamic-fees
     * @param _ma_exp_time MA time; set as time_in_seconds / ln(2), ex: 866 = 600 seconds, 2597 = 1800 seconds.
     * This parameter can be updated later.
     * @param _implementation_idx Index of the plain pool implementation to use. Can be retrieved
     * via `ICurveStableSwapFactoryNG.pool_implementations()`. There is only 1 plain pool implementation right now
     * so use index `0`.
     * @param _asset_types Asset types of the pool tokens as an integer. Available asset type indexes:
     * - 0: Standard ERC20 token with no additional features
     * - 1: Oracle - token with rate oracle (e.g. wstETH)
     * - 2: Rebasing - token with rebase (e.g. stETH)
     * - 3: ERC4626 - token with convertToAssets method (e.g. sDAI)
     * Both Dollar and LUSD are standard ERC20 tokens so we should use asset types with index `0`.
     * @param _method_ids Array of first four bytes of the Keccak-256 hash of the function signatures of
     * the oracle addresses that give rate oracles. This is applied only to asset type `1` (Oracle).
     * For Dollar token deployment set empty.
     * @param _oracles Array of rate oracle addresses. This is applied only to asset type `1` (Oracle).
     * For Dollar token deployment set empty address.
     * @return Deployed plain pool address
     */
    function deploy_plain_pool(
        string memory _name,
        string memory _symbol,
        address[] memory _coins,
        uint256 _A,
        uint256 _fee,
        uint256 _offpeg_fee_multiplier,
        uint256 _ma_exp_time,
        uint256 _implementation_idx,
        uint8[] memory _asset_types,
        bytes4[] memory _method_ids,
        address[] memory _oracles
    ) external returns (address);
}
