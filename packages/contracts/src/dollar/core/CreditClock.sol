// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "abdk/ABDKMathQuad.sol";
import "./UbiquityDollarManager.sol";

contract CreditClock {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    // Manager contract.
    UbiquityDollarManager private immutable manager;

    // ABDKMathQuad with value of 1.
    bytes16 private immutable one = uint256(1).fromUInt();

    // The block height from where we start applying the rate.
    uint256 public rateStartBlock;

    // This is the exchange rate of Credits for the start block.
    bytes16 public rateStartValue;

    // Deprecation rate. How many Dollars are deprecated on each block.
    bytes16 public ratePerBlock;

    event SetRatePerBlock(
        uint256 rateStartBlock,
        bytes16 rateStartValue,
        bytes16 ratePerBlock
    );

    modifier onlyAdmin() {
        require(
            manager.hasRole(manager.INCENTIVE_MANAGER_ROLE(), msg.sender),
            "CreditClock: not admin"
        );
        _;
    }

    /// @param _manager The address of the manager/config contract so we can fetch variables.
    /// @param _rateStartValue ABDKMathQuad Initial rate.
    /// @param _ratePerBlock ABDKMathQuad Initial rate change per block.
    constructor(
        UbiquityDollarManager _manager,
        bytes16 _rateStartValue,
        bytes16 _ratePerBlock
    ) {
        manager = _manager;
        rateStartBlock = block.number;
        rateStartValue = _rateStartValue;
        ratePerBlock = _ratePerBlock;

        emit SetRatePerBlock(rateStartBlock, rateStartValue, ratePerBlock);
    }

    /// @dev Sets rate to apply from this block onward.
    /// @param _ratePerBlock ABDKMathQuad New rate per block to apply from this block onward.
    function setRatePerBlock(bytes16 _ratePerBlock) external onlyAdmin {
        rateStartValue = getRate(block.number);
        rateStartBlock = block.number;
        ratePerBlock = _ratePerBlock;

        emit SetRatePerBlock(rateStartBlock, rateStartValue, ratePerBlock);
    }

    /// @dev Calculate rateStartValue * ( 1 / ( (1 + ratePerBlock) ^ blockNumber - rateStartBlock) ) )
    /// @param blockNumber Block number to get the rate for. 0 for current block.
    /// @return rate ABDKMathQuad The rate calculated for the block number.
    function getRate(uint256 blockNumber) public view returns (bytes16 rate) {
        if (blockNumber == 0) {
            blockNumber = block.number;
        } else {
            if (blockNumber < block.number)
                revert("CreditClock: block number must not be in the past.");
        }
        // slither-disable-next-line divide-before-multiply
        rate = rateStartValue.mul(
            one.div(
                // b ^ n == 2^(n*log²(b))
                (blockNumber - rateStartBlock)
                    .fromUInt()
                    .mul(one.add(ratePerBlock).log_2())
                    .pow_2()
            )
        );
    }
}
