// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./TWAPOracle.s.sol";

contract CreditScript is TWAPScript {
	function run() public virtual override {
		super.run();
		uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        UbiquityCreditToken credit = new UbiquityCreditToken(address(manager));
        manager.setCreditTokenAddress(address(credit));

        DollarMintCalculator mintCalculator = new DollarMintCalculator(address(manager));
        manager.setDollarMintCalculatorAddress(address(mintCalculator));

        DollarMintExcess excess = new DollarMintExcess(address(manager));

        CreditRedemptionCalculator creditCalculator = new CreditRedemptionCalculator(address(manager));
        manager.setCreditCalculatorAddress(address(creditCalculator));
        
        CreditNFTRedemptionCalculator nftCalculator = new CreditNFTRedemptionCalculator(address(manager));
        manager.setCreditNFTCalculatorAddress(address(nftCalculator));

        CreditNFTManager nftManager = new CreditNFTManager(address(manager), 10);
		manager.grantRole(manager.CREDIT_NFT_MANAGER_ROLE(), address(nftManager));
        manager.grantRole(manager.UBQ_MINTER_ROLE(), address(nftManager));
        manager.grantRole(manager.UBQ_BURNER_ROLE(), address(nftManager));

        CreditNFT creditNFT = new CreditNFT(address(manager));
        manager.setCreditNFTAddress(address(creditNFT));

        vm.stopBroadcast();
	}


}
