// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IMetaPool} from "../../../src/dollar/interfaces/IMetaPool.sol";
import {MockMetaPool} from "../../../src/dollar/mocks/MockMetaPool.sol";
import "../DiamondTestSetup.sol";

contract TWAPOracleDollar3poolFacetTest is DiamondTestSetup {
    address curve3CRVTokenAddress = address(0x333);
    address twapOracleAddress;
    address metaPoolAddress;

    function setUp() public override {
        super.setUp();

        metaPoolAddress = address(
            new MockMetaPool(address(dollarToken), curve3CRVTokenAddress)
        );
        vm.prank(owner);
        twapOracleDollar3PoolFacet.setPool(
            metaPoolAddress,
            curve3CRVTokenAddress
        );
    }

    function test_overall() public {
        // set the mock data for meta pool
        uint256[2] memory _price_cumulative_last = [
            uint256(100e18),
            uint256(100e18)
        ];
        uint256 _last_block_timestamp = 20000;
        uint256[2] memory _twap_balances = [uint256(100e18), uint256(100e18)];
        uint256[2] memory _dy_values = [uint256(100e18), uint256(100e18)];
        MockMetaPool(metaPoolAddress).updateMockParams(
            _price_cumulative_last,
            _last_block_timestamp,
            _twap_balances,
            _dy_values
        );
        twapOracleDollar3PoolFacet.update();

        uint256 amount0Out = twapOracleDollar3PoolFacet.consult(
            address(dollarToken)
        );
        uint256 amount1Out = twapOracleDollar3PoolFacet.consult(
            curve3CRVTokenAddress
        );
        assertEq(amount0Out, 100e18);
        assertEq(amount1Out, 100e18);
    }
}
