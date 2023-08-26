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
import {BondingShare} from "../../src/dollar/mocks/MockShareV1.sol";
import "../../src/dollar/libraries/Constants.sol";

contract UupsTestHelper {
    CreditNft public creditNft;
    StakingShare public stakingShare;
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
    BondingShare public stakingShareV1;

    UupsProxy public proxyCreditNft;
    UupsProxy public proxyStakingShare;
    UupsProxy public proxyUCreditToken;
    UupsProxy public proxyUDollarToken;
    UupsProxy public proxyUGovToken;
    UupsProxy public proxyUbiquiStick;

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

        ubiquiStick = new ERC1155Ubiquity();
        proxyUbiquiStick = new UupsProxy(address(ubiquiStick), managerPayload);
        IUbiquiStick = ERC1155Ubiquity(address(proxyUbiquiStick));

        iManager.setUbiquistickAddress(address(IUbiquiStick));
        iManager.setStakingShareAddress(address(IStakingShareToken));
        iManager.setCreditTokenAddress(address(creditToken));
        iManager.setDollarTokenAddress(address(IDollar));
        iManager.setGovernanceTokenAddress(address(IGovToken));
        iManager.setCreditNftAddress(address(IUbiquityNft));

        IDollar = UbiquityDollarToken(iManager.dollarTokenAddress());
        IGovToken = UbiquityGovernanceToken(iManager.governanceTokenAddress());
        IStakingShareToken = StakingShare(iManager.stakingShareAddress());
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
