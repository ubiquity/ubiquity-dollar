// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./DiamondTestSetup.sol";
import "../../src/diamond/libraries/Constants.sol";
import "forge-std/console.sol";

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
        console.log(
            "dollar_manager_addr:%s diamond:%s",
            dollar_manager_addr,
            address(diamond)
        );
    }

    function testSetSymbol_ShouldRevert_IfMethodIsCalledNotByAdmin() public {
        vm.expectRevert("MGR: Caller is not admin");
        IUbiquityDollarToken.setSymbol("ANY_SYMBOL");
    }

    function testSetSymbol_ShouldSetSymbol() public {
        vm.prank(admin);
        IUbiquityDollarToken.setSymbol("ANY_SYMBOL");
        assertEq(IUbiquityDollarToken.symbol(), "ANY_SYMBOL");
    }

    function testSetName_ShouldRevert_IfMethodIsCalledNotByAdmin() public {
        vm.expectRevert("ERC20: deployer must be manager admin");
        IUbiquityDollarToken.setName("ANY_NAME");
    }

    function testSetName_ShouldSetName() public {
        vm.prank(admin);
        IUbiquityDollarToken.setName("ANY_NAME");
        assertEq(IUbiquityDollarToken.name(), "ANY_NAME");
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
                IUbiquityDollarToken.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        curOwner,
                        spender,
                        1e18,
                        IUbiquityDollarToken.nonces(curOwner),
                        0
                    )
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        // run permit
        vm.prank(spender);
        vm.expectRevert("Dollar: EXPIRED");
        IUbiquityDollarToken.permit(curOwner, spender, 1e18, 0, v, r, s);
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
                IUbiquityDollarToken.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        1e18,
                        IUbiquityDollarToken.nonces(owner),
                        block.timestamp + 1 days
                    )
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(spenderPrivateKey, digest);
        // run permit
        vm.prank(spender);
        vm.expectRevert("Dollar: INVALID_SIGNATURE");
        IUbiquityDollarToken.permit(
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
                IUbiquityDollarToken.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        1e18,
                        IUbiquityDollarToken.nonces(owner),
                        block.timestamp + 1 days
                    )
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        // run permit
        uint256 noncesBefore = IUbiquityDollarToken.nonces(owner);
        vm.prank(spender);
        IUbiquityDollarToken.permit(
            owner,
            spender,
            1e18,
            block.timestamp + 1 days,
            v,
            r,
            s
        );
        assertEq(IUbiquityDollarToken.allowance(owner, spender), 1e18);
        assertEq(IUbiquityDollarToken.nonces(owner), noncesBefore + 1);
    }

    function testBurn_ShouldRevert_IfContractIsPaused() public {
        vm.prank(admin);
        IAccessCtrl.pause();
        vm.expectRevert("Pausable: paused");
        IUbiquityDollarToken.burn(50);
    }

    function testBurn_ShouldBurnTokens() public {
        // mint 100 tokens to user
        address mockAddress = address(0x1);
        vm.prank(admin);
        IUbiquityDollarToken.mint(mockAddress, 100);
        assertEq(IUbiquityDollarToken.balanceOf(mockAddress), 100);
        // burn 50 tokens from user
        vm.prank(mockAddress);
        vm.expectEmit(true, true, true, true);
        emit Burning(mockAddress, 50);
        IUbiquityDollarToken.burn(50);
        assertEq(IUbiquityDollarToken.balanceOf(mockAddress), 50);
    }

    function testBurnFrom_ShouldRevert_IfCalledNotByTheBurnerRole() public {
        address mockAddress = address(0x1);
        vm.expectRevert("Governance token: not burner");
        IUbiquityDollarToken.burnFrom(mockAddress, 50);
    }

    function testBurnFrom_ShouldRevert_IfContractIsPaused() public {
        // mint 100 tokens to user
        address mockAddress = address(0x1);
        vm.prank(admin);
        IUbiquityDollarToken.mint(mockAddress, 100);
        assertEq(IUbiquityDollarToken.balanceOf(mockAddress), 100);
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
        IUbiquityDollarToken.burnFrom(mockAddress, 50);
    }

    function testBurnFrom_ShouldBurnTokensFromAddress() public {
        // mint 100 tokens to user
        address mockAddress = address(0x1);
        vm.prank(admin);
        IUbiquityDollarToken.mint(mockAddress, 100);
        assertEq(IUbiquityDollarToken.balanceOf(mockAddress), 100);
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
        IUbiquityDollarToken.burnFrom(mockAddress, 50);
        assertEq(IUbiquityDollarToken.balanceOf(mockAddress), 50);
    }

    function testMint_ShouldRevert_IfCalledNotByTheMinterRole() public {
        address mockAddress = address(0x1);
        vm.expectRevert("Governance token: not minter");
        IUbiquityDollarToken.mint(mockAddress, 100);
    }

    function testMint_ShouldRevert_IfContractIsPaused() public {
        vm.startPrank(admin);
        IAccessCtrl.pause();
        address mockAddress = address(0x1);
        vm.expectRevert("Pausable: paused");
        IUbiquityDollarToken.mint(mockAddress, 100);
        vm.stopPrank();
    }

    function testMint_ShouldMintTokens() public {
        address mockAddress = address(0x1);
        uint256 balanceBefore = IUbiquityDollarToken.balanceOf(mockAddress);
        vm.prank(admin);
        vm.expectEmit(true, true, false, true);
        emit Minting(mockAddress, admin, 100);
        IUbiquityDollarToken.mint(mockAddress, 100);
        uint256 balanceAfter = IUbiquityDollarToken.balanceOf(mockAddress);
        assertEq(balanceAfter - balanceBefore, 100);
    }

    function testPause_ShouldRevert_IfCalledNotByThePauserRole() public {
        vm.expectRevert("Governance token: not pauser");
        IAccessCtrl.pause();
    }

    function testPause_ShouldPauseContract() public {
        assertFalse(IAccessCtrl.paused());
        vm.prank(admin);
        IAccessCtrl.pause();
        assertTrue(IAccessCtrl.paused());
    }

    function testUnpause_ShouldRevert_IfCalledNotByThePauserRole() public {
        vm.expectRevert("Governance token: not pauser");
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
        assertEq(IUbiquityDollarToken.name(), "Test");
    }

    function testSymbol_ShouldReturnSymbolName() public {
        assertEq(IUbiquityDollarToken.symbol(), "Test");
    }

    function testTransfer_ShouldRevert_IfContractIsPaused() public {
        // admin pauses contract
        vm.prank(admin);
        IAccessCtrl.pause();
        // transfer tokens to user
        address userAddress = address(0x1);
        vm.prank(admin);
        vm.expectRevert("Pausable: paused");
        IUbiquityDollarToken.transfer(userAddress, 10);
    }

    function testTransfer_ShouldTransferTokens() public {
        // mint tokens to admin
        vm.prank(admin);
        IUbiquityDollarToken.mint(admin, 100);
        // transfer tokens to user
        address userAddress = address(0x1);
        assertEq(IUbiquityDollarToken.balanceOf(userAddress), 0);
        vm.prank(admin);
        IUbiquityDollarToken.transfer(userAddress, 10);
        assertEq(IUbiquityDollarToken.balanceOf(userAddress), 10);
    }
}
