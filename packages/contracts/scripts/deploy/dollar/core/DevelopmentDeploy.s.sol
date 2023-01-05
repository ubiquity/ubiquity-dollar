// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "dollar/core/CreditNFT.sol";
import "dollar/core/CreditNFTManager.sol";
import "dollar/core/CreditNFTRedemption.sol";
import "dollar/core/DollarMintCalculator.sol";
import "dollar/core/DollarMintExcess.sol";
import "dollar/core/TWAPOracleDollar3pool.sol";
import "dollar/core/UbiquityCreditToken.sol";
import "dollar/core/UbiquityDollarManager.sol";
import "dollar/core/UbiquityDollarToken.sol";
import "dollar/core/UbiquityGovernanceToken.sol";

import "dollar/DirectGovernanceFarmer.sol";
import "dollar/Staking.sol";
import "dollar/StakingFormulas.sol";
import "dollar/StakingShare.sol";
import "dollar/UbiquityChef.sol";
import "dollar/UbiquityFormulas.sol";

import "forge-std/Script.sol";
import "../../shared/constants/migrateDataV1.sol";

contract DevelopmentDeploy is Script {

    function run() {
        address[] storage originals;
        address[] storage lpAmounts;
        address[] storage terms;
        uint256[] storage shareAmounts;
        uint256[] storage ids;
        address[] memory originals_;
        uint256[] memory lpAmounts_;
        uint256[] memory terms_;
        uint256[] memory shareAmounts_;
        uint256[] memory ids_;

        string memory uri;
        address admin = 0xefc0e701a824943b469a694ac564aa1eff7ab7dd;

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        UbiquityDollarManager manager = new UbiquityDollarManager(admin);
        manager.setTreasuryAddress(admin);

        UbiquityDollarToken dollar = new UbiquityDollarToken(address(manager));
        manager.setDollarTokenAddress(address(dollar));
        manager.deployStableSwapPool(
            0xB9fC157394Af804a3578134A6585C0dc9cc990d4,
            0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7,
            0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490,
            10,
            500000000);

        address metapool = manager.stableSwapMetaPoolAddress();
        TWAPOracleDollar3Pool twapOracle = new TWAPOracleDollar3Pool(
            metapool, 
            address(dollar), 
            0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490); 

        UbiquityGovernanceToken governance = new UbiquityGovernanceToken(address(manager));
        manager.setGovernanceTokenAddress(address(governance));

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

        CreditNFT creditNFT = new CreditNFT(address(manager));
        manager.setCreditNFTAddress(address(creditNFT));

        StakingFormulas sFormulas = new StakingFormulas;

        UbiquityFormulas uFormulas = new UbiquityFormulas;
        manager.setFormulasAddress(address(uFormulas));


        for(uint i = 0; i < migrateDataV1.users_.length; ++i){
            address original = migrateDataV1.users_[i];
            uint256 lpAmount = migrateDataV1.lpAmounts_[i];
            uint256 term = migrateDataV1.lockups[i];
            originals.push(original);
            lpAmounts.push(lpAmount);
            terms.push(term);
            shareAmounts.push(
                uFormulas.durationMultiply(lpAmount, term, 1e15));
            ids.push(i+1);
        }
        originals_ = originals;
        lpAmounts_ = lpAmounts;
        terms_ = terms;
        shareAmounts_ = shareAmounts;
        ids_ = ids;
        
        Staking staking = new Staking(address(manager), address(sFormulas), originals_, lpAmounts_, terms_);
        manager.setStakingContractAddress(address(staking));

        StakingShare share = new StakingShare(address(manager), uri);
        manager.setStakingShareAddress(address(share));

        
        UbiquityChef uChef = new UbiquityChef(originals_, shareAmounts_, ids_);
        manager.setMasterChefAddress(address(uChef));

        manager.grantRole(manager.UBQ_MINTER_ROLE(), address(uChef));
        manager.grantRole(manager.UBQ_MINTER_ROLE(), address(staking));
        manager.grantRole(manager.GOVERNANCE_TOKEN_MANAGER_ROLE(), admin);
        manager.grantRole(manager.CREDIT_NFT_MANAGER_ROLE(), address(creditNFTManager));
        manager.grantRole(manager.UBQ_MINTER_ROLE(), address(creditNFTManager));
        manager.grantRole(manager.UBQ_BURNER_ROLE(), address(creditNFTManager));

        vm.stopBroadcast();
    }
}