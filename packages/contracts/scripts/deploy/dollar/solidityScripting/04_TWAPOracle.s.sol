// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./03_UbiquityGovernanceToken.s.sol";

contract TWAPScript is GovernanceScript {
	function run() public virtual override {
		super.run();
		vm.startBroadcast(deployerPrivateKey);

		TWAPOracleDollar3pool twapOracle = new TWAPOracleDollar3pool( 
			metapool, 
			address(dollar), 
			address(USDCrvToken)
		); 

		manager.setTwapOracleAddress(address(twapOracle));
		
		vm.stopBroadcast();
	}


}
