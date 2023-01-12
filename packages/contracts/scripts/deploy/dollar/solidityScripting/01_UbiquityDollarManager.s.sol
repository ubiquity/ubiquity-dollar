// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./00_Constants.sol";

contract ManagerScript is Constants {
    UbiquityDollarManager manager; 
    function run() public virtual {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        manager = new UbiquityDollarManager(admin);
        manager.setTreasuryAddress(admin);
        manager.grantRole(manager.GOVERNANCE_TOKEN_MANAGER_ROLE(), admin);
        IERC20(USDCrvToken).transfer(address(manager), 10000e18);

        vm.stopBroadcast();
    }
}