// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../../dollar/UbiquityAlgorithmicDollarManager.sol";

contract ManagerFacet is UbiquityAlgorithmicDollarManager {

    address public creditTokenAddress; // uCR

    constructor(address addr) UbiquityAlgorithmicDollarManager(addr) {}

    function setuCRTokenAddress(address _uCRTokenAddress) external onlyAdmin {
        creditTokenAddress = _uCRTokenAddress;
    }
}