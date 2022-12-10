// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IMetaPool} from "../../src/dollar/interfaces/IMetaPool.sol";
import {MockMetaPool} from "../../src/dollar/mocks/MockMetaPool.sol";
import {TWAPOracle} from "../../src/dollar/TWAPOracle.sol";
import "../helpers/LocalTestHelper.sol";

contract TWAPOracleTest is LocalTestHelper {
    address uadTokenAddress = address(0x222);
    address curve3CRVTokenAddress = address(0x333);
    TWAPOracle twapOracle;
    MockMetaPool metaPool;

    function setUp() public {
        metaPool =
            new MockMetaPool(uadTokenAddress, curve3CRVTokenAddress);
        twapOracle = 
            new TWAPOracle(address(metaPool), uadTokenAddress, curve3CRVTokenAddress)
        ;
    }

    function test_overall() public {
        // set the mock data for meta pool
        uint256[2] memory _price_cumulative_last =
            [uint256(100e18), uint256(100e18)];
        uint256 _last_block_timestamp = 20000;
        uint256[2] memory _twap_balances = [uint256(100e18), uint256(100e18)];
        uint256[2] memory _dy_values = [uint256(100e18), uint256(100e18)];
        metaPool.updateMockParams(
            _price_cumulative_last,
            _last_block_timestamp,
            _twap_balances,
            _dy_values
        );

        twapOracle.update();

        uint256 amount0Out =
            twapOracle.consult(uadTokenAddress);
        uint256 amount1Out =
            twapOracle.consult(curve3CRVTokenAddress);
        assertEq(amount0Out, 100e18);
        assertEq(amount1Out, 100e18);
    }
}
