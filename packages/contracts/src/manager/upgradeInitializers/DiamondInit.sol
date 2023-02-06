// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IERC173} from "../interfaces/IERC173.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import {Modifiers, GOVERNANCE_TOKEN_MINTER_ROLE, PAUSER_ROLE, CREDIT_NFT_MANAGER_ROLE, STAKING_MANAGER_ROLE, INCENTIVE_MANAGER_ROLE, GOVERNANCE_TOKEN_MANAGER_ROLE} from "../libraries/LibAppStorage.sol";
import {AccessControlStorage} from "../libraries/AccessControlStorage.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init function if you need to.

contract DiamondInit is Modifiers {
    // You can add parameters to this function in order to pass in
    // data to set your own state variables
    function init(address _admin) external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        _grantRole(AccessControlStorage.DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(GOVERNANCE_TOKEN_MINTER_ROLE, _admin);
        _grantRole(PAUSER_ROLE, _admin);
        _grantRole(CREDIT_NFT_MANAGER_ROLE, _admin);
        _grantRole(STAKING_MANAGER_ROLE, _admin);
        _grantRole(INCENTIVE_MANAGER_ROLE, _admin);
        _grantRole(GOVERNANCE_TOKEN_MANAGER_ROLE, address(this));

        // add your own state variables
        // EIP-2535 specifies that the `diamondCut` function takes two optional
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface
    }
}
