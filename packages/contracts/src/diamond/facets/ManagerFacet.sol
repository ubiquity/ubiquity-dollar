// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {
    AppStorage,
    Modifiers,
    UBQ_MINTER_ROLE,
    PAUSER_ROLE,
    COUPON_MANAGER_ROLE,
    BONDING_MANAGER_ROLE,
    INCENTIVE_MANAGER_ROLE,
    UBQ_TOKEN_MANAGER_ROLE    
} from "../libraries/LibAppStorage.sol";
import { AccessControlStorage } from "solidstate/contracts/access/access_control/AccessControlStorage.sol";

contract ManagerFacet is Modifiers {

    function initialize(address _admin) external onlyOwner {
        _grantRole(AccessControlStorage.DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(UBQ_MINTER_ROLE, _admin);
        _grantRole(PAUSER_ROLE, _admin);
        _grantRole(COUPON_MANAGER_ROLE, _admin);
        _grantRole(BONDING_MANAGER_ROLE, _admin);
        _grantRole(INCENTIVE_MANAGER_ROLE, _admin);
        _grantRole(UBQ_TOKEN_MANAGER_ROLE, address(this));
    }

    function getDollarTokenAddress() external view returns (address) {
        return s.dollarTokenAddress;
    }

    function setDollarTokenAddress(address _dollarTokenAddress)
        external
        onlyAdmin
    {
        s.dollarTokenAddress = _dollarTokenAddress;
    }

    function getCreditTokenAddress() external view returns (address) {
        return s.creditTokenAddress;
    }

    function setCreditTokenAddress(address _creditTokenAddress)
        external
        onlyAdmin
    {
        s.creditTokenAddress = _creditTokenAddress;
    }

    function getExcessDollarsDistributor(address _debtCouponManagerAddress)
        external
        view
        returns (address)
    {
        return s._excessDollarDistributors[_debtCouponManagerAddress];
    }

    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {}
}