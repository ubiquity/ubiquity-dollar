// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UbiquityGovernanceToken} from "../../src/dollar/core/UbiquityGovernanceToken.sol";
import {UbiquityDollarToken} from "../../src/dollar/core/UbiquityDollarToken.sol";
import {UbiquityCreditToken} from "../../src/dollar/core/UbiquityCreditToken.sol";
import {StakingShare} from "../../src/dollar/core/StakingShare.sol";
import {CreditNft} from "../../src/dollar/core/CreditNft.sol";
import {ManagerFacet} from "../../src/dollar/facets/ManagerFacet.sol";
import "../../src/dollar/libraries/Constants.sol";
import "forge-std/Test.sol";

/**
 * Initializes core contracts with UUPS upgradeability:
 * - UbiquityDollarToken
 * - UbiquityCreditToken
 * - UbiquityGovernanceToken
 * - CreditNft
 * - StakingShare
 */
contract UUPSTestHelper {
    // core contracts pointing to proxies
    CreditNft creditNft;
    StakingShare stakingShare;
    UbiquityCreditToken creditToken;
    UbiquityDollarToken dollarToken;
    UbiquityGovernanceToken governanceToken;

    // proxies for core contracts
    ERC1967Proxy proxyCreditNft;
    ERC1967Proxy proxyStakingShare;
    ERC1967Proxy proxyCreditToken;
    ERC1967Proxy proxyDollarToken;
    ERC1967Proxy proxyGovernanceToken;
    ERC1967Proxy proxyUbiquiStick;

    /**
     * Initializes core contracts with UUPS upgradeability
     */
    function __setupUUPS(address diamond) public {
        bytes memory initData;
        string
            memory uri = "https://bafybeifibz4fhk4yag5reupmgh5cdbm2oladke4zfd7ldyw7avgipocpmy.ipfs.infura-ipfs.io/";

        // deploy CreditNft
        initData = abi.encodeWithSignature("initialize(address)", diamond);
        proxyCreditNft = new ERC1967Proxy(address(new CreditNft()), initData);
        creditNft = CreditNft(address(proxyCreditNft));

        // deploy StakingShare
        initData = abi.encodeWithSignature(
            "initialize(address,string)",
            diamond,
            uri
        );
        proxyStakingShare = new ERC1967Proxy(
            address(new StakingShare()),
            initData
        );
        stakingShare = StakingShare(address(proxyStakingShare));

        // deploy UbiquityCreditToken
        initData = abi.encodeWithSignature("initialize(address)", diamond);
        proxyCreditToken = new ERC1967Proxy(
            address(new UbiquityCreditToken()),
            initData
        );
        creditToken = UbiquityCreditToken(address(proxyCreditToken));

        // deploy UbiquityDollarToken
        initData = abi.encodeWithSignature("initialize(address)", diamond);
        proxyDollarToken = new ERC1967Proxy(
            address(new UbiquityDollarToken()),
            initData
        );
        dollarToken = UbiquityDollarToken(address(proxyDollarToken));

        // deploy UbiquityGovernanceToken
        initData = abi.encodeWithSignature("initialize(address)", diamond);
        proxyGovernanceToken = new ERC1967Proxy(
            address(new UbiquityGovernanceToken()),
            initData
        );
        governanceToken = UbiquityGovernanceToken(
            address(proxyGovernanceToken)
        );

        // set addresses of the newly deployed contracts in the Diamond
        ManagerFacet managerFacet = ManagerFacet(diamond);
        managerFacet.setStakingShareAddress(address(stakingShare));
        managerFacet.setCreditTokenAddress(address(creditToken));
        managerFacet.setDollarTokenAddress(address(dollarToken));
        managerFacet.setGovernanceTokenAddress(address(governanceToken));
        managerFacet.setCreditNftAddress(address(creditNft));
    }
}
