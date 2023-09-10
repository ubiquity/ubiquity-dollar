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

import "../../src/dollar/interfaces/IDiamondCut.sol";
import "../../src/dollar/interfaces/IDiamondLoupe.sol";

contract UUPSTestHelper {
    CreditNft internal IUbiquityNft;
    StakingShare internal IStakingShareToken;
    ERC1155Ubiquity internal uStakingShareV1;
    UbiquityCreditToken internal uCreditToken;
    UbiquityDollarToken internal uDollarToken;
    UbiquityGovernanceToken internal uGovToken;
    ERC1155Ubiquity internal ubiquiStick;

    CreditNft internal creditNft;
    StakingShare internal stakingShare;
    UbiquityCreditToken internal creditToken;
    UbiquityDollarToken internal IDollar;
    UbiquityGovernanceToken internal governanceToken;
    ERC1155Ubiquity internal IUbiquiStick;
    ERC1155Ubiquity internal stakingShareV1;

    ERC1967Proxy internal proxyCreditNft;
    ERC1967Proxy internal proxyStakingShare;
    ERC1967Proxy internal proxyUCreditToken;
    ERC1967Proxy internal proxyUDollarToken;
    ERC1967Proxy internal proxyUGovToken;
    ERC1967Proxy internal proxyUbiquiStick;
    ERC1967Proxy internal proxyStakingShareV1;

    ManagerFacet internal iManager;
    AccessControlFacet internal IAccessControl;

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

        IUbiquityNft = new CreditNft();
        proxyCreditNft = new ERC1967Proxy(
            address(IUbiquityNft),
            managerPayload
        );
        creditNft = CreditNft(address(proxyCreditNft));

        IStakingShareToken = new StakingShare();
        proxyStakingShare = new ERC1967Proxy(
            address(IStakingShareToken),
            manAndUriPayload
        );
        stakingShare = StakingShare(address(proxyStakingShare));

        uCreditToken = new UbiquityCreditToken();
        proxyUCreditToken = new ERC1967Proxy(
            address(uCreditToken),
            managerPayload
        );
        creditToken = UbiquityCreditToken(address(proxyUCreditToken));

        uDollarToken = new UbiquityDollarToken();
        proxyUDollarToken = new ERC1967Proxy(
            address(uDollarToken),
            managerPayload
        );
        IDollar = UbiquityDollarToken(address(proxyUDollarToken));

        uGovToken = new UbiquityGovernanceToken();
        proxyUGovToken = new ERC1967Proxy(address(uGovToken), managerPayload);
        governanceToken = UbiquityGovernanceToken(address(proxyUGovToken));

        bytes memory ubq1155Payload = abi.encodeWithSignature(
            "__ERC1155Ubiquity_init(address,string)",
            manager,
            uri
        );

        ubiquiStick = new ERC1155Ubiquity();
        proxyUbiquiStick = new ERC1967Proxy(
            address(ubiquiStick),
            ubq1155Payload
        );
        IUbiquiStick = ERC1155Ubiquity(address(proxyUbiquiStick));

        uStakingShareV1 = new ERC1155Ubiquity();
        proxyStakingShareV1 = new ERC1967Proxy(
            address(uStakingShareV1),
            ubq1155Payload
        );
        stakingShareV1 = ERC1155Ubiquity(address(proxyStakingShareV1));

        iManager.setUbiquistickAddress(address(IUbiquiStick));
        iManager.setStakingShareAddress(address(stakingShare));
        iManager.setCreditTokenAddress(address(creditToken));
        iManager.setDollarTokenAddress(address(IDollar));
        iManager.setGovernanceTokenAddress(address(governanceToken));
        iManager.setCreditNftAddress(address(creditNft));
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
