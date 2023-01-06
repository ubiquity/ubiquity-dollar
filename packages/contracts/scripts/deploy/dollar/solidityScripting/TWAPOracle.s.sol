// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./UbiquityGovernanceToken.s.sol";

contract TWAPScript is GovernanceScript {
	function run() public virtual override {
		super.run();
		uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
		vm.startBroadcast(deployerPrivateKey);

		MockTWAPOracleDollar3pool twapOracle = new MockTWAPOracleDollar3pool( 
			metapool, 
			address(dollar), 
			address(USDCrvToken),
			1e18,
			1e18
		); 

		manager.setTwapOracleAddress(address(twapOracle));
		
		vm.stopBroadcast();
	}


}
