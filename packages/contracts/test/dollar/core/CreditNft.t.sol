// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ManagerFacet} from "../../../src/dollar/facets/ManagerFacet.sol";
import {CreditNft} from "../../../src/dollar/core/CreditNft.sol";

import "../../helpers/LocalTestHelper.sol";

contract CreditNftTest is LocalTestHelper {
    address dollarManagerAddress;
    address creditNftAddress;

    event MintedCreditNft(
        address recipient,
        uint256 expiryBlock,
        uint256 amount
    );

    event BurnedCreditNft(
        address creditNftHolder,
        uint256 expiryBlock,
        uint256 amount
    );

    function setUp() public override {
        super.setUp();

        // deploy Credit NFT token
        creditNftAddress = address(creditNft);
        vm.prank(admin);
        managerFacet.setCreditNftAddress(address(creditNftAddress));
    }

    function testSetManager_ShouldRevert_WhenNotAdmin() public {
        vm.prank(address(0x123abc));
        vm.expectRevert("ERC20Ubiquity: not admin");
        creditNft.setManager(address(0x123abc));
    }

    function testSetManager_ShouldSetDiamond() public {
        address newDiamond = address(0x123abc);
        vm.prank(admin);
        creditNft.setManager(newDiamond);
        require(creditNft.getManager() == newDiamond);
    }

    function testMintCreditNft_ShouldRevert_WhenNotCreditNftManager() public {
        vm.expectRevert("Caller is not a CreditNft manager");
        creditNft.mintCreditNft(address(0x123), 1, 100);
    }

    function testMintCreditNft_ShouldMintCreditNft() public {
        address receiver = address(0x123);
        uint256 expiryBlockNumber = 100;
        uint256 mintAmount = 1;

        uint256 init_balance = creditNft.balanceOf(receiver, expiryBlockNumber);
        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit MintedCreditNft(receiver, expiryBlockNumber, 1);
        creditNft.mintCreditNft(receiver, mintAmount, expiryBlockNumber);
        uint256 last_balance = creditNft.balanceOf(receiver, expiryBlockNumber);
        assertEq(last_balance - init_balance, mintAmount);

        uint256[] memory holderTokens = creditNft.holderTokens(receiver);
        assertEq(holderTokens[0], expiryBlockNumber);
    }

    function testBurnCreditNft_ShouldRevert_WhenNotCreditNftManager() public {
        vm.expectRevert("Caller is not a CreditNft manager");
        creditNft.burnCreditNft(address(0x123), 1, 100);
    }

    function testBurnCreditNft_ShouldBurnCreditNft() public {
        address creditNftOwner = address(0x123);
        uint256 expiryBlockNumber = 100;
        uint256 burnAmount = 1;

        vm.prank(admin);
        creditNft.mintCreditNft(creditNftOwner, 10, expiryBlockNumber);
        uint256 init_balance = creditNft.balanceOf(
            creditNftOwner,
            expiryBlockNumber
        );
        vm.prank(creditNftOwner);
        creditNft.setApprovalForAll(admin, true);
        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit BurnedCreditNft(creditNftOwner, expiryBlockNumber, 1);
        creditNft.burnCreditNft(creditNftOwner, burnAmount, expiryBlockNumber);
        uint256 last_balance = creditNft.balanceOf(
            creditNftOwner,
            expiryBlockNumber
        );
        assertEq(init_balance - last_balance, burnAmount);
    }

    function testUpdateTotalDebt_ShouldUpdateTotalDebt() public {
        vm.startPrank(admin);
        creditNft.mintCreditNft(vm.addr(0x111), 10, 10000); // 10 -> amount, 10000 -> expiryBlockNumber
        creditNft.mintCreditNft(vm.addr(0x222), 10, 20000);
        creditNft.mintCreditNft(vm.addr(0x333), 10, 30000);
        vm.stopPrank();

        // sets block.number
        vm.roll(block.number + 15000);
        creditNft.updateTotalDebt();
        uint256 outStandingTotalDebt = creditNft.getTotalOutstandingDebt();
        assertEq(outStandingTotalDebt, 20);
    }

    function testGetTotalOutstandingDebt_ReturnTotalDebt() public {
        vm.startPrank(admin);
        creditNft.mintCreditNft(address(0x111), 10, 10000); // 10 -> amount, 10000 -> expiryBlockNumber
        creditNft.mintCreditNft(address(0x222), 10, 20000);
        creditNft.mintCreditNft(address(0x333), 10, 30000);
        vm.stopPrank();

        // sets block.number
        vm.roll(block.number + 25000);
        creditNft.updateTotalDebt();
        uint256 outStandingTotalDebt = creditNft.getTotalOutstandingDebt();
        assertEq(outStandingTotalDebt, 10);
    }

    function testUUPS_ShouldUpgradeAndCall() external {
        CreditNftUpgraded creditNftUpgraded = new CreditNftUpgraded();

        vm.startPrank(admin);
        bytes memory hasUpgradedCall = abi.encodeWithSignature("hasUpgraded()");

        // trying to directly call will fail and exit early so call it like this
        (bool success, ) = address(creditNft).call(hasUpgradedCall);
        assertEq(success, false, "should not have upgraded yet");
        require(success == false, "should not have upgraded yet");

        creditNft.upgradeTo(address(creditNftUpgraded));

        // It will also fail unless cast so we'll use the same pattern as above
        (success, ) = address(creditNft).call(hasUpgradedCall);
        assertEq(success, true, "should have upgraded");
        require(success == true, "should have upgraded");

        vm.expectRevert();
        creditNft.initialize(address(diamond));

        vm.stopPrank();
    }

    function testUUPS_ImplChanges() external {
        CreditNftUpgraded creditNftUpgraded = new CreditNftUpgraded();

        address oldImpl = address(creditNft);
        address newImpl = address(creditNftUpgraded);

        vm.prank(admin);
        creditNft.upgradeTo(newImpl);

        bytes memory getImplCall = abi.encodeWithSignature("getImpl()");

        (bool success, bytes memory data) = address(creditNft).call(
            getImplCall
        );
        assertEq(success, true, "should have upgraded");

        address newAddrViaNewFunc = abi.decode(data, (address));

        assertEq(
            newAddrViaNewFunc,
            newImpl,
            "should be the new implementation"
        );
        assertTrue(
            newAddrViaNewFunc != oldImpl,
            "should not be the old implementation"
        );
    }

    function testUUPS_InitializedVersion() external {
        uint expectedVersion = 1;
        uint baseExpectedVersion = 255;

        CreditNftUpgraded creditNftUpgraded = new CreditNftUpgraded();
        CreditNftUpgraded creditNftT = new CreditNftUpgraded();

        vm.startPrank(admin);
        creditNft.upgradeTo(address(creditNftUpgraded));

        bytes memory getVersionCall = abi.encodeWithSignature("getVersion()");

        (bool success, bytes memory data) = address(creditNft).call(
            getVersionCall
        );
        assertEq(success, true, "should have upgraded");
        uint8 version = abi.decode(data, (uint8));

        assertEq(
            version,
            expectedVersion,
            "should be the same version as only initialized once"
        );

        creditNft.upgradeTo(address(creditNftT));

        (success, data) = address(creditNft).call(getVersionCall);
        assertEq(success, true, "should have upgraded");
        version = abi.decode(data, (uint8));

        assertEq(
            version,
            expectedVersion,
            "should be the same version as only initialized once"
        );

        (success, data) = address(creditNftT).call(getVersionCall);
        assertEq(success, true, "should succeed");
        version = abi.decode(data, (uint8));

        assertEq(
            version,
            baseExpectedVersion,
            "should be maxed as initializers are disabled."
        );
    }

    function testUUPS_initialization() external {
        CreditNftUpgraded creditNftUpgraded = new CreditNftUpgraded();

        vm.startPrank(admin);
        vm.expectRevert();
        creditNftUpgraded.initialize(address(diamond));

        vm.expectRevert();
        creditNft.initialize(address(diamond));

        vm.expectRevert();
        creditNft.initialize(address(diamond));

        creditNft.upgradeTo(address(creditNftUpgraded));

        vm.expectRevert();
        creditNft.initialize(address(diamond));
    }

    function testUUPS_AdminAuth() external {
        CreditNftUpgraded creditNftUpgraded = new CreditNftUpgraded();

        vm.expectRevert();
        creditNft.upgradeTo(address(creditNftUpgraded));

        vm.prank(admin);
        creditNft.upgradeTo(address(creditNftUpgraded));

        bytes memory hasUpgradedCall = abi.encodeWithSignature("hasUpgraded()");
        (bool success, bytes memory data) = address(creditNft).call(
            hasUpgradedCall
        );
        bool hasUpgraded = abi.decode(data, (bool));

        assertEq(hasUpgraded, true, "should have upgraded");
        assertEq(success, true, "should have upgraded");
        require(success == true, "should have upgraded");
    }
}

contract CreditNftUpgraded is CreditNft {
    function hasUpgraded() public pure returns (bool) {
        return true;
    }

    function getVersion() public view returns (uint8) {
        return super._getInitializedVersion();
    }

    function getImpl() public view returns (address) {
        return super._getImplementation();
    }
}
