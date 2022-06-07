// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import {ERC20} from "../solmate/tokens/ERC20.sol";
import "./IERC4626.sol";
import "./IERC4626Router.sol";
import "./IRateCalculator.sol";

/** 
 @title ProxyYieldAggregator Interface
 */
interface IProxyYieldAggregator {

    /************************** Errors **************************/

    /// @notice thrown when amount of assets received is below the min set by caller
    error MinAmountError();

    /// @notice thrown when amount of shares received is below the min set by caller
    error MinSharesError();

    /// @notice thrown when amount of assets received is above the max set by caller
    error MaxAmountError();

    /// @notice thrown when amount of shares received is above the max set by caller
    error MaxSharesError();


    /************************** Assets **************************/

    /**
     @notice add `asset` into this contract.
     @param asset The ERC20 token address.
     @return isAdded If asset is successfully added, then true or false.
    */
    function addAsset(
        ERC20 asset
    ) external returns (bool isAdded);

    /**
     @notice pause `asset`.
     @param asset The ERC20 token address.
     @return isPaused If asset is successfully paused, then true or false.
    */
    function pauseAsset(
        ERC20 asset
    ) external returns (bool isPaused);

    /************************** Calculator **************************/

    /**
     @notice set Set calculator contract to get rate.
     @param calculator Calculator contract address.
     @return success If calculator is successfully set, then true or false.
    */
    function setCalculator(
        IRateCalculator calculator
    ) external returns (bool success);

    /************************** Mint **************************/

    /**
     @notice mint `shares` from an ERC4626 vault.
     @param vault The ERC4626 vault to mint shares from.
     @param to The destination of ownership shares.
     @param shares The amount of shares to mint from `vault`.
     @param maxAmountIn The max amount of assets used to mint.
     @return amountIn the amount of assets used to mint by `to`.
     @dev throws MaxAmountError
    */
    function mint(
        IERC4626 vault,
        address to,
        uint256 shares,
        uint256 maxAmountIn
    ) external payable returns (uint256 amountIn);

    /************************** Deposit **************************/

    /**
     @notice deposit `amount` to an ERC4626 vault.
     @param vault The ERC4626 vault to deposit assets to.
     @param to The destination of ownership shares.
     @param amount The amount of assets to deposit to `vault`.
     @param minSharesOut The min amount of `vault` shares received by `to`.
     @return sharesOut the amount of shares received by `to`.
     @dev throws MinSharesError
    */
    function deposit(
        IERC4626 vault,
        address to,
        uint256 amount,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut);

    /************************** Withdraw **************************/

    /**
     @notice withdraw `amount` from an ERC4626 vault.
     @param vault The ERC4626 vault to withdraw assets from.
     @param to The destination of assets.
     @param amount The amount of assets to withdraw from vault.
     @param minSharesOut The min amount of shares received by `to`.
     @return sharesOut the amount of shares received by `to`.
     @dev throws MaxSharesError
    */
    function withdraw(
        IERC4626 vault,
        address to,
        uint256 amount,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut);

    /************************** Redeem **************************/

    /**
     @notice redeem `shares` shares from an ERC4626 vault.
     @param vault The ERC4626 vault to redeem shares from.
     @param to The destination of assets.
     @param shares The amount of shares to redeem from vault.
     @param minAmountOut The min amount of assets received by `to`.
     @return amountOut the amount of assets received by `to`.
     @dev throws MinAmountError
    */
    function redeem(
        IERC4626 vault,
        address to,
        uint256 shares,
        uint256 minAmountOut
    ) external payable returns (uint256 amountOut);

    /************************** Deposit **************************/

    /**
     @notice deposit `amount` to an ERC4626 vault.
     @param vault The ERC4626 vault to deposit assets to.
     @param to The destination of ownership shares.
     @param amount The amount of assets to deposit to `vault`.
     @param minSharesOut The min amount of `vault` shares received by `to`.
     @return sharesOut the amount of shares received by `to`.
     @dev throws MinSharesError
    */
    function depositToVault(
        IERC4626 vault,
        address to,
        uint256 amount,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut);

    /**
     @notice deposit max assets to an ERC4626 vault.
     @param vault The ERC4626 vault to deposit assets to.
     @param to The destination of ownership shares.
     @param minSharesOut The min amount of `vault` shares received by `to`.
     @return sharesOut the amount of shares received by `to`.
     @dev throws MinSharesError
    */
    function depositMax(
        IERC4626 vault,
        address to,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut);

    /************************** Withdraw **************************/

    /**
     @notice withdraw `amount` to an ERC4626 vault.
     @param fromVault The ERC4626 vault to withdraw assets from.
     @param toVault The ERC4626 vault to deposit assets to.
     @param to The destination of ownership shares.
     @param amount The amount of assets to withdraw from fromVault.
     @param maxSharesIn The max amount of fromVault shares withdrawn by caller.
     @param minSharesOut The min amount of toVault shares received by `to`.
     @return sharesOut the amount of shares received by `to`.
     @dev throws MaxSharesError, MinSharesError
    */
    function withdrawToDeposit(
        IERC4626 fromVault,
        IERC4626 toVault,
        address to,
        uint256 amount,
        uint256 maxSharesIn,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut);

    /************************** Redeem **************************/

    /**
     @notice redeem `shares` to an ERC4626 vault.
     @param fromVault The ERC4626 vault to redeem shares from.
     @param toVault The ERC4626 vault to deposit assets to.
     @param to The destination of ownership shares.
     @param shares The amount of shares to redeem from fromVault.
     @param minSharesOut The min amount of toVault shares received by `to`.
     @return sharesOut the amount of shares received by `to`.
     @dev throws MinAmountError, MinSharesError
    */
    function redeemToDeposit(
        IERC4626 fromVault,
        IERC4626 toVault,
        address to,
        uint256 shares,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut);

    /**
     @notice redeem max shares to an ERC4626 vault.
     @param vault The ERC4626 vault to redeem shares from.
     @param to The destination of assets.
     @param minAmountOut The min amount of assets received by `to`.
     @return amountOut the amount of assets received by `to`.
     @dev throws MinAmountError
    */
    function redeemMax(
        IERC4626 vault,
        address to,
        uint256 minAmountOut
    ) external payable returns (uint256 amountOut);



}
