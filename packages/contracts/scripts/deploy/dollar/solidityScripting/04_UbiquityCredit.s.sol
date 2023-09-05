// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./03_UbiquityGovernanceToken.s.sol";
import {UbiquityCreditToken} from "../../../../src/dollar/core/UbiquityCreditToken.sol";
import {CreditNft} from "../../../../src/dollar/core/CreditNft.sol";

contract CreditScript is GovernanceScript {
    UbiquityCreditToken public creditToken;
    CreditNft public creditNft;

    ERC1967Proxy public proxyCreditToken;
    ERC1967Proxy public proxyCreditNft;

    function run() public virtual override {
        super.run();
        vm.startBroadcast(deployerPrivateKey);
        bytes memory managerPayload = abi.encodeWithSignature(
            "initialize(address)",
            address(diamond)
        );

        proxyCreditToken = new ERC1967Proxy(
            address(new UbiquityCreditToken()),
            managerPayload
        );
        creditToken = UbiquityCreditToken(address(proxyCreditToken));

        IManager.setCreditTokenAddress(address(creditToken));

        IAccessControl.grantRole(CREDIT_TOKEN_MINTER_ROLE, address(diamond));
        IAccessControl.grantRole(CREDIT_TOKEN_BURNER_ROLE, address(diamond));
        IAccessControl.grantRole(CREDIT_NFT_MANAGER_ROLE, address(diamond));

        proxyCreditNft = new ERC1967Proxy(
            address(new CreditNft()),
            managerPayload
        );
        creditNft = CreditNft(address(proxyCreditNft));

        IManager.setCreditNftAddress(address(creditNft));

        vm.stopBroadcast();
    }
}
