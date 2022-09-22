// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/*
echidna-test ExampleEchidnaTest.sol --contract ExampleEchidnaTest
*/
contract Counter {
    uint256 public count;

    function inc() external {
        count += 1;
    }

    function dec() external {
        count -= 1;
    }
}

contract ExampleEchidnaTest is Counter {
    function echidna_test_true() public pure returns (bool) {
        return true;
    }

    function echidna_test_false() public pure returns (bool) {
        return false;
    }

    function echidna_test_count() public view returns (bool) {
        // Here we are testing that Counter.count should always be <= 5.
        // Test will fail. Echidna is smart enough to call Counter.inc() more
        // than 5 times.
        return count <= 5;
    }
}

/*
echidna-test ExampleEchidnaTest.sol --contract TestAssert --check-asserts
*/
contract TestAssert {
    // Asserts not detected in 0.8.
    // Switch to 0.7 to test assertions
    function test_assert(uint256 _i) external pure {
        assert(_i < 10);
    }

    // More complex example
    function abs(uint256 x, uint256 y) private pure returns (uint256) {
        if (x >= y) {
            return x - y;
        }
        return y - x;
    }

    function test_abs(uint256 x, uint256 y) external pure {
        uint256 z = abs(x, y);
        if (x >= y) {
            assert(z <= x);
        } else {
            assert(z <= y);
        }
    }
}
