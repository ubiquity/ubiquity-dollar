// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./06_Formulas.s.sol";

contract StakingScript is FormulaScript {
	function run() public virtual override {
		super.run();
		vm.startBroadcast(deployerPrivateKey);

		for(uint256 i = 0; i < users.length; ++i){
            uint256 lpAmount = lpAmounts[i];
            uint256 term = terms[i];
            shareAmounts.push(
                uFormulas.durationMultiply(lpAmount, term, 1e15)
			);
            ids.push(i+1);
        }
        address[] memory users_ = users;
        uint256[] memory lpAmounts_ = lpAmounts;
        uint256[] memory terms_ = terms;
        uint256[] memory shareAmounts_ = shareAmounts;
        uint256[] memory ids_ = ids;

		Staking staking = new Staking(manager, sFormulas, users_, lpAmounts_, terms_);
        manager.setStakingContractAddress(address(staking));

        StakingShare share = new StakingShare(manager, uri);
        manager.setStakingShareAddress(address(share));

        
        UbiquityChef uChef = new UbiquityChef(manager, users_, shareAmounts_, ids_);
        manager.setMasterChefAddress(address(uChef));

		manager.grantRole(manager.GOVERNANCE_TOKEN_MINTER_ROLE(), address(uChef));
        manager.grantRole(manager.GOVERNANCE_TOKEN_MINTER_ROLE(), address(staking));
		
		vm.stopBroadcast();
	}
}
