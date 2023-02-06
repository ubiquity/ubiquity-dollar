// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import "./IERC20Ubiquity.sol";

/// @title Ubiquity Dollar stablecoin interface
/// @author Ubiquity DAO
interface IUbiquityDollarToken is IERC20Ubiquity {
    event IncentiveContractUpdate(
        address indexed _incentivized,
        address indexed _incentiveContract
    );

    function setIncentiveContract(address account, address incentive) external;

    function incentiveContract(address account) external view returns (address);
}
