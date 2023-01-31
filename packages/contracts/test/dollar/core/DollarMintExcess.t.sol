// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUniswapV2Router01} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import {DollarMintExcess} from "../../../src/dollar/core/DollarMintExcess.sol";
import {UbiquityDollarManager} from "../../../src/dollar/core/UbiquityDollarManager.sol";
import {IMetaPool} from "../../../src/dollar/interfaces/IMetaPool.sol";

import "../../helpers/LocalTestHelper.sol";

// exposes internal methods as external for testing
contract DollarMintExcessHarness is DollarMintExcess {
    constructor(UbiquityDollarManager _manager) DollarMintExcess(_manager) {}

    function exposed_swapDollarsForGovernance(
        bytes16 amountIn
    ) external returns (uint256) {
        return _swapDollarsForGovernance(amountIn);
    }

    function exposed_governanceBuyBackLPAndBurn(uint256 amount) external {
        _governanceBuyBackLPAndBurn(amount);
    }

    function exposed_convertToCurveLPAndTransfer(
        uint256 amount
    ) external returns (uint256) {
        return _convertToCurveLPAndTransfer(amount);
    }
}

contract DollarMintExcessTest is LocalTestHelper {
    UbiquityDollarManager dollarManager;
    DollarMintExcessHarness dollarMintExcessHarness;

    address sushiSwapRouterAddress = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    function setUp() public override {
        super.setUp();
        dollarMintExcessHarness = new DollarMintExcessHarness(manager);
        address dollarManagerAddress = address(manager);
        address twapOracleAddress = UbiquityDollarManager(dollarManagerAddress)
            .twapOracleAddress();
        address dollarAddress = manager.dollarTokenAddress();
        address excessDollarsDistributorAddress = address(
            new DollarMintExcess(manager)
        );
    }

    function testFailDistributeDollars_ShouldTransferTokens() public {
        // mock dollar token
        vm.mockCall(
            dollarManager.dollarTokenAddress(),
            abi.encodeWithSelector(IERC20.balanceOf.selector),
            abi.encode(200 ether)
        );
        vm.mockCall(
            dollarManager.dollarTokenAddress(),
            abi.encodeWithSelector(IERC20.transfer.selector),
            abi.encode()
        );

        // mock router
        vm.etch(sushiSwapRouterAddress, new bytes(0x42));
        uint256[] memory amountsOut = new uint256[](2);
        amountsOut[0] = 0;
        amountsOut[1] = 2 ether;
        vm.mockCall(
            sushiSwapRouterAddress,
            abi.encodeWithSelector(
                IUniswapV2Router01.swapExactTokensForTokens.selector
            ),
            abi.encode(amountsOut)
        );
        vm.mockCall(
            sushiSwapRouterAddress,
            abi.encodeWithSelector(IUniswapV2Router01.addLiquidity.selector),
            abi.encode(1, 1, 1)
        );

        // mock stable swap meta pool and curve3pool
        address stableSwapMetaPoolAddress = address(0x01);
        address curve3PoolTokenAddress = address(0x02);
        vm.prank(admin);
        dollarManager.setStableSwapMetaPoolAddress(stableSwapMetaPoolAddress);
        vm.mockCall(
            stableSwapMetaPoolAddress,
            abi.encodeWithSelector(IMetaPool.exchange.selector),
            abi.encode(1 ether)
        );
        vm.store(
            address(dollarManager),
            bytes32(uint256(9)),
            bytes32(abi.encode(curve3PoolTokenAddress))
        );
        vm.etch(curve3PoolTokenAddress, new bytes(0x42));
        vm.mockCall(
            curve3PoolTokenAddress,
            abi.encodeWithSelector(IERC20.approve.selector),
            abi.encode(true)
        );
        vm.mockCall(
            stableSwapMetaPoolAddress,
            abi.encodeWithSelector(IMetaPool.add_liquidity.selector),
            abi.encode(1 ether)
        );

        // distribute
        vm.expectCall(
            dollarManager.dollarTokenAddress(),
            abi.encodeCall(
                IERC20.transfer,
                (dollarManager.treasuryAddress(), 100 ether)
            )
        );
        dollarMintExcess.distributeDollars();
    }

    function testSwapDollarsForGovernance_ShouldReturnSwapOutputAmount()
        public
    {
        // mock router
        vm.etch(sushiSwapRouterAddress, new bytes(0x42));
        uint256[] memory amountsOut = new uint256[](2);
        amountsOut[0] = 0;
        amountsOut[1] = 1 ether;
        vm.mockCall(
            sushiSwapRouterAddress,
            abi.encodeWithSelector(
                IUniswapV2Router01.swapExactTokensForTokens.selector
            ),
            abi.encode(amountsOut)
        );
        // make a swap
        assertEq(
            dollarMintExcessHarness.exposed_swapDollarsForGovernance(
                bytes16(0x00000000000000000000000000000001)
            ),
            1 ether
        );
    }

    function testFailGovernanceBuyBackLPAndBurn_ShouldAllLiquidityToZeroAddress()
        public
    {
        // mock router
        vm.etch(sushiSwapRouterAddress, new bytes(0x42));
        uint256[] memory amountsOut = new uint256[](2);
        amountsOut[0] = 0;
        amountsOut[1] = 2 ether;
        vm.mockCall(
            sushiSwapRouterAddress,
            abi.encodeWithSelector(
                IUniswapV2Router01.swapExactTokensForTokens.selector
            ),
            abi.encode(amountsOut)
        );
        vm.mockCall(
            sushiSwapRouterAddress,
            abi.encodeWithSelector(IUniswapV2Router01.addLiquidity.selector),
            abi.encode(1, 1, 1)
        );
        // add liquidity
        vm.expectCall(
            sushiSwapRouterAddress,
            abi.encodeCall(
                IUniswapV2Router01.addLiquidity,
                (
                    dollarManager.dollarTokenAddress(),
                    dollarManager.governanceTokenAddress(),
                    0.5 ether,
                    2 ether,
                    0,
                    0,
                    address(0),
                    block.timestamp + 100
                )
            )
        );
        dollarMintExcessHarness.exposed_governanceBuyBackLPAndBurn(1 ether);
    }

    function testFailConvertToCurveLPAndTransfer_ShouldAddLiquidity() public {
        // prepare mocks
        address stableSwapMetaPoolAddress = address(0x01);
        address curve3PoolTokenAddress = address(0x02);
        vm.prank(admin);
        manager.setStableSwapMetaPoolAddress(stableSwapMetaPoolAddress);
        vm.mockCall(
            stableSwapMetaPoolAddress,
            abi.encodeWithSelector(IMetaPool.exchange.selector),
            abi.encode(1 ether)
        );

        vm.store(
            address(dollarManager),
            bytes32(uint256(9)),
            bytes32(abi.encode(curve3PoolTokenAddress))
        );
        vm.etch(curve3PoolTokenAddress, new bytes(0x42));
        vm.mockCall(
            curve3PoolTokenAddress,
            abi.encodeWithSelector(IERC20.approve.selector),
            abi.encode(true)
        );

        vm.mockCall(
            stableSwapMetaPoolAddress,
            abi.encodeWithSelector(IMetaPool.add_liquidity.selector),
            abi.encode(1 ether)
        );

        // add liquidity
        assertEq(
            dollarMintExcessHarness.exposed_convertToCurveLPAndTransfer(
                1 ether
            ),
            1 ether
        );
    }
}
