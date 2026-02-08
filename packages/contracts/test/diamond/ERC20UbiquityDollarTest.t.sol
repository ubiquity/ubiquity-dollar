// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./DiamondTestSetup.sol";
import "../../src/dollar/libraries/Constants.sol";

contract ERC20UbiquityDollarTest is DiamondTestSetup {
    event Minting(
        address indexed mockAddr1,
        address indexed minter,
        uint256 amount
    );

    event Burning(address indexed burned, uint256 amount);

    // create owner and spender addresses
    address erc20Owner;
    uint256 erc20OwnerPrivateKey;
    address erc20Spender;
    uint256 erc20SpenderPrivateKey;

    function setUp() public override {
        super.setUp();
        // create owner and spender addresses
        (erc20Owner, erc20OwnerPrivateKey) = makeAddrAndKey("owner");
        (erc20Spender, erc20SpenderPrivateKey) = makeAddrAndKey("spender");
    }

    function testSetSymbol_ShouldRevert_IfMethodIsCalledNotByAdmin() public {
        vm.expectRevert("ERC20Ubiquity: not admin");
        dollarToken.setSymbol("ANY_SYMBOL");
    }

    function testSetSymbol_ShouldSetSymbol() public {
        vm.prank(admin);
        dollarToken.setSymbol("ANY_SYMBOL");
        assertEq(dollarToken.symbol(), "ANY_SYMBOL");
    }

    function testPermit_ShouldRevert_IfDeadlineExpired() public {
        // create owner's signature
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                dollarToken.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        erc20Owner,
                        erc20Spender,
                        1 ether,
                        dollarToken.nonces(erc20Owner),
                        0
                    )
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(erc20OwnerPrivateKey, digest);
        // run permit
        vm.prank(erc20Spender);
        vm.expectRevert("ERC20Permit: expired deadline");
        dollarToken.permit(erc20Owner, erc20Spender, 1 ether, 0, v, r, s);
    }

    function testPermit_ShouldRevert_IfSignatureIsInvalid() public {
        // create owner's signature
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                dollarToken.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        erc20Owner,
                        erc20Spender,
                        1 ether,
                        dollarToken.nonces(erc20Owner),
                        block.timestamp + 1 days
                    )
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            erc20SpenderPrivateKey,
            digest
        );
        // run permit
        vm.prank(erc20Spender);
        vm.expectRevert("ERC20Permit: invalid signature");
        dollarToken.permit(
            erc20Owner,
            erc20Spender,
            1 ether,
            block.timestamp + 1 days,
            v,
            r,
            s
        );
    }

    function testPermit_ShouldIncreaseSpenderAllowance() public {
        // create owner's signature
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                dollarToken.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        erc20Owner,
                        erc20Spender,
                        1 ether,
                        dollarToken.nonces(erc20Owner),
                        block.timestamp + 1 days
                    )
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(erc20OwnerPrivateKey, digest);
        // run permit
        uint256 noncesBefore = dollarToken.nonces(erc20Owner);
        vm.prank(erc20Spender);
        dollarToken.permit(
            erc20Owner,
            erc20Spender,
            1 ether,
            block.timestamp + 1 days,
            v,
            r,
            s
        );
        assertEq(dollarToken.allowance(erc20Owner, erc20Spender), 1 ether);
        assertEq(dollarToken.nonces(erc20Owner), noncesBefore + 1);
    }

    function testBurn_ShouldRevert_IfContractIsPaused() public {
        vm.prank(admin);
        dollarToken.pause();
        vm.expectRevert("Pausable: paused");
        dollarToken.burn(50);
    }

    function testBurn_ShouldBurnTokens() public {
        // mint 100 tokens to user
        address mockAddress = makeAddr("user1");
        vm.prank(admin);
        dollarToken.mint(mockAddress, 100);
        assertEq(dollarToken.balanceOf(mockAddress), 100);
        // burn 50 tokens from user
        vm.prank(mockAddress);
        vm.expectEmit(true, true, true, true);
        emit Burning(mockAddress, 50);
        dollarToken.burn(50);
        assertEq(dollarToken.balanceOf(mockAddress), 50);
    }

    function testBurnFrom_ShouldRevert_IfCalledNotByTheBurnerRole() public {
        address mockAddress = makeAddr("user1");
        vm.expectRevert("Dollar token: not burner");
        dollarToken.burnFrom(mockAddress, 50);
    }

    function testBurnFrom_ShouldRevert_IfContractIsPaused() public {
        // mint 100 tokens to user
        address mockAddress = makeAddr("user1");
        vm.prank(admin);
        dollarToken.mint(mockAddress, 100);
        assertEq(dollarToken.balanceOf(mockAddress), 100);
        // create burner role
        address burner = makeAddr("burner");
        vm.prank(admin);
        accessControlFacet.grantRole(
            keccak256("DOLLAR_TOKEN_BURNER_ROLE"),
            burner
        );
        // admin pauses contract
        vm.prank(admin);
        dollarToken.pause();
        // burn 50 tokens for user
        vm.prank(burner);
        vm.expectRevert("Pausable: paused");
        dollarToken.burnFrom(mockAddress, 50);
    }

    function testBurnFrom_ShouldBurnTokensFromAddress() public {
        // mint 100 tokens to user
        address mockAddress = makeAddr("user1");
        vm.prank(admin);
        dollarToken.mint(mockAddress, 100);
        assertEq(dollarToken.balanceOf(mockAddress), 100);
        // create burner role
        address burner = makeAddr("burner");
        vm.prank(admin);
        accessControlFacet.grantRole(
            keccak256("DOLLAR_TOKEN_BURNER_ROLE"),
            burner
        );
        // burn 50 tokens for user
        vm.prank(burner);
        vm.expectEmit(true, true, true, true);
        emit Burning(mockAddress, 50);
        dollarToken.burnFrom(mockAddress, 50);
        assertEq(dollarToken.balanceOf(mockAddress), 50);
    }

    function testMint_ShouldRevert_IfCalledNotByTheMinterRole() public {
        address mockAddress = makeAddr("user1");
        vm.expectRevert("Dollar token: not minter");
        dollarToken.mint(mockAddress, 100);
    }

    function testMint_ShouldRevert_IfContractIsPaused() public {
        vm.startPrank(admin);
        dollarToken.pause();
        address mockAddress = makeAddr("user1");
        vm.expectRevert("Pausable: paused");
        dollarToken.mint(mockAddress, 100);
        vm.stopPrank();
    }

    function testMint_ShouldMintTokens() public {
        address mockAddress = makeAddr("user1");
        uint256 balanceBefore = dollarToken.balanceOf(mockAddress);
        vm.prank(admin);
        vm.expectEmit(true, true, false, true);
        emit Minting(mockAddress, admin, 100);
        dollarToken.mint(mockAddress, 100);
        uint256 balanceAfter = dollarToken.balanceOf(mockAddress);
        assertEq(balanceAfter - balanceBefore, 100);
    }

    function testPause_ShouldRevert_IfCalledNotByThePauserRole() public {
        vm.expectRevert("ERC20Ubiquity: not pauser");
        dollarToken.pause();
    }

    function testPause_ShouldPauseContract() public {
        assertFalse(dollarToken.paused());
        vm.prank(admin);
        dollarToken.pause();
        assertTrue(dollarToken.paused());
    }

    function testUnpause_ShouldRevert_IfCalledNotByThePauserRole() public {
        // admin pauses contract
        vm.prank(admin);
        dollarToken.pause();
        vm.expectRevert("ERC20Ubiquity: not pauser");
        dollarToken.unpause();
    }

    function testUnpause_ShouldUnpauseContract() public {
        vm.startPrank(admin);
        accessControlFacet.pause();
        assertTrue(accessControlFacet.paused());
        accessControlFacet.unpause();
        assertFalse(accessControlFacet.paused());
        vm.stopPrank();
    }

    function testName_ShouldReturnTokenName() public {
        // cspell: disable-next-line
        assertEq(dollarToken.name(), "Ubiquity Dollar");
    }

    function testSymbol_ShouldReturnSymbolName() public {
        // cspell: disable-next-line
        assertEq(dollarToken.symbol(), "uAD");
    }

    function testTransfer_ShouldRevert_IfContractIsPaused() public {
        // admin pauses contract
        vm.prank(admin);
        dollarToken.pause();
        // transfer tokens to user
        address userAddress = makeAddr("user1");
        vm.prank(admin);
        vm.expectRevert("Pausable: paused");
        dollarToken.transfer(userAddress, 10);
    }

    function testTransferFrom_ShouldRevert_IfContractIsPaused() public {
        // transfer tokens to user
        address userAddress = makeAddr("user1");
        address user2Address = makeAddr("user2");
        vm.prank(admin);
        dollarToken.mint(userAddress, 100);
        // admin pauses contract
        vm.prank(admin);
        dollarToken.pause();
        vm.prank(userAddress);
        dollarToken.approve(user2Address, 100);
        vm.expectRevert("Pausable: paused");
        vm.prank(user2Address);
        dollarToken.transferFrom(userAddress, user2Address, 100);

        // admin unpauses contract
        vm.prank(admin);
        dollarToken.unpause();

        // transfer now should work
        vm.prank(user2Address);
        dollarToken.transferFrom(userAddress, user2Address, 100);

        assertEq(dollarToken.balanceOf(userAddress), 0);
        assertEq(dollarToken.balanceOf(user2Address), 100);
    }

    function testTransfer_ShouldTransferTokens() public {
        // mint tokens to admin
        vm.prank(admin);
        dollarToken.mint(admin, 100);
        // transfer tokens to user
        address userAddress = makeAddr("user1");
        assertEq(dollarToken.balanceOf(userAddress), 0);
        vm.prank(admin);
        dollarToken.transfer(userAddress, 10);
        assertEq(dollarToken.balanceOf(userAddress), 10);
    }

    // test transferFrom function should transfer tokens from address
    function testTransferFrom_ShouldTransferTokensFromAddress() public {
        // mint tokens to admin
        vm.prank(admin);
        dollarToken.mint(admin, 100);
        // transfer tokens to user
        address userAddress = makeAddr("user1");
        address user2Address = makeAddr("user2");
        assertEq(dollarToken.balanceOf(userAddress), 0);
        vm.prank(admin);
        dollarToken.transfer(userAddress, 100);
        assertEq(dollarToken.balanceOf(userAddress), 100);
        // approve user2 to transfer tokens from user
        vm.prank(userAddress);
        dollarToken.approve(user2Address, 100);
        // transfer tokens from user to user2
        vm.prank(user2Address);
        dollarToken.transferFrom(userAddress, user2Address, 100);
        assertEq(dollarToken.balanceOf(userAddress), 0);
        assertEq(dollarToken.balanceOf(user2Address), 100);
    }

    // test approve function should approve address to transfer tokens
    function testApprove_ShouldApproveAddressToTransferTokens() public {
        // mint tokens to admin
        vm.prank(admin);
        dollarToken.mint(admin, 100);
        // transfer tokens to user
        address userAddress = makeAddr("user1");
        address user2Address = makeAddr("user2");
        assertEq(dollarToken.balanceOf(userAddress), 0);
        vm.prank(admin);
        dollarToken.transfer(userAddress, 100);
        assertEq(dollarToken.balanceOf(userAddress), 100);
        // approve user2 to transfer tokens from user
        vm.prank(userAddress);
        dollarToken.approve(user2Address, 100);
        // transfer tokens from user to user2
        vm.prank(user2Address);
        dollarToken.transferFrom(userAddress, user2Address, 100);
        assertEq(dollarToken.balanceOf(userAddress), 0);
        assertEq(dollarToken.balanceOf(user2Address), 100);
    }

    // test allowance function should return allowance
    function testAllowance_ShouldReturnAllowance() public {
        // mint tokens to admin
        vm.prank(admin);
        dollarToken.mint(admin, 100);
        // transfer tokens to user
        address userAddress = makeAddr("user1");
        address user2Address = makeAddr("user2");
        assertEq(dollarToken.balanceOf(userAddress), 0);
        vm.prank(admin);
        dollarToken.transfer(userAddress, 100);
        assertEq(dollarToken.balanceOf(userAddress), 100);
        // approve user2 to transfer tokens from user
        vm.prank(userAddress);
        dollarToken.approve(user2Address, 100);
        // transfer tokens from user to user2
        vm.prank(user2Address);
        dollarToken.transferFrom(userAddress, user2Address, 100);
        assertEq(dollarToken.balanceOf(userAddress), 0);
        assertEq(dollarToken.balanceOf(user2Address), 100);
        assertEq(dollarToken.allowance(userAddress, user2Address), 0);
    }
}
