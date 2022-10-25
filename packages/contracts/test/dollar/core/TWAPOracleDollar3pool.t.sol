// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IMetaPool} from "../../../src/dollar/interfaces/IMetaPool.sol";
import {MockMetaPool} from "../../../src/dollar/mocks/MockMetaPool.sol";
import {TWAPOracleDollar3pool} from
    "../../../src/dollar/core/TWAPOracleDollar3pool.sol";
import "../../helpers/LocalTestHelper.sol";

contract TWAPOracleDollar3poolTest is LocalTestHelper {
    address dollarTokenAddress = address(0x222);
    address curve3CRVTokenAddress = address(0x333);
    address twapOracleAddress;
    address metaPoolAddress;

    function setUp() public {
        metaPoolAddress =
            address(new MockMetaPool(dollarTokenAddress, curve3CRVTokenAddress));
        twapOracleAddress = address(
            new TWAPOracleDollar3pool(metaPoolAddress, dollarTokenAddress, curve3CRVTokenAddress)
        );
    }

    function test_overall() public {
        // set the mock data for meta pool
        uint256[2] memory _price_cumulative_last =
            [uint256(100e18), uint256(100e18)];
        uint256 _last_block_timestamp = 20000;
        uint256[2] memory _twap_balances = [uint256(100e18), uint256(100e18)];
        uint256[2] memory _dy_values = [uint256(100e18), uint256(100e18)];
        MockMetaPool(metaPoolAddress).updateMockParams(
            _price_cumulative_last,
            _last_block_timestamp,
            _twap_balances,
            _dy_values
        );

        TWAPOracleDollar3pool(twapOracleAddress).update();

        uint256 amount0Out =
            TWAPOracleDollar3pool(twapOracleAddress).consult(dollarTokenAddress);
        uint256 amount1Out = TWAPOracleDollar3pool(twapOracleAddress).consult(
            curve3CRVTokenAddress
        );
        assertEq(amount0Out, 100e18);
        assertEq(amount1Out, 100e18);
    }
}
