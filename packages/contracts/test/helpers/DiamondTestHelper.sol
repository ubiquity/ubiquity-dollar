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

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../../src/dollar/interfaces/IDiamondCut.sol";
import "../../src/dollar/interfaces/IDiamondLoupe.sol";

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

contract DiamondTestHelper is IDiamondCut, IDiamondLoupe, UupsTestHelper, Test {
    uint256 private seed;

    modifier prankAs(address caller) {
        vm.startPrank(caller);
        _;
        vm.stopPrank();
    }

    function generateAddress(
        string memory _name,
        bool _isContract
    ) internal returns (address) {
        return generateAddress(_name, _isContract, 0);
    }

    function generateAddress(
        string memory _name,
        bool _isContract,
        uint256 _eth
    ) internal returns (address newAddress_) {
        seed++;
        newAddress_ = vm.addr(seed);

        vm.label(newAddress_, _name);

        if (_isContract) {
            vm.etch(newAddress_, "Generated Contract Address");
        }

        vm.deal(newAddress_, _eth);

        return newAddress_;
    }

    // remove index from bytes4[] array
    function removeElement(
        uint256 index,
        bytes4[] memory array
    ) public pure returns (bytes4[] memory) {
        bytes4[] memory newArray = new bytes4[](array.length - 1);
        uint256 j = 0;
        for (uint256 i = 0; i < array.length; i++) {
            if (i != index) {
                newArray[j] = array[i];
                j += 1;
            }
        }
        return newArray;
    }

    // remove value from bytes4[] array
    function removeElement(
        bytes4 el,
        bytes4[] memory array
    ) public pure returns (bytes4[] memory) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == el) {
                return removeElement(i, array);
            }
        }
        return array;
    }

    function containsElement(
        bytes4[] memory array,
        bytes4 el
    ) public pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == el) {
                return true;
            }
        }
        return false;
    }

    function containsElement(
        address[] memory array,
        address el
    ) public pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == el) {
                return true;
            }
        }
        return false;
    }

    function sameMembers(
        bytes4[] memory array1,
        bytes4[] memory array2
    ) public pure returns (bool) {
        if (array1.length != array2.length) {
            return false;
        }
        for (uint256 i = 0; i < array1.length; i++) {
            if (containsElement(array1, array2[i])) {
                return true;
            }
        }
        return false;
    }

    function getAllSelectors(
        address diamondAddress
    ) public view returns (bytes4[] memory) {
        Facet[] memory facetList = IDiamondLoupe(diamondAddress).facets();

        uint256 len = 0;
        for (uint256 i = 0; i < facetList.length; i++) {
            len += facetList[i].functionSelectors.length;
        }

        uint256 pos = 0;
        bytes4[] memory selectors = new bytes4[](len);
        for (uint256 i = 0; i < facetList.length; i++) {
            for (
                uint256 j = 0;
                j < facetList[i].functionSelectors.length;
                j++
            ) {
                selectors[pos] = facetList[i].functionSelectors[j];
                pos += 1;
            }
        }
        return selectors;
    }

    function compareStrings(
        string memory a,
        string memory b
    ) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    // implement dummy override functions
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external {}

    function facetAddress(
        bytes4 _functionSelector
    ) external view returns (address facetAddress_) {}

    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_)
    {}

    function facetFunctionSelectors(
        address _facet
    ) external view returns (bytes4[] memory facetFunctionSelectors_) {}

    function facets() external view returns (Facet[] memory facets_) {}
}
