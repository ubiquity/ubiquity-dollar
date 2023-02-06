// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./05_UbiquityCredit.s.sol";

contract FormulaScript is CreditScript {
    StakingFormulas sFormulas;
    UbiquityFormulas uFormulas;

    function run() public virtual override {
        super.run();
        vm.startBroadcast(deployerPrivateKey);

        sFormulas = new StakingFormulas();

        uFormulas = new UbiquityFormulas();
        manager.setFormulasAddress(address(uFormulas));

        vm.stopBroadcast();
    }
}
