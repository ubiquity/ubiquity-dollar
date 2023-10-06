// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IUniswapV2Router01} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMetaPool} from "../../../src/dollar/interfaces/IMetaPool.sol";
import {ManagerFacet} from "../../../src/dollar/facets/ManagerFacet.sol";
import {DollarMintExcessFacet} from "../../../src/dollar/facets/DollarMintExcessFacet.sol";
import "../DiamondTestSetup.sol";

contract DollarMintExcessFacetTest is DiamondTestSetup {
    address dollarManagerAddress;
    address treasuryAddress;
    address twapOracleAddress;
    address excessDollarsDistributorAddress;
    address _sushiSwapRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    function setUp() public virtual override {
        super.setUp();
        dollarManagerAddress = address(diamond);
        twapOracleAddress = address(diamond);

        excessDollarsDistributorAddress = address(dollarMintExcessFacet);
        treasuryAddress = managerFacet.treasuryAddress();
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
        address _stakingContractAddress
    ) public {
        vm.store(
            dollarManagerAddress,
            bytes32(uint256(13)),
            bytes32(abi.encodePacked(_stakingContractAddress))
        );
        vm.store(
            dollarManagerAddress,
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
        ManagerFacet(dollarManagerAddress).setStableSwapMetaPoolAddress(
            _metaPoolAddress
        );
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
        // TODO: To mock up the array of uint256[] for sushiswap/uniswap routerV2, we use vm.mockCall.
        // function mockCall(address where, bytes calldata data, bytes calldata retdata) external;
        // The problem here is that it doesn't return uint256[] even if we configure it like abi.encode(retVal) => retVal: uint256[]
        // Once we figure it out, we should remove Fails from function name.

        // mock up external calls
        mockSushiSwapRouter(10e18);
        mockMetaPool(address(0x55555), 10e18, 10e18);
        mockManagerAddresses(address(0x123), address(0x456));
        dollarToken.mint(excessDollarsDistributorAddress, 200e18);

        // 10% should be transferred to the treasury address
        uint256 _before_treasury_bal = dollarToken.balanceOf(treasuryAddress);

        DollarMintExcessFacet(excessDollarsDistributorAddress)
            .distributeDollars();
        uint256 _after_treasury_bal = dollarToken.balanceOf(treasuryAddress);
        assertEq(_after_treasury_bal - _before_treasury_bal, 20e18);
    }
}
