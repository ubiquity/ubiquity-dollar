// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

// import {IMetaPool} from "../../../src/dollar/interfaces/IMetaPool.sol";

// import "../DiamondTestSetup.sol";

// contract TWAPOracleDollar3poolFacetTest is DiamondSetup {
    
//     address twapOracleAddress;
//     address metaPoolAddress;

//     function setUp() public override {
//         super.setUp();

//         metaPoolAddress = 
//             curveFactory.deploy_metapool(
//                 address(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7), 
//                 "Ubiquity MetaPool", 
//                 "UAD3CRV", 
//                 address(IDollar), 
//                 10, 
//                 4000000);
    
//         vm.prank(owner);
//         ITWAPOracleDollar3pool.setPool(metaPoolAddress, address(crv3Token));
//     }

//     function test_overall() public {
//         // set the mock data for meta pool
//         uint256[2] memory _price_cumulative_last = [
//             uint256(100e18),
//             uint256(100e18)
//         ];
//         uint256 _last_block_timestamp = 20000;
//         uint256[2] memory _twap_balances = [uint256(100e18), uint256(100e18)];
//         uint256[2] memory _dy_values = [uint256(100e18), uint256(100e18)];
//         MockMetaPool(metaPoolAddress).updateMockParams(
//             _price_cumulative_last,
//             _last_block_timestamp,
//             _twap_balances,
//             _dy_values
//         );
//         ITWAPOracleDollar3pool.update();

//         uint256 amount0Out = ITWAPOracleDollar3pool.consult(address(IDollar));
//         uint256 amount1Out = ITWAPOracleDollar3pool.consult(
//             address(crv3Token)
//         );
//         assertEq(amount0Out, 100e18);
//         assertEq(amount1Out, 100e18);
//     }
// }
