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

    /// @param _manager the address of the manager/config contract so we can fetch variables
    constructor(UbiquityDollarManager _manager, bytes16 _rateStartValue, bytes16 _ratePerBlock) {
        manager = _manager;
        rateStartBlock = block.number;
        rateStartValue = _rateStartValue;
        ratePerBlock = _ratePerBlock;
    }

    function setRatePerBlock(bytes16 _ratePerBlock)
        external
        onlyAdmin
    {
        rateStartBlock = block.number;
        rateStartValue = rate(block.number);
        ratePerBlock = _ratePerBlock;
    }

    function pow(bytes16 x, bytes16 y) private pure returns(bytes16 result) {
       result = y.mul(x.log_2()).pow_2();
    }

    function rate(uint256 blockNumber)
        public
        view
        returns (bytes16)
    {
        if (blockNumber == 0) blockNumber = block.number;

        return rateStartValue.mul(
            uint256(1 ether).fromUInt().div(
                pow(
                    uint256(1 ether).fromUInt().add(ratePerBlock),
                    (blockNumber - rateStartBlock).fromUInt()
                )
            )
        );
    }

}
