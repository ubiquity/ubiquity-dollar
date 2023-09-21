// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./02_UbiquityDollarToken.s.sol";

contract GovernanceScript is DollarScript {
    UbiquityGovernanceToken public governanceToken;
    ERC1967Proxy public proxyGovernanceToken;

    function run() public virtual override {
        super.run();
        vm.startBroadcast(deployerPrivateKey);

        bytes memory managerPayload = abi.encodeWithSignature(
            "initialize(address)",
            address(diamond)
        );

        proxyGovernanceToken = new ERC1967Proxy(
            address(new UbiquityGovernanceToken()),
            managerPayload
        );
        governanceToken = UbiquityGovernanceToken(
            address(proxyGovernanceToken)
        );

        IManager.setGovernanceTokenAddress(address(governanceToken));
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
