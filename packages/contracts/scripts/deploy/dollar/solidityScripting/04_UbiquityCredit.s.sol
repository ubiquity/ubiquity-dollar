// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./03_UbiquityGovernanceToken.s.sol";
import {UbiquityCreditToken} from "../../../../src/dollar/core/UbiquityCreditToken.sol";
import {CreditNft} from "../../../../src/dollar/core/CreditNft.sol";

contract CreditScript is GovernanceScript {
    UbiquityCreditToken public uCreditToken;
    UbiquityCreditToken public creditToken;
    UupsProxy public proxyUCreditToken;

    CreditNft public creditNft;
    CreditNft public IUbiquityNft;
    UupsProxy public proxyCreditNft;

    function run() public virtual override {
        super.run();
        vm.startBroadcast(deployerPrivateKey);
        bytes memory managerPayload = abi.encodeWithSignature(
            "initialize(address)",
            address(diamond)
        );
        uCreditToken = new UbiquityCreditToken();
        proxyUCreditToken = new UupsProxy(
            address(uCreditToken),
            managerPayload
        );
        creditToken = UbiquityCreditToken(address(proxyUCreditToken));

        IManager.setCreditTokenAddress(address(creditToken));

        IAccessControl.grantRole(CREDIT_TOKEN_MINTER_ROLE, address(diamond));
        IAccessControl.grantRole(CREDIT_TOKEN_BURNER_ROLE, address(diamond));
        IAccessControl.grantRole(CREDIT_NFT_MANAGER_ROLE, address(diamond));

        creditNft = new CreditNft();
        proxyCreditNft = new UupsProxy(address(creditNft), managerPayload);
        IUbiquityNft = CreditNft(address(proxyCreditNft));

        IManager.setCreditNftAddress(address(IUbiquityNft));

        vm.stopBroadcast();
    }
}
