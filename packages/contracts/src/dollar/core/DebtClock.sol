// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../libs/ABDKMathQuad.sol";
import "./UbiquityDollarManager.sol";

contract DebtClock {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    UbiquityDollarManager public manager;

    uint256 public rateStartBlock;
    bytes16 public rateStartValue;
    bytes16 public ratePerBlock;

    modifier onlyAdmin() {
        require(
            manager.hasRole(manager.INCENTIVE_MANAGER_ROLE(), msg.sender),
            "DebtClock: not admin"
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
    /// @param _ratePerBlock New rate per block to apply from this block onward.
    function setRatePerBlock(bytes16 _ratePerBlock)
        external
        onlyAdmin
    {
        rateStartBlock = block.number;
        rateStartValue = rate(block.number);
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

    /// @dev Calculate rateStartValue * ( 1 / ( (1 + ratePerBlock) ^ (blockNumber - rateStartBlock) ) )
    /// @param blockNumber Block number to get the rate for. 0 for current block.
    /// @return ABDKMathQuad The rate calculated for the block number.
    function rate(uint256 blockNumber)
        public
        view
        returns (bytes16)
    {
        if (blockNumber == 0) {
            blockNumber = block.number;
        }
        else {
            if (blockNumber < block.number) revert ("DebtClock: block number must not be in the past.");
        }

        return rateStartValue.mul(
            uint256(1).fromUInt().div(
                pow(
                    uint256(1).fromUInt().add(ratePerBlock),
                    (blockNumber - rateStartBlock).fromUInt()
                )
            )
        );
    }

}
