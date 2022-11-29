// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

import "./IERC20Ubiquity.sol";

/// @title Ubiquity Dollar stablecoin interface
/// @author Ubiquity Dollar
interface IUbiquityDollarToken is IERC20Ubiquity {
    event IncentiveContractUpdate(
        address indexed _incentivized, address indexed _incentiveContract
    );

    function setIncentiveContract(address account, address incentive)
        external;

    function incentiveContract(address account)
        external
        view
        returns (address);
}
