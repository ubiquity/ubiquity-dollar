// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./02_UbiquityDollarToken.s.sol";

contract GovernanceScript is DollarScript {
	function run() public virtual override {
		super.run();
		uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
		vm.startBroadcast(deployerPrivateKey);

		UbiquityGovernanceToken governance = new UbiquityGovernanceToken(address(manager));
		manager.setGovernanceTokenAddress(address(governance));
		
		vm.stopBroadcast();
	}


}
