// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import {IERC20Ubiquity} from "../../dollar/interfaces/IERC20Ubiquity.sol";
import "../../dollar/interfaces/IMetaPool.sol";
import "../../dollar/SushiSwapPool.sol";
import "abdk-libraries-solidity/ABDKMathQuad.sol";
import {LibAppStorage} from "./LibAppStorage.sol";
import {LibDollar} from "./LibDollar.sol";

/// @title An excess dollar distributor which sends dollars to treasury,
/// lp rewards and inflation rewards
library LibDollarMintExcess {
    using SafeERC20 for IERC20Ubiquity;
    using SafeERC20 for IERC20;
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    uint256 private constant _minAmountToDistribute = 100 ether;
    IUniswapV2Router01 private constant _router =
        IUniswapV2Router01(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F); // SushiV2Router02

    function distributeDollars() internal {
        //the excess dollars which were sent to this contract by the coupon manager
        uint256 excessDollars = LibDollar.balanceOf(address(this));
        if (excessDollars > _minAmountToDistribute) {
            address treasuryAddress = LibAppStorage
                .appStorage()
                .treasuryAddress;

            // curve UbiquityDollar-3CRV liquidity pool
            uint256 tenPercent = excessDollars
                .fromUInt()
                .div(uint256(10).fromUInt())
                .toUInt();
            uint256 fiftyPercent = excessDollars
                .fromUInt()
                .div(uint256(2).fromUInt())
                .toUInt();
            IERC20Ubiquity(address(this)).safeTransfer(
                treasuryAddress,
                fiftyPercent
            );
            // convert Ubiquity Dollar to GovernanceToken-DollarToken LP on sushi and burn them
            _governanceBuyBackLPAndBurn(tenPercent);
            // convert remaining Ubiquity Dollar to curve LP tokens
            // and transfer the curve LP tokens to the staking contract
            _convertToCurveLPAndTransfer(
                excessDollars - fiftyPercent - tenPercent
            );
        }
    }

    // swap half amount to Governance Token
    function _swapDollarsForGovernance(
        bytes16 amountIn
    ) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = LibAppStorage.appStorage().governanceTokenAddress;
        uint256[] memory amounts = _router.swapExactTokensForTokens(
            amountIn.toUInt(),
            0,
            path,
            address(this),
            block.timestamp + 100
        );

        return amounts[1];
    }

    // buy-back and burn Governance Token
    function _governanceBuyBackLPAndBurn(uint256 amount) internal {
        bytes16 amountDollars = (amount.fromUInt()).div(uint256(2).fromUInt());

        // we need to approve sushi router
        IERC20Ubiquity(address(this)).safeApprove(address(_router), 0);
        IERC20Ubiquity(address(this)).safeApprove(address(_router), amount);
        uint256 amountGovernanceTokens = _swapDollarsForGovernance(
            amountDollars
        );
        address governanceTokenAddress = LibAppStorage
            .appStorage()
            .governanceTokenAddress;
        IERC20Ubiquity(governanceTokenAddress).safeApprove(address(_router), 0);
        IERC20Ubiquity(governanceTokenAddress).safeApprove(
            address(_router),
            amountGovernanceTokens
        );

        // deposit liquidity and transfer to zero address (burn)
        _router.addLiquidity(
            address(this),
            governanceTokenAddress,
            amountDollars.toUInt(),
            amountGovernanceTokens,
            0,
            0,
            address(0),
            block.timestamp + 100
        );
    }

    // @dev convert to curve LP
    // @param amount to convert to curve LP by swapping to 3CRV
    //        and deposit the 3CRV as liquidity to get UbiquityDollar-3CRV LP tokens
    //        the LP token are sent to the staking contract
    function _convertToCurveLPAndTransfer(
        uint256 amount
    ) internal returns (uint256) {
        address stableSwapMetaPoolAddress = LibAppStorage
            .appStorage()
            .stableSwapMetaPoolAddress;
        address curve3PoolTokenAddress = LibAppStorage
            .appStorage()
            .curve3PoolTokenAddress;
        // we need to approve metaPool
        IERC20Ubiquity(address(this)).approve(stableSwapMetaPoolAddress, 0);
        IERC20Ubiquity(address(this)).approve(
            stableSwapMetaPoolAddress,
            amount
        );

        // swap amount of Ubiquity Dollar => 3CRV
        uint256 amount3CRVReceived = IMetaPool(stableSwapMetaPoolAddress)
            .exchange(0, 1, amount, 0);

        // approve metapool to transfer our 3CRV
        IERC20(curve3PoolTokenAddress).approve(stableSwapMetaPoolAddress, 0);
        IERC20(curve3PoolTokenAddress).approve(
            stableSwapMetaPoolAddress,
            amount3CRVReceived
        );

        // deposit liquidity
        uint256 res = IMetaPool(stableSwapMetaPoolAddress).add_liquidity(
            [0, amount3CRVReceived],
            0,
            address(this) // stacking contract
        );
        // update TWAP price
        return res;
    }
}
