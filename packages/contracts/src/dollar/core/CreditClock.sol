// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../libs/ABDKMathQuad.sol";
import "./UbiquityDollarManager.sol";

contract CreditClock {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    UbiquityDollarManager public manager;

    uint256 public rateStartBlock;
    bytes16 public rateStartValue;
    bytes16 public ratePerBlock;

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
        return n.mul(b.log_2()).pow_2();
    }

    /// @dev Calculates rate a certain number of blocks after rate per block is set.
    /// @param _rateStartValue ABDKMathQuad The initial value of the rate.
    /// @param _ratePerBlock ABDKMathQuad The rate per block.
    /// @param blockDelta How many blocks after the rate was set.
    /// @return rate ABDKMathQuad The rate calculated.
    function calculateRate(bytes16 _rateStartValue, bytes16 _ratePerBlock, uint blockDelta)
        public
        pure
        returns (bytes16 rate)
    {
        rate = _rateStartValue.mul(
            uint256(1).fromUInt().div(
                pow(
                    uint256(1).fromUInt().add(_ratePerBlock),
                    (blockDelta).fromUInt()
                )
            )
        );
    }

    /// @dev Calculate rateStartValue * ( 1 / ( (1 + ratePerBlock) ^ (blockNumber - rateStartBlock) ) )
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
