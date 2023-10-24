// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../helpers/LocalTestHelper.sol";
import {IMetaPool} from "../../../src/dollar/interfaces/IMetaPool.sol";
import {StakingShare} from "../../../src/dollar/core/StakingShare.sol";
import "../../../src/dollar/libraries/Constants.sol";
import {BondingShare} from "../../../src/dollar/mocks/MockShareV1.sol";

contract DepositStakingShare is LocalTestHelper {
    address treasury = address(0x3);
    address secondAccount = address(0x4);
    address thirdAccount = address(0x5);
    address fourthAccount = address(0x6);
    address fifthAccount = address(0x7);
    address stakingZeroAccount = address(0x8);
    address stakingMinAccount = address(0x9);
    address stakingMaxAccount = address(0x10);

    uint256 fourthBal;
    uint256 minBal;
    uint256 maxBal;
    uint256[] creationBlock;
    IMetaPool metapool;

    event Paused(address _caller);
    event Unpaused(address _caller);
    event TransferSingle(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount
    );

    function setUp() public virtual override {
        super.setUp();
        // grant diamond token staking share right rights
        vm.prank(admin);
        accessControlFacet.grantRole(
            STAKING_SHARE_MINTER_ROLE,
            address(diamond)
        );
        metapool = IMetaPool(metaPoolAddress);
        fourthBal = metapool.balanceOf(fourthAccount);
        minBal = metapool.balanceOf(stakingMinAccount);
        maxBal = metapool.balanceOf(stakingMaxAccount);
        address[4] memory depositingAccounts = [
            stakingMinAccount,
            fourthAccount,
            stakingMaxAccount,
            stakingMaxAccount
        ];
        uint256[4] memory depositAmounts = [
            minBal,
            fourthBal,
            maxBal / 2,
            maxBal / 2
        ];
        uint256[4] memory lockupWeeks = [
            uint256(1),
            uint256(52),
            uint256(208),
            uint256(208)
        ];

        for (uint256 i; i < depositingAccounts.length; ++i) {
            vm.startPrank(depositingAccounts[i]);
            metapool.approve(address(stakingFacet), 2 ** 256 - 1);
            creationBlock.push(block.number);
            stakingFacet.deposit(depositAmounts[i], lockupWeeks[i]);
            vm.stopPrank();
        }
    }
}

contract StakingShareTest is DepositStakingShare {
    uint256[] ids;
    uint256[] amounts;

    function testUpdateStake_ShouldUpdateStake(
        uint128 amount,
        uint128 debt,
        uint256 end
    ) public {
        vm.prank(admin);
        accessControlFacet.grantRole(STAKING_SHARE_MINTER_ROLE, address(admin));
        vm.prank(admin);
        stakingShare.updateStake(1, uint256(amount), uint256(debt), end);
        StakingShare.Stake memory stake = stakingShare.getStake(1);
        assertEq(stake.lpAmount, amount);
        assertEq(stake.lpRewardDebt, debt);
        assertEq(stake.endBlock, end);
    }

    function testUpdateStake_ShouldRevert_IfNotMinter(
        uint128 amount,
        uint128 debt,
        uint256 end
    ) public {
        vm.expectRevert("Staking Share: not minter");
        vm.prank(secondAccount);
        stakingShare.updateStake(1, uint256(amount), uint256(debt), end);
    }

    function testUpdateStake_ShouldRevert_IfPaused(
        uint128 amount,
        uint128 debt,
        uint256 end
    ) public {
        vm.prank(admin);
        stakingShare.pause();

        vm.expectRevert("Staking Share: not minter");
        vm.prank(admin);
        stakingShare.updateStake(1, uint256(amount), uint256(debt), end);
    }

    function testMint_ShouldMint(
        uint128 deposited,
        uint128 debt,
        uint256 end
    ) public {
        vm.prank(admin);
        accessControlFacet.grantRole(STAKING_SHARE_MINTER_ROLE, address(admin));
        vm.prank(admin);
        uint256 id = stakingShare.mint(
            secondAccount,
            uint256(deposited),
            uint256(debt),
            end
        );
        StakingShare.Stake memory stake = stakingShare.getStake(id);
        assertEq(stake.minter, secondAccount);
        assertEq(stake.lpAmount, deposited);
        assertEq(stake.lpRewardDebt, debt);
        assertEq(stake.endBlock, end);
        assertEq(stake.creationBlock, block.number);
    }

    function testMint_ShouldRevert_IfMintingToZeroAddress(
        uint128 deposited,
        uint128 debt,
        uint256 end
    ) public {
        vm.expectRevert("Staking Share: not minter");
        vm.prank(admin);
        stakingShare.mint(address(0), uint256(deposited), uint256(debt), end);
    }

    function testMint_ShouldRevert_IfNotMinter(
        uint128 deposited,
        uint128 debt,
        uint256 end
    ) public {
        vm.expectRevert("Staking Share: not minter");
        vm.prank(secondAccount);

        stakingShare.mint(address(0), uint256(deposited), uint256(debt), end);
    }

    function testMint_ShouldRevert_IfPaused(
        uint128 deposited,
        uint128 debt,
        uint256 end
    ) public {
        vm.prank(admin);
        stakingShare.pause();

        vm.prank(admin);
        vm.expectRevert("Staking Share: not minter");
        stakingShare.mint(address(0), uint256(deposited), uint256(debt), end);
    }

    function testPause_ShouldPause() public {
        vm.expectEmit(true, false, false, true);
        emit Paused(admin);

        vm.prank(admin);
        accessControlFacet.pause();
    }

    function testPause_ShouldRevert_IfNotPauser() public {
        vm.expectRevert("Manager: Caller is not admin");
        vm.prank(secondAccount);
        accessControlFacet.pause();
    }

    function testUnpause_ShouldUnpause() public {
        vm.prank(admin);
        accessControlFacet.pause();

        vm.expectEmit(true, false, false, true);
        emit Unpaused(admin);

        vm.prank(admin);
        accessControlFacet.unpause();
    }

    function testUnpause_ShouldRevert_IfNotPauser() public {
        vm.prank(admin);
        accessControlFacet.pause();

        vm.expectRevert("Manager: Caller is not admin");
        vm.prank(secondAccount);
        accessControlFacet.unpause();
    }

    function testSafeTransferFrom_ShouldTransferTokenId() public {
        vm.prank(stakingMinAccount);
        stakingShare.setApprovalForAll(admin, true);

        bytes memory data;
        vm.prank(admin);
        stakingShare.safeTransferFrom(
            stakingMinAccount,
            secondAccount,
            1,
            1,
            data
        );
        ids.push(1);

        assertEq(stakingShare.holderTokens(secondAccount), ids);
    }

    function testSafeTransferFrom_ShouldRevert_IfToAddressZero() public {
        vm.prank(stakingMinAccount);
        stakingShare.setApprovalForAll(admin, true);

        vm.expectRevert("ERC1155: transfer to the zero address");
        bytes memory data;
        vm.prank(admin);
        stakingShare.safeTransferFrom(
            stakingMinAccount,
            address(0),
            1,
            1,
            data
        );
    }

    function testSafeTransferFrom_ShouldRevert_IfInsufficientBalance() public {
        vm.prank(fifthAccount);
        stakingShare.setApprovalForAll(admin, true);

        vm.expectRevert("ERC1155: insufficient balance for transfer");
        bytes memory data;
        vm.prank(admin);
        stakingShare.safeTransferFrom(fifthAccount, secondAccount, 1, 1, data);
    }

    function testSafeTransferFrom_ShouldRevert_IfPaused() public {
        vm.prank(admin);
        stakingShare.pause();

        vm.expectRevert("Pausable: paused");
        vm.prank(admin);
        bytes memory data;
        stakingShare.safeTransferFrom(
            stakingMinAccount,
            secondAccount,
            1,
            1,
            data
        );
    }

    function testSafeBatchTransferFrom_ShouldTransferTokenIds() public {
        ids.push(3);
        ids.push(4);
        amounts.push(1);
        amounts.push(1);

        vm.prank(stakingMaxAccount);
        stakingShare.setApprovalForAll(admin, true);

        bytes memory data;

        vm.prank(admin);
        stakingShare.safeBatchTransferFrom(
            stakingMaxAccount,
            secondAccount,
            ids,
            amounts,
            data
        );
        assertEq(stakingShare.holderTokens(secondAccount), ids);
    }

    function testSafeBatchTransferFrom_ShouldRevert_IfPaused() public {
        vm.prank(admin);
        stakingShare.pause();

        vm.expectRevert("Pausable: paused");
        bytes memory data;
        vm.prank(admin);
        stakingShare.safeBatchTransferFrom(
            stakingMaxAccount,
            secondAccount,
            ids,
            amounts,
            data
        );
    }

    function testTotalSupply_ShouldReturn_TotalSupply() public {
        assertEq(stakingShare.totalSupply(), 4);
    }

    function testGetStake_ShouldReturnStake() public {
        StakingShare.Stake memory stake = StakingShare.Stake(
            fourthAccount,
            fourthBal,
            creationBlock[1],
            stakingFormulasFacet.durationMultiply(
                fourthBal,
                52,
                stakingFacet.stakingDiscountMultiplier()
            ),
            stakingFacet.blockCountInAWeek() * 52,
            fourthBal
        );

        StakingShare.Stake memory stake_ = stakingShare.getStake(2);
        bytes32 stake1 = bytes32(abi.encode(stake));
        bytes32 stake2 = bytes32(abi.encode(stake_));
        assertEq(stake1, stake2);
    }

    function testSetUri_ShouldSetUri() public {
        vm.prank(admin);
        accessControlFacet.grantRole(STAKING_SHARE_MINTER_ROLE, address(admin));

        string memory stringTest = "{'name':'Staking Share','description':,"
        "'Ubiquity Staking Share',"
        "'image': 'https://bafybeifibz4fhk4yag5reupmgh5cdbm2oladke4zfd7ldyw7avgipocpmy.ipfs.infura-ipfs.io/'}";
        vm.prank(admin);
        stakingShare.setUri(1, stringTest);
        assertEq(
            stakingShare.uri(1),
            stringTest,
            "the uri is not set correctly by the method"
        );
    }

    function testSetBaseUri_ShouldSetUri() public {
        vm.prank(admin);
        accessControlFacet.grantRole(STAKING_SHARE_MINTER_ROLE, address(admin));

        string memory stringTest = "{'name':'Staking Share','description':,"
        "'Ubiquity Staking Share',"
        "'image': 'https://bafybeifibz4fhk4yag5reupmgh5cdbm2oladke4zfd7ldyw7avgipocpmy.ipfs.infura-ipfs.io/'}";
        vm.prank(admin);
        stakingShare.setBaseUri(stringTest);
        assertEq(
            stakingShare.getBaseUri(),
            stringTest,
            "the uri is not set correctly by the method"
        );
    }

    function testSetUriSingle_ShouldSetUri() public {
        vm.prank(admin);
        accessControlFacet.grantRole(STAKING_SHARE_MINTER_ROLE, address(admin));

        string memory stringTest = "{'name':'Staking Share','description':,"
        "'Ubiquity Staking Share',"
        "'image': 'https://bafybeifibz4fhk4yag5reupmgh5cdbm2oladke4zfd7ldyw7avgipocpmy.ipfs.infura-ipfs.io/'}";
        vm.prank(admin);
        stakingShare.setUri(stringTest);
        assertEq(
            stakingShare.uri(1),
            stringTest,
            "the uri is not set correctly by the method"
        );
    }

    function testSetUri_ShouldRevert_IfGovernanceTokenNotStakingManager()
        public
    {
        string memory stringTest = "{'a parsed json':'value'}";
        vm.expectRevert("Staking Share: not minter");
        vm.prank(fifthAccount);
        stakingShare.setUri(1, stringTest);
    }

    function testUUPS_ShouldUpgradeAndCall() external {
        BondingShare bondingShare = new BondingShare();

        string
            memory uri = "https://bafybeifibz4fhk4yag5reupmgh5cdbm2oladke4zfd7ldyw7avgipocpmy.ipfs.infura-ipfs.io/";

        vm.startPrank(admin);
        bytes memory hasUpgradedCall = abi.encodeWithSignature("hasUpgraded()");

        // trying to directly call will fail and exit early so call it like this
        (bool success, ) = address(stakingShare).call(hasUpgradedCall);
        assertEq(success, false, "should not have upgraded yet");
        require(success == false, "should not have upgraded yet");

        stakingShare.upgradeTo(address(bondingShare));

        // It will also fail unless cast so we'll use the same pattern as above
        (success, ) = address(stakingShare).call(hasUpgradedCall);
        assertEq(success, true, "should have upgraded");
        require(success == true, "should have upgraded");

        vm.expectRevert();
        stakingShare.initialize(address(diamond), uri);

        vm.stopPrank();
    }

    function testUUPS_ImplChanges() external {
        BondingShare bondingShare = new BondingShare();

        address oldImpl = address(stakingShare);
        address newImpl = address(bondingShare);

        vm.prank(admin);
        stakingShare.upgradeTo(newImpl);

        bytes memory getImplCall = abi.encodeWithSignature("getImpl()");

        (bool success, bytes memory data) = address(stakingShare).call(
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

        BondingShare bondingShare = new BondingShare();
        BondingShareUpgraded bondingShareUpgraded = new BondingShareUpgraded();

        vm.startPrank(admin);
        stakingShare.upgradeTo(address(bondingShare));

        bytes memory getVersionCall = abi.encodeWithSignature("getVersion()");

        (bool success, bytes memory data) = address(stakingShare).call(
            getVersionCall
        );
        assertEq(success, true, "should have upgraded");
        uint8 version = abi.decode(data, (uint8));

        assertEq(
            version,
            expectedVersion,
            "should be the same version as only initialized once"
        );

        stakingShare.upgradeTo(address(bondingShareUpgraded));

        (success, data) = address(stakingShare).call(getVersionCall);
        assertEq(success, true, "should have upgraded");
        version = abi.decode(data, (uint8));

        assertEq(
            version,
            expectedVersion,
            "should be the same version as only initialized once"
        );

        (success, data) = address(bondingShare).call(getVersionCall);
        assertEq(success, true, "should succeed");
        version = abi.decode(data, (uint8));

        assertEq(
            version,
            baseExpectedVersion,
            "should be maxed as initializers are disabled."
        );
    }

    function testUUPS_initialization() external {
        BondingShare bondingShare = new BondingShare();

        vm.startPrank(admin);
        vm.expectRevert();
        bondingShare.initialize(address(diamond), "test");

        vm.expectRevert();
        stakingShare.initialize(address(diamond), "test");

        vm.expectRevert();
        stakingShare.initialize(address(diamond), "test");

        stakingShare.upgradeTo(address(bondingShare));

        vm.expectRevert();
        stakingShare.initialize(address(diamond), "test");
    }

    function testUUPS_AdminAuth() external {
        BondingShare bondingShare = new BondingShare();

        vm.expectRevert();
        stakingShare.upgradeTo(address(bondingShare));

        vm.prank(admin);
        stakingShare.upgradeTo(address(bondingShare));

        bytes memory hasUpgradedCall = abi.encodeWithSignature("hasUpgraded()");
        (bool success, bytes memory data) = address(stakingShare).call(
            hasUpgradedCall
        );
        bool hasUpgraded = abi.decode(data, (bool));

        assertEq(hasUpgraded, true, "should have upgraded");
        assertEq(success, true, "should have upgraded");
        require(success == true, "should have upgraded");
    }
}

contract BondingShareUpgraded is BondingShare {
    function hasUpgraded() public pure override returns (bool) {
        return true;
    }

    function getVersion() public view override returns (uint8) {
        return super._getInitializedVersion();
    }

    function getImpl() public view override returns (address) {
        return super._getImplementation();
    }
}
