// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./UbiquityCredit.s.sol";

contract FormulaScript is CreditScript {

	StakingFormulas sFormulas;
	UbiquityFormulas uFormulas;

	function run() public virtual override {
		super.run();
		uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
		vm.startBroadcast(deployerPrivateKey);

		sFormulas = new StakingFormulas();

        uFormulas = new UbiquityFormulas();
        manager.setFormulasAddress(address(uFormulas));
		
		vm.stopBroadcast();
	}


}
