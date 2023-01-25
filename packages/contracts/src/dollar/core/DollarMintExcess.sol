// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "../interfaces/IERC20Ubiquity.sol";
import "../interfaces/IDollarMintExcess.sol";
import "../interfaces/IMetaPool.sol";
import "../SushiSwapPool.sol";
import "../libs/ABDKMathQuad.sol";
import "./UbiquityDollarManager.sol";

/// @title An excess dollar distributor which sends dollars to treasury,
/// lp rewards and inflation rewards
contract DollarMintExcess is IDollarMintExcess {
    using SafeERC20 for IERC20Ubiquity;
    using SafeERC20 for IERC20;
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    UbiquityDollarManager public manager;
    uint256 private immutable _minAmountToDistribute = 100 ether;
    IUniswapV2Router01 private immutable _router =
        IUniswapV2Router01(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F); // SushiV2Router02

    /// @param _manager the address of the manager contract so we can fetch variables
    constructor(address _manager) {
        manager = UbiquityDollarManager(_manager);
    }

    function distributeDollars() external override {
        //the excess dollars which were sent to this contract by the coupon manager
        uint256 excessDollars = IERC20Ubiquity(manager.dollarTokenAddress())
            .balanceOf(address(this));
        if (excessDollars > _minAmountToDistribute) {
            address treasuryAddress = manager.treasuryAddress();

            // curve UbiquityDollar-3CRV liquidity pool
            uint256 tenPercent = excessDollars
                .fromUInt()
                .div(uint256(10).fromUInt())
                .toUInt();
            uint256 fiftyPercent = excessDollars
                .fromUInt()
                .div(uint256(2).fromUInt())
                .toUInt();
            IERC20Ubiquity(manager.dollarTokenAddress()).safeTransfer(
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
        path[0] = manager.dollarTokenAddress();
        path[1] = manager.governanceTokenAddress();
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
        IERC20Ubiquity(manager.dollarTokenAddress()).safeApprove(
            address(_router),
            0
        );
        IERC20Ubiquity(manager.dollarTokenAddress()).safeApprove(
            address(_router),
            amount
        );
        uint256 amountGovernanceTokens = _swapDollarsForGovernance(
            amountDollars
        );

        IERC20Ubiquity(manager.governanceTokenAddress()).safeApprove(
            address(_router),
            0
        );
        IERC20Ubiquity(manager.governanceTokenAddress()).safeApprove(
            address(_router),
            amountGovernanceTokens
        );

        // deposit liquidity and transfer to zero address (burn)
        _router.addLiquidity(
            manager.dollarTokenAddress(),
            manager.governanceTokenAddress(),
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
        // we need to approve metaPool
        IERC20Ubiquity(manager.dollarTokenAddress()).approve(
            manager.stableSwapMetaPoolAddress(),
            0
        );
        IERC20Ubiquity(manager.dollarTokenAddress()).approve(
            manager.stableSwapMetaPoolAddress(),
            amount
        );

        // swap amount of Ubiquity Dollar => 3CRV
        uint256 amount3CRVReceived = IMetaPool(
            manager.stableSwapMetaPoolAddress()
        ).exchange(0, 1, amount, 0);

        // approve metapool to transfer our 3CRV
        IERC20(manager.curve3PoolTokenAddress()).approve(
            manager.stableSwapMetaPoolAddress(),
            0
        );
        IERC20(manager.curve3PoolTokenAddress()).approve(
            manager.stableSwapMetaPoolAddress(),
            amount3CRVReceived
        );

        // deposit liquidity
        uint256 res = IMetaPool(manager.stableSwapMetaPoolAddress())
            .add_liquidity(
                [0, amount3CRVReceived],
                0,
                manager.stakingAddress()
            );
        // update TWAP price
        return res;
    }
}
