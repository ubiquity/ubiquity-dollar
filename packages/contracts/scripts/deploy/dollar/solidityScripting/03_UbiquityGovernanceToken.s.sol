// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./02_UbiquityDollarToken.s.sol";

contract GovernanceScript is DollarScript {
    UbiquityGovernanceToken governance;

    function run() public virtual override {
        super.run();
        vm.startBroadcast(deployerPrivateKey);

        governance = new UbiquityGovernanceToken(manager);
        manager.setGovernanceTokenAddress(address(governance));

        vm.stopBroadcast();
    }
}
