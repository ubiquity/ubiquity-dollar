// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../libs/ABDKMathQuad.sol";
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

    // This is the exchange rate of uAR for the start block.
    bytes16 public rateStartValue;

    // Deprecation rate. How much uAD is deprecated on each block.
    bytes16 public ratePerBlock;

    event SetRatePerBlock(
        uint256 rateStartBlock, bytes16 rateStartValue, bytes16 ratePerBlock
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
    constructor(UbiquityDollarManager _manager, bytes16 _rateStartValue, bytes16 _ratePerBlock) {
        manager = _manager;
        rateStartBlock = block.number;
        rateStartValue = _rateStartValue;
        ratePerBlock = _ratePerBlock;

        emit SetRatePerBlock(rateStartBlock, rateStartValue, ratePerBlock);
    }

    /// @dev Sets rate to apply from this block onward.
    /// @param _ratePerBlock ABDKMathQuad New rate per block to apply from this block onward.
    function setRatePerBlock(bytes16 _ratePerBlock)
        external
        onlyAdmin
    {
        rateStartValue = calculateRate(rateStartValue, ratePerBlock, block.number - rateStartBlock);
        rateStartBlock = block.number;
        ratePerBlock = _ratePerBlock;

        emit SetRatePerBlock(rateStartBlock, rateStartValue, ratePerBlock);
    }

    /// @dev Calculates b raised to the power of n.
    /// @param b ABDKMathQuad
    /// @param n ABDKMathQuad
    /// @return ABDKMathQuad b ^ n
    function pow(bytes16 b, bytes16 n)
        private
        pure
        returns (bytes16)
    {
        // b ^ n == 2^(n*log²(b))
        return n.mul(b.log_2()).pow_2();
    }

    /// @dev Calculate rateStartValue * ( 1 / ( (1 + ratePerBlock) ^ blockDelta) ) )
    /// @param _rateStartValue ABDKMathQuad The initial value of the rate.
    /// @param _ratePerBlock ABDKMathQuad The rate per block.
    /// @param blockDelta How many blocks after the rate was set.
    /// @return rate ABDKMathQuad The rate calculated.
    function calculateRate(bytes16 _rateStartValue, bytes16 _ratePerBlock, uint blockDelta)
        public
        view
        returns (bytes16 rate)
    {
        rate = _rateStartValue.mul(
            one.div(
                pow(
                    one.add(_ratePerBlock),
                    (blockDelta).fromUInt()
                )
            )
        );
    }

    /// @dev Calculates rate at a specific block number.
    /// @param blockNumber Block number to get the rate for. 0 for current block.
    /// @return rate ABDKMathQuad The rate calculated for the block number.
    function getRate(uint256 blockNumber)
        external
        view
        returns (bytes16 rate)
    {
        if (blockNumber == 0) {
            blockNumber = block.number;
        }
        else {
            if (blockNumber < block.number) revert ("CreditClock: block number must not be in the past.");
        }

        rate = calculateRate(rateStartValue, ratePerBlock, blockNumber - rateStartBlock);
    }

}
