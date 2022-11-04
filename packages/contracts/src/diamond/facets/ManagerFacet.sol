// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../../dollar/UbiquityAlgorithmicDollarManager.sol";

contract ManagerFacet is UbiquityAlgorithmicDollarManager {

    address public creditTokenAddress; // uCR

    constructor(address addr) UbiquityAlgorithmicDollarManager(addr) {}

    function initialize(address _admin) external {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(UBQ_MINTER_ROLE, _admin);
        _setupRole(PAUSER_ROLE, _admin);
        _setupRole(COUPON_MANAGER_ROLE, _admin);
        _setupRole(BONDING_MANAGER_ROLE, _admin);
        _setupRole(INCENTIVE_MANAGER_ROLE, _admin);
        _setupRole(UBQ_TOKEN_MANAGER_ROLE, address(this));
    }

    function setuCRTokenAddress(address _uCRTokenAddress) external onlyAdmin {
        creditTokenAddress = _uCRTokenAddress;
    }
}