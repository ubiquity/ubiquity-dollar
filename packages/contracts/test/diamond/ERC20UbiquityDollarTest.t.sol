// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./DiamondTestSetup.sol";
import "../../src/diamond/libraries/Constants.sol";

contract ERC20UbiquityDollarTest is DiamondSetup {
    address token_addr;
    address dollar_manager_addr;
    event Minting(
        address indexed mock_addr1,
        address indexed _minter,
        uint256 _amount
    );

    event Burning(address indexed _burned, uint256 _amount);

    function setUp() public override {
        super.setUp();
        token_addr = address(diamond);
        dollar_manager_addr = address(diamond);
    }

    function testSetSymbol_ShouldRevert_IfMethodIsCalledNotByAdmin() public {
        vm.expectRevert("MGR: Caller is not admin");
        IDollarFacet.setSymbol("ANY_SYMBOL");
    }

    function testSetSymbol_ShouldSetSymbol() public {
        vm.prank(admin);
        IDollarFacet.setSymbol("ANY_SYMBOL");
        assertEq(IDollarFacet.symbol(), "ANY_SYMBOL");
    }

    function testSetName_ShouldRevert_IfMethodIsCalledNotByAdmin() public {
        vm.expectRevert("MGR: Caller is not admin");
        IDollarFacet.setName("ANY_NAME");
    }

    function testSetName_ShouldSetName() public {
        vm.prank(admin);
        IDollarFacet.setName("ANY_NAME");
        assertEq(IDollarFacet.name(), "ANY_NAME");
    }

    function testPermit_ShouldRevert_IfDeadlineExpired() public {
        // create owner and spender addresses
        uint256 ownerPrivateKey = 0x1;
        uint256 spenderPrivateKey = 0x2;
        address curOwner = vm.addr(ownerPrivateKey);
        address spender = vm.addr(spenderPrivateKey);
        // create owner's signature
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                IDollarFacet.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        curOwner,
                        spender,
                        1e18,
                        IDollarFacet.nonces(curOwner),
                        0
                    )
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        // run permit
        vm.prank(spender);
        vm.expectRevert("Dollar: EXPIRED");
        IDollarFacet.permit(curOwner, spender, 1e18, 0, v, r, s);
    }

    function testPermit_ShouldRevert_IfSignatureIsInvalid() public {
        // create owner and spender addresses
        uint256 ownerPrivateKey = 0x1;
        uint256 spenderPrivateKey = 0x2;
        address owner = vm.addr(ownerPrivateKey);
        address spender = vm.addr(spenderPrivateKey);
        // create owner's signature
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                IDollarFacet.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        1e18,
                        IDollarFacet.nonces(owner),
                        block.timestamp + 1 days
                    )
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(spenderPrivateKey, digest);
        // run permit
        vm.prank(spender);
        vm.expectRevert("Dollar: INVALID_SIGNATURE");
        IDollarFacet.permit(
            owner,
            spender,
            1e18,
            block.timestamp + 1 days,
            v,
            r,
            s
        );
    }

    function testPermit_ShouldIncreaseSpenderAllowance() public {
        // create owner and spender addresses
        uint256 ownerPrivateKey = 0x1;
        uint256 spenderPrivateKey = 0x2;
        address owner = vm.addr(ownerPrivateKey);
        address spender = vm.addr(spenderPrivateKey);
        // create owner's signature
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                IDollarFacet.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        1e18,
                        IDollarFacet.nonces(owner),
                        block.timestamp + 1 days
                    )
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        // run permit
        uint256 noncesBefore = IDollarFacet.nonces(owner);
        vm.prank(spender);
        IDollarFacet.permit(
            owner,
            spender,
            1e18,
            block.timestamp + 1 days,
            v,
            r,
            s
        );
        assertEq(IDollarFacet.allowance(owner, spender), 1e18);
        assertEq(IDollarFacet.nonces(owner), noncesBefore + 1);
    }

    function testBurn_ShouldRevert_IfContractIsPaused() public {
        vm.prank(admin);
        IAccessCtrl.pause();
        vm.expectRevert("Pausable: paused");
        IDollarFacet.burn(50);
    }

    function testBurn_ShouldBurnTokens() public {
        // mint 100 tokens to user
        address mockAddress = address(0x1);
        vm.prank(admin);
        IDollarFacet.mint(mockAddress, 100);
        assertEq(IDollarFacet.balanceOf(mockAddress), 100);
        // burn 50 tokens from user
        vm.prank(mockAddress);
        vm.expectEmit(true, true, true, true);
        emit Burning(mockAddress, 50);
        IDollarFacet.burn(50);
        assertEq(IDollarFacet.balanceOf(mockAddress), 50);
    }

    function testBurnFrom_ShouldRevert_IfCalledNotByTheBurnerRole() public {
        address mockAddress = address(0x1);
        vm.expectRevert("Governance token: not burner");
        IDollarFacet.burnFrom(mockAddress, 50);
    }

    function testBurnFrom_ShouldRevert_IfContractIsPaused() public {
        // mint 100 tokens to user
        address mockAddress = address(0x1);
        vm.prank(admin);
        IDollarFacet.mint(mockAddress, 100);
        assertEq(IDollarFacet.balanceOf(mockAddress), 100);
        // create burner role
        address burner = address(0x2);
        vm.prank(admin);
        IAccessCtrl.grantRole(
            keccak256("GOVERNANCE_TOKEN_BURNER_ROLE"),
            burner
        );
        // admin pauses contract
        vm.prank(admin);
        IAccessCtrl.pause();
        // burn 50 tokens for user
        vm.prank(burner);
        vm.expectRevert("Pausable: paused");
        IDollarFacet.burnFrom(mockAddress, 50);
    }

    function testBurnFrom_ShouldBurnTokensFromAddress() public {
        // mint 100 tokens to user
        address mockAddress = address(0x1);
        vm.prank(admin);
        IDollarFacet.mint(mockAddress, 100);
        assertEq(IDollarFacet.balanceOf(mockAddress), 100);
        // create burner role
        address burner = address(0x2);
        vm.prank(admin);
        IAccessCtrl.grantRole(
            keccak256("GOVERNANCE_TOKEN_BURNER_ROLE"),
            burner
        );
        // burn 50 tokens for user
        vm.prank(burner);
        vm.expectEmit(true, true, true, true);
        emit Burning(mockAddress, 50);
        IDollarFacet.burnFrom(mockAddress, 50);
        assertEq(IDollarFacet.balanceOf(mockAddress), 50);
    }

    function testMint_ShouldRevert_IfCalledNotByTheMinterRole() public {
        address mockAddress = address(0x1);
        vm.expectRevert("Governance token: not minter");
        IDollarFacet.mint(mockAddress, 100);
    }

    function testMint_ShouldRevert_IfContractIsPaused() public {
        vm.startPrank(admin);
        IAccessCtrl.pause();
        address mockAddress = address(0x1);
        vm.expectRevert("Pausable: paused");
        IDollarFacet.mint(mockAddress, 100);
        vm.stopPrank();
    }

    function testMint_ShouldMintTokens() public {
        address mockAddress = address(0x1);
        uint256 balanceBefore = IDollarFacet.balanceOf(mockAddress);
        vm.prank(admin);
        vm.expectEmit(true, true, false, true);
        emit Minting(mockAddress, admin, 100);
        IDollarFacet.mint(mockAddress, 100);
        uint256 balanceAfter = IDollarFacet.balanceOf(mockAddress);
        assertEq(balanceAfter - balanceBefore, 100);
    }

    function testPause_ShouldRevert_IfCalledNotByThePauserRole() public {
        vm.expectRevert("MGR: Caller is not admin");
        IAccessCtrl.pause();
    }

    function testPause_ShouldPauseContract() public {
        assertFalse(IAccessCtrl.paused());
        vm.prank(admin);
        IAccessCtrl.pause();
        assertTrue(IAccessCtrl.paused());
    }

    function testUnpause_ShouldRevert_IfCalledNotByThePauserRole() public {
        // admin pauses contract
        vm.prank(admin);
        IAccessCtrl.pause();
        vm.expectRevert("MGR: Caller is not admin");
        IAccessCtrl.unpause();
    }

    function testUnpause_ShouldUnpauseContract() public {
        vm.startPrank(admin);
        IAccessCtrl.pause();
        assertTrue(IAccessCtrl.paused());
        IAccessCtrl.unpause();
        assertFalse(IAccessCtrl.paused());
        vm.stopPrank();
    }

    function testName_ShouldReturnTokenName() public {
        assertEq(IDollarFacet.name(), "Ubiquity Algorithmic Dollar");
    }

    function testSymbol_ShouldReturnSymbolName() public {
        assertEq(IDollarFacet.symbol(), "uAD");
    }

    function testTransfer_ShouldRevert_IfContractIsPaused() public {
        // admin pauses contract
        vm.prank(admin);
        IAccessCtrl.pause();
        // transfer tokens to user
        address userAddress = address(0x1);
        vm.prank(admin);
        vm.expectRevert("Pausable: paused");
        IDollarFacet.transfer(userAddress, 10);
    }

    function testTransferFrom_ShouldRevert_IfContractIsPaused() public {
        // transfer tokens to user
        address userAddress = address(0x1);
        address user2Address = address(0x12);
        vm.prank(admin);
        IDollarFacet.mint(userAddress, 100);
        // admin pauses contract
        vm.prank(admin);
        IAccessCtrl.pause();
        vm.prank(userAddress);
        IDollarFacet.approve(user2Address, 100);
        vm.expectRevert("Pausable: paused");
        vm.prank(user2Address);
        IDollarFacet.transferFrom(userAddress, user2Address, 100);
    }

    function testTransfer_ShouldTransferTokens() public {
        // mint tokens to admin
        vm.prank(admin);
        IDollarFacet.mint(admin, 100);
        // transfer tokens to user
        address userAddress = address(0x1);
        assertEq(IDollarFacet.balanceOf(userAddress), 0);
        vm.prank(admin);
        IDollarFacet.transfer(userAddress, 10);
        assertEq(IDollarFacet.balanceOf(userAddress), 10);
    }

    // test transferFrom function should transfer tokens from address
    function testTransferFrom_ShouldTransferTokensFromAddress() public {
        // mint tokens to admin
        vm.prank(admin);
        IDollarFacet.mint(admin, 100);
        // transfer tokens to user
        address userAddress = address(0x1);
        address user2Address = address(0x12);
        assertEq(IDollarFacet.balanceOf(userAddress), 0);
        vm.prank(admin);
        IDollarFacet.transfer(userAddress, 100);
        assertEq(IDollarFacet.balanceOf(userAddress), 100);
        // approve user2 to transfer tokens from user
        vm.prank(userAddress);
        IDollarFacet.approve(user2Address, 100);
        // transfer tokens from user to user2
        vm.prank(user2Address);
        IDollarFacet.transferFrom(userAddress, user2Address, 100);
        assertEq(IDollarFacet.balanceOf(userAddress), 0);
        assertEq(IDollarFacet.balanceOf(user2Address), 100);
    }

    // test approve function should approve address to transfer tokens
    function testApprove_ShouldApproveAddressToTransferTokens() public {
        // mint tokens to admin
        vm.prank(admin);
        IDollarFacet.mint(admin, 100);
        // transfer tokens to user
        address userAddress = address(0x1);
        address user2Address = address(0x12);
        assertEq(IDollarFacet.balanceOf(userAddress), 0);
        vm.prank(admin);
        IDollarFacet.transfer(userAddress, 100);
        assertEq(IDollarFacet.balanceOf(userAddress), 100);
        // approve user2 to transfer tokens from user
        vm.prank(userAddress);
        IDollarFacet.approve(user2Address, 100);
        // transfer tokens from user to user2
        vm.prank(user2Address);
        IDollarFacet.transferFrom(userAddress, user2Address, 100);
        assertEq(IDollarFacet.balanceOf(userAddress), 0);
        assertEq(IDollarFacet.balanceOf(user2Address), 100);
    }

    // test allowance function should return allowance
    function testAllowance_ShouldReturnAllowance() public {
        // mint tokens to admin
        vm.prank(admin);
        IDollarFacet.mint(admin, 100);
        // transfer tokens to user
        address userAddress = address(0x1);
        address user2Address = address(0x12);
        assertEq(IDollarFacet.balanceOf(userAddress), 0);
        vm.prank(admin);
        IDollarFacet.transfer(userAddress, 100);
        assertEq(IDollarFacet.balanceOf(userAddress), 100);
        // approve user2 to transfer tokens from user
        vm.prank(userAddress);
        IDollarFacet.approve(user2Address, 100);
        // transfer tokens from user to user2
        vm.prank(user2Address);
        IDollarFacet.transferFrom(userAddress, user2Address, 100);
        assertEq(IDollarFacet.balanceOf(userAddress), 0);
        assertEq(IDollarFacet.balanceOf(user2Address), 100);
        assertEq(IDollarFacet.allowance(userAddress, user2Address), 0);
    }
}
