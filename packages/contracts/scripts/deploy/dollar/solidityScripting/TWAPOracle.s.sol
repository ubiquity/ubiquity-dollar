// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./UbiquityGovernanceToken.s.sol";

contract TWAPScript is GovernanceScript {
	function run() public virtual override {
		super.run();
		uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
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
