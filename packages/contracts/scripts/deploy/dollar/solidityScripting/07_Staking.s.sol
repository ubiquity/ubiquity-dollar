// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./06_Formulas.s.sol";

contract StakingScript is FormulaScript {
	function run() public virtual override {
		super.run();
		uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
		vm.startBroadcast(deployerPrivateKey);

		for(uint i = 0; i < users_.length; ++i){
            address original = users_[i];
            uint256 lpAmount = amounts_[i];
            uint256 term = lockups_[i];
            originals.push(original);
            lpAmounts.push(lpAmount);
            terms.push(term);
            shareAmounts.push(
                uFormulas.durationMultiply(lpAmount, term, 1e15)
			);
            ids.push(i+1);
        }
        address[] memory originals_ = originals;
        uint256[] memory lpAmounts_ = lpAmounts;
        uint256[] memory terms_ = terms;
        uint256[] memory shareAmounts_ = shareAmounts;
        uint256[] memory ids_ = ids;

		Staking staking = new Staking(manager, sFormulas, originals_, lpAmounts_, terms_);
        manager.setStakingContractAddress(address(staking));

        StakingShare share = new StakingShare(manager, uri);
        manager.setStakingShareAddress(address(share));

        
        UbiquityChef uChef = new UbiquityChef(manager, originals_, shareAmounts_, ids_);
        manager.setMasterChefAddress(address(uChef));

		manager.grantRole(manager.GOVERNANCE_TOKEN_MINTER_ROLE(), address(uChef));
        manager.grantRole(manager.GOVERNANCE_TOKEN_MINTER_ROLE(), address(staking));
		
		vm.stopBroadcast();
	}


}
