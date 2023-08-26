// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {UupsProxy} from "./UupsProxy.sol";
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

contract UupsTestHelper {
    CreditNft public creditNft;
    StakingShare public stakingShare;
    ERC1155Ubiquity public uStakingShareV1;
    UbiquityCreditToken public uCreditToken;
    UbiquityDollarToken public uDollarToken;
    UbiquityGovernanceToken public uGovToken;
    ERC1155Ubiquity public ubiquiStick;

    CreditNft public IUbiquityNft;
    StakingShare public IStakingShareToken;
    UbiquityCreditToken public creditToken;
    UbiquityDollarToken public IDollar;
    UbiquityGovernanceToken public IGovToken;
    ERC1155Ubiquity public IUbiquiStick;
    ERC1155Ubiquity public stakingShareV1;

    UupsProxy public proxyCreditNft;
    UupsProxy public proxyStakingShare;
    UupsProxy public proxyUCreditToken;
    UupsProxy public proxyUDollarToken;
    UupsProxy public proxyUGovToken;
    UupsProxy public proxyUbiquiStick;
    UupsProxy public proxyStakingShareV1;

    ManagerFacet iManager;
    AccessControlFacet IAccessControl;

    function __setupUUPS(address manager) public {
        iManager = ManagerFacet(manager);
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

        creditNft = new CreditNft();
        proxyCreditNft = new UupsProxy(address(creditNft), managerPayload);
        IUbiquityNft = CreditNft(address(proxyCreditNft));

        stakingShare = new StakingShare();
        proxyStakingShare = new UupsProxy(
            address(stakingShare),
            manAndUriPayload
        );
        IStakingShareToken = StakingShare(address(proxyStakingShare));

        uCreditToken = new UbiquityCreditToken();
        proxyUCreditToken = new UupsProxy(
            address(uCreditToken),
            managerPayload
        );
        creditToken = UbiquityCreditToken(address(proxyUCreditToken));

        uDollarToken = new UbiquityDollarToken();
        proxyUDollarToken = new UupsProxy(
            address(uDollarToken),
            managerPayload
        );
        IDollar = UbiquityDollarToken(address(proxyUDollarToken));

        uGovToken = new UbiquityGovernanceToken();
        proxyUGovToken = new UupsProxy(address(uGovToken), managerPayload);
        IGovToken = UbiquityGovernanceToken(address(proxyUGovToken));

        bytes memory ubq1155Payload = abi.encodeWithSignature(
            "__ERC1155Ubiquity_init(address,string)",
            manager,
            uri
        );

        ubiquiStick = new ERC1155Ubiquity();
        proxyUbiquiStick = new UupsProxy(address(ubiquiStick), ubq1155Payload);
        IUbiquiStick = ERC1155Ubiquity(address(proxyUbiquiStick));

        uStakingShareV1 = new ERC1155Ubiquity();
        proxyStakingShareV1 = new UupsProxy(
            address(uStakingShareV1),
            ubq1155Payload
        );
        stakingShareV1 = ERC1155Ubiquity(address(proxyStakingShareV1));

        iManager.setUbiquistickAddress(address(IUbiquiStick));
        iManager.setStakingShareAddress(address(IStakingShareToken));
        iManager.setCreditTokenAddress(address(creditToken));
        iManager.setDollarTokenAddress(address(IDollar));
        iManager.setGovernanceTokenAddress(address(IGovToken));
        iManager.setCreditNftAddress(address(IUbiquityNft));
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
