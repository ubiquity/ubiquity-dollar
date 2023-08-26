// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./02_UbiquityDollarToken.s.sol";

contract GovernanceScript is DollarScript {
    UbiquityGovernanceToken public uGovToken;
    UbiquityGovernanceToken public governance;
    UupsProxy public proxyUGovToken;

    function run() public virtual override {
        super.run();
        vm.startBroadcast(deployerPrivateKey);

        bytes memory managerPayload = abi.encodeWithSignature(
            "initialize(address)",
            address(diamond)
        );

        uGovToken = new UbiquityGovernanceToken();
        proxyUGovToken = new UupsProxy(address(uGovToken), managerPayload);
        governance = UbiquityGovernanceToken(address(proxyUGovToken));

        IManager.setGovernanceTokenAddress(address(governance));
        // grant diamond token admin rights
        IAccessControl.grantRole(
            GOVERNANCE_TOKEN_MINTER_ROLE,
            address(diamond)
        );
        IAccessControl.grantRole(
            GOVERNANCE_TOKEN_BURNER_ROLE,
            address(diamond)
        );

        vm.stopBroadcast();
    }
}
