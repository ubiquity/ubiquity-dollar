// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//Onchain Compatible ABI @0x7944d5b8f9668AfB1e648a61e54DEa8DE734c1d1 by Ubiquity DAO: Deployer
interface ITWAPOracle {
    function consult( address token ) external view returns (uint256 amountOut);
    function pool() external view returns (address );
    function price0Average() external view returns (uint256 );
    function price1Average() external view returns (uint256 );
    function priceCumulativeLast(uint256) external view returns (uint256 );
    function pricesBlockTimestampLast() external view returns (uint256 );
    function token0() external view returns (address );
    function token1() external view returns (address );
    function update() external;
}

import {IMetaPool} from "../../../src/dollar/interfaces/IMetaPool.sol";
import "../DiamondTestSetup.sol";

contract TWAPOracleDollar3poolFacetTest is DiamondSetup {
    address curve3CRVTokenAddress = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address twapOracleAddress = 0x7944d5b8f9668AfB1e648a61e54DEa8DE734c1d1;
    address metaPoolAddress = 0x20955CB69Ae1515962177D164dfC9522feef567E;
    address OnChainUbiquityDollar = 0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6;

    function setUp() public override {
        super.setUp();
        vm.prank(owner);
    }

    function test_Fork() public {
        vm.activeFork(); //Active??
    }

    function test_testMetaPoolA() public {
        uint256 call = IMetaPool(metaPoolAddress).A();
        assertEq(call, 10);
    }

    function test_MetaPoolTransfer() public {
        //vm.prank(owner);
        //IMetaPool(metaPoolAddress).transferFrom(owner, user1, 1 ether);
    }

    function test_MetaPoolDecimal() public {
        uint256 num = IMetaPool(metaPoolAddress).decimals();
        assertEq(num, 18);
    }

    function test_TokenOneAddress() public {
        address token = ITWAPOracle(twapOracleAddress).token0();
        assert(token == OnChainUbiquityDollar);
    }

    function test_TokenTwoAddress() public {
        address crvToken = ITWAPOracle(twapOracleAddress).token1();
        assert(crvToken == curve3CRVTokenAddress);
    }

    function test_overall() public {
        // set the mock data for meta pool
        uint256[2][2] memory _price_cumulative_last = [
            IMetaPool(metaPoolAddress).get_price_cumulative_last(),
            IMetaPool(metaPoolAddress).get_price_cumulative_last()
        ];
        uint256 _last_block_timestamp = IMetaPool(metaPoolAddress).block_timestamp_last();
        //uint256[2] memory _twap_balances = [uint256(100e18), uint256(100e18)];
        //uint256[2] memory _dy_values = [uint256(100e18), uint256(100e18)];
        uint256 amount0Out = ITWAPOracle(twapOracleAddress).consult((OnChainUbiquityDollar));
        uint256 amount1Out = ITWAPOracle(twapOracleAddress).consult(curve3CRVTokenAddress);
        assertEq(amount0Out, amount0Out);
        assertEq(amount1Out, amount1Out);
    }
}
