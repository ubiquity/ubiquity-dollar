// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IUniswapV2Router01} from
    "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UbiquityAlgorithmicDollarManager} from
    "../../src/dollar/UbiquityAlgorithmicDollarManager.sol";
import {TWAPOracle} from "../../src/dollar/TWAPOracle.sol";
import {ExcessDollarsDistributor} from
    "../../src/dollar/ExcessDollarsDistributor.sol";
import {IMetaPool} from "../../src/dollar/interfaces/IMetaPool.sol";

import "../helpers/LocalTestHelper.sol";

contract ExcessDollarsDistributorTest is LocalTestHelper {
    address uADManagerAddress;
    address uADAddress;

    address twapOracleAddress;
    address excessDollarsDistributorAddress;
    address _sushiSwapRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    function setUp() public {
        uADManagerAddress = helpers_deployUbiquityAlgorithmicDollarManager();
        twapOracleAddress = UbiquityAlgorithmicDollarManager(uADManagerAddress)
            .twapOracleAddress();
        uADAddress = UbiquityAlgorithmicDollarManager(uADManagerAddress)
            .dollarTokenAddress();
        excessDollarsDistributorAddress =
            address(new ExcessDollarsDistributor(uADManagerAddress));
    }

    function mockSushiSwapRouter(uint256 _expected_swap_amount) public {
        vm.etch(_sushiSwapRouter, new bytes(0x42));
        uint256[] memory amountsOut = new uint256[](2);
        amountsOut[0] = 0;
        amountsOut[1] = _expected_swap_amount;
        vm.mockCall(
            _sushiSwapRouter,
            abi.encodeWithSelector(
                IUniswapV2Router01.swapExactTokensForTokens.selector
            ),
            abi.encode(amountsOut)
        );
        vm.mockCall(
            _sushiSwapRouter,
            abi.encodeWithSelector(IUniswapV2Router01.addLiquidity.selector),
            abi.encode()
        );
    }

    function mockManagerAddresses(
        address _curve3PoolAddress,
        address _bondingContractAddress
    ) public {
        vm.store(
            uADManagerAddress,
            bytes32(uint256(13)),
            bytes32(abi.encodePacked(_bondingContractAddress))
        );
        vm.store(
            uADManagerAddress,
            bytes32(uint256(15)),
            bytes32(abi.encodePacked(_curve3PoolAddress))
        );
        vm.mockCall(
            _curve3PoolAddress,
            abi.encodeWithSelector(IERC20.approve.selector),
            abi.encode()
        );
    }

    function mockMetaPool(
        address _metaPoolAddress,
        uint256 _expectedLiqAmt,
        uint256 _expectedExchangeAmt
    ) public {
        vm.prank(admin);
        UbiquityAlgorithmicDollarManager(uADManagerAddress)
            .setStableSwapMetaPoolAddress(_metaPoolAddress);
        vm.mockCall(
            _metaPoolAddress,
            abi.encodeWithSelector(IMetaPool.exchange.selector),
            abi.encode(_expectedExchangeAmt)
        );
        vm.mockCall(
            _metaPoolAddress,
            abi.encodeWithSelector(IMetaPool.add_liquidity.selector),
            abi.encode(_expectedLiqAmt)
        );
    }

    function testFails_distributeDollarsWorks() public {
        // TODO: To mock up the array of uint256[] for sushiswap/uniswap routerv2, we use vm.mockCall.
        // function mockCall(address where, bytes calldata data, bytes calldata retdata) external;
        // The problem here is that it doesn't return uint256[] even if we configure it like abi.encode(retVal) => retVal: uint256[]
        // Once we figure it out, we should remove Fails from function name.

        // mock up external calls
        mockSushiSwapRouter(10e18);
        mockMetaPool(address(0x55555), 10e18, 10e18);
        mockManagerAddresses(address(0x123), address(0x456));
        MockuADToken(uADAddress).mint(excessDollarsDistributorAddress, 200e18);

        // 10% should be transferred to the treasury address
        uint256 _before_treasury_bal =
            MockuADToken(uADAddress).balanceOf(treasuryAddress);

        ExcessDollarsDistributor(excessDollarsDistributorAddress)
            .distributeDollars();
        uint256 _after_treasury_bal =
            MockuADToken(uADAddress).balanceOf(treasuryAddress);
        assertEq(_after_treasury_bal - _before_treasury_bal, 20e18);
    }
}
