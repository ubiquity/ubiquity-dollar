// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./04_TWAPOracle.s.sol";

contract CreditScript is TWAPScript {
	function run() public virtual override {
		super.run();
        vm.startBroadcast(deployerPrivateKey);

        UbiquityCreditToken credit = new UbiquityCreditToken(manager);
        manager.setCreditTokenAddress(address(credit));

        DollarMintCalculator mintCalculator = new DollarMintCalculator(manager);
        manager.setDollarMintCalculatorAddress(address(mintCalculator));

        DollarMintExcess excess = new DollarMintExcess(manager);

        CreditRedemptionCalculator creditCalculator = new CreditRedemptionCalculator(manager);
        manager.setCreditCalculatorAddress(address(creditCalculator));
        
        CreditNFTRedemptionCalculator nftCalculator = new CreditNFTRedemptionCalculator(manager);
        manager.setCreditNFTCalculatorAddress(address(nftCalculator));

        CreditNFTManager nftManager = new CreditNFTManager(manager, 10);
		manager.grantRole(manager.CREDIT_NFT_MANAGER_ROLE(), address(nftManager));
        manager.grantRole(manager.GOVERNANCE_TOKEN_MINTER_ROLE(), address(nftManager));
        manager.grantRole(manager.GOVERNANCE_TOKEN_BURNER_ROLE(), address(nftManager));

        CreditNFT creditNFT = new CreditNFT(manager);
        manager.setCreditNFTAddress(address(creditNFT));

        vm.stopBroadcast();
	}
}
