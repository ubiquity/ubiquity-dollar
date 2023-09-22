// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UbiquityGovernanceToken} from "../../src/dollar/core/UbiquityGovernanceToken.sol";
import {UbiquityDollarToken} from "../../src/dollar/core/UbiquityDollarToken.sol";
import {UbiquityCreditToken} from "../../src/dollar/core/UbiquityCreditToken.sol";
import {StakingShare} from "../../src/dollar/core/StakingShare.sol";
import {CreditNft} from "../../src/dollar/core/CreditNft.sol";
import {ManagerFacet} from "../../src/dollar/facets/ManagerFacet.sol";
import {AccessControlFacet} from "../../src/dollar/facets/AccessControlFacet.sol";
import {ERC1155Ubiquity} from "../../src/dollar/core/ERC1155Ubiquity.sol";
import "../../src/dollar/libraries/Constants.sol";
import "forge-std/Test.sol";

contract UUPSTestHelper {
    CreditNft creditNft;
    StakingShare stakingShare;
    UbiquityCreditToken creditToken;
    UbiquityDollarToken IDollar;
    UbiquityGovernanceToken governanceToken;
    ERC1155Ubiquity ubiquiStick;

    ERC1967Proxy proxyCreditNft;
    ERC1967Proxy proxyStakingShare;
    ERC1967Proxy proxyCreditToken;
    ERC1967Proxy proxyDollarToken;
    ERC1967Proxy proxyGovernanceToken;
    ERC1967Proxy proxyUbiquiStick;

    AccessControlFacet IAccessControl;

    function __setupUUPS(address manager) public {
        ManagerFacet managerFacet = ManagerFacet(manager);
        IAccessControl = AccessControlFacet(manager);
        string
            memory uri = "https://bafybeifibz4fhk4yag5reupmgh5cdbm2oladke4zfd7ldyw7avgipocpmy.ipfs.infura-ipfs.io/";

        bytes memory managerPayload = abi.encodeWithSignature(
            "initialize(address)",
            manager
        );
        bytes memory manAndUriPayload = abi.encodeWithSignature(
            "initialize(address,string)",
            manager,
            uri
        );

        proxyCreditNft = new ERC1967Proxy(
            address(new CreditNft()),
            managerPayload
        );
        creditNft = CreditNft(address(proxyCreditNft));

        proxyStakingShare = new ERC1967Proxy(
            address(new StakingShare()),
            manAndUriPayload
        );
        stakingShare = StakingShare(address(proxyStakingShare));

        proxyCreditToken = new ERC1967Proxy(
            address(new UbiquityCreditToken()),
            managerPayload
        );
        creditToken = UbiquityCreditToken(address(proxyCreditToken));

        proxyDollarToken = new ERC1967Proxy(
            address(new UbiquityDollarToken()),
            managerPayload
        );
        IDollar = UbiquityDollarToken(address(proxyDollarToken));

        proxyGovernanceToken = new ERC1967Proxy(
            address(new UbiquityGovernanceToken()),
            managerPayload
        );
        governanceToken = UbiquityGovernanceToken(
            address(proxyGovernanceToken)
        );

        bytes memory ubq1155Payload = abi.encodeWithSignature(
            "__ERC1155Ubiquity_init(address,string)",
            manager,
            uri
        );

        // TODO: move from UUPSTestHelper
        proxyUbiquiStick = new ERC1967Proxy(
            address(new ERC1155Ubiquity()),
            ubq1155Payload
        );
        ubiquiStick = ERC1155Ubiquity(address(proxyUbiquiStick));

        managerFacet.setUbiquistickAddress(address(ubiquiStick));
        managerFacet.setStakingShareAddress(address(stakingShare));
        managerFacet.setCreditTokenAddress(address(creditToken));
        managerFacet.setDollarTokenAddress(address(IDollar));
        managerFacet.setGovernanceTokenAddress(address(governanceToken));
        managerFacet.setCreditNftAddress(address(creditNft));
        // grant diamond dollar minting and burning rights
        IAccessControl.grantRole(DOLLAR_TOKEN_MINTER_ROLE, address(manager));
        IAccessControl.grantRole(DOLLAR_TOKEN_BURNER_ROLE, address(manager));
        // grand diamond Credit token minting and burning rights
        IAccessControl.grantRole(CREDIT_TOKEN_MINTER_ROLE, address(manager));
        IAccessControl.grantRole(CREDIT_TOKEN_BURNER_ROLE, address(manager));
        // grant diamond token admin rights
        IAccessControl.grantRole(
            GOVERNANCE_TOKEN_MANAGER_ROLE,
            address(manager)
        );
        // grant diamond token minter rights
        IAccessControl.grantRole(STAKING_SHARE_MINTER_ROLE, address(manager));
    }
}
