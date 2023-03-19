// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./02_UbiquityDollarToken.s.sol";

contract GovernanceScript is DollarScript {
    UbiquityGovernanceToken governance;

    function run() public virtual override {
        super.run();
        vm.startBroadcast(deployerPrivateKey);

        governance = new UbiquityGovernanceToken(address(diamond));

        IManager.setGovernanceTokenAddress(address(governance));
        // grant diamond token admin rights
        IAccessCtrl.grantRole(GOVERNANCE_TOKEN_MINTER_ROLE, address(diamond));
        IAccessCtrl.grantRole(GOVERNANCE_TOKEN_BURNER_ROLE, address(diamond));

        vm.stopBroadcast();
    }
}
