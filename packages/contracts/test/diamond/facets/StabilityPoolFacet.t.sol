// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {StabilityPoolFacet} from "../../src/dollar/facets/StabilityPoolFacet.sol";
import {LibStabilityPool} from "../../src/dollar/libraries/LibStabilityPool.sol";

contract MockStabilityPool {
    uint256 public deposits;
    uint256 public ethGain;
    uint256 public lqtyGain;

    function provideToSP(uint256 _amount, address) external {
        deposits += _amount;
    }

    function withdrawFromSP(uint256 _amount) external {
        if (_amount <= deposits) {
            deposits -= _amount;
        } else {
            deposits = 0;
        }
    }

    function setGains(uint256 _eth, uint256 _lqty) external {
        ethGain = _eth;
        lqtyGain = _lqty;
    }

    function getDepositorETHGain(address) external view returns (uint256) {
        return ethGain;
    }

    function getDepositorLQTYGain(address) external view returns (uint256) {
        return lqtyGain;
    }

    function getCompoundedLUSDDeposit(address) external view returns (uint256) {
        return deposits;
    }

    receive() external payable {}
}

contract StabilityPoolFacetTest is Test {
    StabilityPoolFacet facet;
    MockStabilityPool mockPool;
    address treasury = address(0x1111);
    address lusd = address(0x2222);
    address lqty = address(0x3333);

    function setUp() public {
        facet = new StabilityPoolFacet();
        mockPool = new MockStabilityPool();
    }

    function test_InitialState() public {
        assertTrue(true);
    }
}
