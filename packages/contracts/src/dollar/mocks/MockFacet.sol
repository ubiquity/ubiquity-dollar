// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibDiamond} from "../libraries/LibDiamond.sol";

interface IMockFacet {
    function functionA() external returns (uint256);
    function functionB() external returns (uint256);
}

struct NewSimpleStorage {
    uint256 slot1;
}

struct NewStorageExtended {
    uint256 slot1;
    uint256 slot2;
}

bytes32 constant NEW_STORAGE_POSITION = keccak256(
    "ubiquity.contracts.mock.storage"
);

contract MockFacetInitializer {
    function initialize() external {
        NewStorageExtended storage newStorage;
        bytes32 position = NEW_STORAGE_POSITION;
        assembly {
            newStorage.slot := position
        }
        newStorage.slot1 = 2;
        newStorage.slot2 = 22;
    }

    function initializeRevert() external pure returns (uint256) {
        revert();
    }

    function initializeRevertWithMessage() external pure returns (uint256) {
        revert("MockFacetError");
    }
}

contract MockFacetWithPureFunctions is IMockFacet {
    function functionA() external pure returns (uint256) {
        return 1;
    }

    function functionB() external pure returns (uint256) {
        return 2;
    }
}

contract MockFacetWithStorageWriteFunctions is IMockFacet {
    function functionA() external view returns (uint256) {
        NewSimpleStorage storage newStorage;
        bytes32 position = NEW_STORAGE_POSITION;
        assembly {
            newStorage.slot := position
        }
        return newStorage.slot1;
    }

    function functionB() external returns (uint256) {
        NewSimpleStorage storage newStorage;
        bytes32 position = NEW_STORAGE_POSITION;
        assembly {
            newStorage.slot := position
        }
        newStorage.slot1 = 1;
        return newStorage.slot1;
    }
}

contract MockFacetWithExtendedStorageWriteFunctions is IMockFacet {
    function functionA() external view returns (uint256) {
        NewStorageExtended storage newStorage;
        bytes32 position = NEW_STORAGE_POSITION;
        assembly {
            newStorage.slot := position
        }
        return newStorage.slot1;
    }

    function functionB() external view returns (uint256) {
        NewStorageExtended storage newStorage;
        bytes32 position = NEW_STORAGE_POSITION;
        assembly {
            newStorage.slot := position
        }
        return newStorage.slot2;
    }
}
