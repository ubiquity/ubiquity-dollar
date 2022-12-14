// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IERC173} from "../interfaces/IERC173.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import {Modifiers, GOVERNANCE_TOKEN_MINTER_ROLE, PAUSER_ROLE, CREDIT_NFT_MANAGER_ROLE, STAKING_MANAGER_ROLE, INCENTIVE_MANAGER_ROLE, GOVERNANCE_TOKEN_MANAGER_ROLE} from "../libraries/LibAppStorage.sol";
import {LibAccessControl} from "../libraries/LibAccessControl.sol";
import {LibTWAPOracle} from "../libraries/LibTWAPOracle.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init function if you need to.

contract DiamondInit is Modifiers {
    struct Args {
        address admin;
        // twap oracle
        address pool;
        address curve3CRVToken1;
    }

    // You can add parameters to this function in order to pass in
    // data to set your own state variables
    function init(Args memory _args) external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        LibAccessControl._grantRole(
            LibAccessControl.DEFAULT_ADMIN_ROLE,
            _args.admin
        );
        LibAccessControl._grantRole(GOVERNANCE_TOKEN_MINTER_ROLE, _args.admin);
        LibAccessControl._grantRole(PAUSER_ROLE, _args.admin);
        LibAccessControl._grantRole(CREDIT_NFT_MANAGER_ROLE, _args.admin);
        LibAccessControl._grantRole(STAKING_MANAGER_ROLE, _args.admin);
        LibAccessControl._grantRole(INCENTIVE_MANAGER_ROLE, _args.admin);
        LibAccessControl._grantRole(GOVERNANCE_TOKEN_MANAGER_ROLE, _args.admin);

        // twap oracle inital configuration

        LibTWAPOracle._setPool(_args.pool, _args.curve3CRVToken1);

        // add your own state variables
        // EIP-2535 specifies that the `diamondCut` function takes two optional
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface
    }
}
