// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ubiquity-governance-token-s.sol";
import {UbiquityCreditToken} from "../../../../src/dollar/core/ubiquity-credit-token.sol";
import {CreditNft} from "../../../../src/dollar/core/credit-nft.sol";

contract CreditScript is GovernanceScript {
    function run() public virtual override {
        super.run();
        vm.startBroadcast(deployerPrivateKey);

        UbiquityCreditToken credit = new UbiquityCreditToken(address(diamond));
        IManager.setCreditTokenAddress(address(credit));

        IAccessCtrl.grantRole(CREDIT_TOKEN_MINTER_ROLE, address(diamond));
        IAccessCtrl.grantRole(CREDIT_TOKEN_BURNER_ROLE, address(diamond));
        IAccessCtrl.grantRole(CREDIT_NFT_MANAGER_ROLE, address(diamond));

        CreditNft creditNft = new CreditNft(address(diamond));
        IManager.setCreditNftAddress(address(creditNft));

        vm.stopBroadcast();
    }
}
