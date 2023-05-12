// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../DiamondTestSetup.sol";
import {IMetaPool} from "../../../src/dollar/interfaces/IMetaPool.sol";
import {MockMetaPool} from "../../../src/dollar/mocks/MockMetaPool.sol";

contract UbiquityPoolFacetTest is DiamondSetup {
    address curve3CRVTokenAddress = address(0x333);
    address metaPoolAddress;
    address twapOracleAddress;

    function setUp() public override {
        super.setUp();
        metaPoolAddress = address(
            new MockMetaPool(address(IDollar), curve3CRVTokenAddress)
        );
        vm.prank(owner);
        ITWAPOracleDollar3pool.setPool(metaPoolAddress, curve3CRVTokenAddress);
    }

    function test_setNotRedeemPausedShouldWorkIfAdmin() public {
        vm.prank(admin);
        IUbiquityPoolFacet.setNotRedeemPaused(address(0x333), true);
        assertEq(IUbiquityPoolFacet.getNotRedeemPaused(address(0x333)), true);
    }

    function test_setNotRedeemPausedShouldFailIfNotAdmin() public {
        vm.expectRevert("Manager: Caller is not admin");
        IUbiquityPoolFacet.setNotRedeemPaused(address(0x333), true);
    }

    function test_setNotMintPausedShouldWorkIfAdmin() public {
        vm.prank(admin);
        IUbiquityPoolFacet.setNotMintPaused(address(0x333), true);
        assertEq(IUbiquityPoolFacet.getNotMintPaused(address(0x333)), true);
    }

    function test_setNotMintPausedShouldFailIfNotAdmin() public {
        vm.expectRevert("Manager: Caller is not admin");
        IUbiquityPoolFacet.setNotMintPaused(address(0x333), true);
    }

    function test_addTokenShouldWorkIfAdmin() public {
        vm.prank(admin);
        IUbiquityPoolFacet.addToken(
            address(IDollar),
            IMetaPool(metaPoolAddress)
        );
    }

    function test_addTokenWithZeroAddressFail() public {
        vm.startPrank(admin);
        vm.expectRevert("0 address detected");
        IUbiquityPoolFacet.addToken(address(0), IMetaPool(metaPoolAddress));
        vm.expectRevert("0 address detected");
        IUbiquityPoolFacet.addToken(address(IDollar), IMetaPool(address(0)));
        vm.stopPrank();
    }

    function test_addTokenShouldFailIfNotAdmin() public {
        vm.expectRevert("Manager: Caller is not admin");
        IUbiquityPoolFacet.addToken(
            address(IDollar),
            IMetaPool(address(0x444))
        );
    }

    /*   function mintDollarShouldWork() public {
        vm.prank(admin);
        IUbiquityPoolFacet.mintDollar(
            address(0x333),
            1000,
            1000,
            curve3CRVTokenAddress,
            twapOracleAddress,
            metaPoolAddress
        );
        assertEq(IUbiquityPoolFacet.getNotMintPaused(address(0x333)), true);
    }

    function redeemDollarShouldWork() public {
        vm.prank(admin);
        IUbiquityPoolFacet.redeemDollar(
            address(0x333),
            1000,
            1000,
            curve3CRVTokenAddress,
            twapOracleAddress,
            metaPoolAddress
        );
        assertEq(IUbiquityPoolFacet.getNotMintPaused(address(0x333)), true);
    }

    function collectRedemptionShouldWork() public {
        vm.prank(admin);
        IUbiquityPoolFacet.collectRedemption(
            address(0x333),
            curve3CRVTokenAddress,
            twapOracleAddress,
            metaPoolAddress
        );
        assertEq(IUbiquityPoolFacet.getNotMintPaused(address(0x333)), true);
    } */
}
