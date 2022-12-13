// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {ERC20Ubiquity} from "../../src/dollar/ERC20Ubiquity.sol";
import {UbiquityDollarManager} from
    "../../src/dollar/core/UbiquityDollarManager.sol";
import "../helpers/LocalTestHelper.sol";

contract ERC20UbiquityHarness is ERC20Ubiquity {
    constructor(address _manager, string memory name_, string memory symbol_)
        ERC20Ubiquity(_manager, name_, symbol_)
    {}

    function exposed_transfer(address sender, address recipient, uint256 amount) external {
        _transfer(sender, recipient, amount);
    }
}

contract ERC20UbiquityTest is LocalTestHelper {
    address token_addr;
    address dollar_manager_addr;

    event Minting(
        address indexed mock_addr1, address indexed _minter, uint256 _amount
    );

    event Burning(address indexed _burned, uint256 _amount);

    function setUp() public {
        dollar_manager_addr = helpers_deployUbiquityDollarManager();
        vm.prank(admin);
        token_addr =
            address(new ERC20Ubiquity(dollar_manager_addr, "Test", "Test"));
    }

    function testConstructor_ShouldRevert_IfSenderIsNotAdmin() public {
        vm.prank(address(0x1));
        vm.expectRevert("ERC20: deployer must be manager admin");
        new ERC20Ubiquity(dollar_manager_addr, "Test", "Test");
    }

    function testConstructor_ShouldSetConstructorParams() public {
        assertEq(ERC20Ubiquity(token_addr).name(), "Test");
        assertEq(ERC20Ubiquity(token_addr).symbol(), "Test");
        assertEq(address(ERC20Ubiquity(token_addr).manager()), dollar_manager_addr);
    }

    function testSetSymbol_ShouldRevert_IfMethodIsCalledNotByAdmin() public {
        vm.expectRevert("ERC20: deployer must be manager admin");
        ERC20Ubiquity(token_addr).setSymbol("ANY_SYMBOL");
    }

    function testSetSymbol_ShouldSetSymbol() public {
        vm.prank(admin);
        ERC20Ubiquity(token_addr).setSymbol("ANY_SYMBOL");
        assertEq(ERC20Ubiquity(token_addr).symbol(), "ANY_SYMBOL");
    }

    function testSetName_ShouldRevert_IfMethodIsCalledNotByAdmin() public {
        vm.expectRevert("ERC20: deployer must be manager admin");
        ERC20Ubiquity(token_addr).setName("ANY_NAME");
    }

    function testSetName_ShouldSetName() public {
        vm.prank(admin);
        ERC20Ubiquity(token_addr).setName("ANY_NAME");
        assertEq(ERC20Ubiquity(token_addr).name(), "ANY_NAME");
    }

    function testPermit_ShouldRevert_IfDeadlineExpired() public {
        // create owner and spender addresses
        uint ownerPrivateKey = 0x1;
        uint spenderPrivateKey = 0x2;
        address owner = vm.addr(ownerPrivateKey);
        address spender = vm.addr(spenderPrivateKey);
        // create owner's signature
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                ERC20Ubiquity(token_addr).DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        ERC20Ubiquity(token_addr).PERMIT_TYPEHASH(),
                        owner,
                        spender,
                        1e18,
                        ERC20Ubiquity(token_addr).nonces(owner),
                        0
                    )
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        // run permit
        vm.prank(spender);
        vm.expectRevert("Dollar: EXPIRED");
        ERC20Ubiquity(token_addr).permit(
            owner,
            spender,
            1e18,
            0,
            v,
            r,
            s
        );
    }

    function testPermit_ShouldRevert_IfSignatureIsInvalid() public {
        // create owner and spender addresses
        uint ownerPrivateKey = 0x1;
        uint spenderPrivateKey = 0x2;
        address owner = vm.addr(ownerPrivateKey);
        address spender = vm.addr(spenderPrivateKey);
        // create owner's signature
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                ERC20Ubiquity(token_addr).DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        ERC20Ubiquity(token_addr).PERMIT_TYPEHASH(),
                        owner,
                        spender,
                        1e18,
                        ERC20Ubiquity(token_addr).nonces(owner),
                        block.timestamp + 1 days
                    )
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(spenderPrivateKey, digest);
        // run permit
        vm.prank(spender);
        vm.expectRevert("Dollar: INVALID_SIGNATURE");
        ERC20Ubiquity(token_addr).permit(
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
        uint ownerPrivateKey = 0x1;
        uint spenderPrivateKey = 0x2;
        address owner = vm.addr(ownerPrivateKey);
        address spender = vm.addr(spenderPrivateKey);
        // create owner's signature
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                ERC20Ubiquity(token_addr).DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        ERC20Ubiquity(token_addr).PERMIT_TYPEHASH(),
                        owner,
                        spender,
                        1e18,
                        ERC20Ubiquity(token_addr).nonces(owner),
                        block.timestamp + 1 days
                    )
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        // run permit
        uint noncesBefore = ERC20Ubiquity(token_addr).nonces(owner);
        vm.prank(spender);
        ERC20Ubiquity(token_addr).permit(
            owner,
            spender,
            1e18,
            block.timestamp + 1 days,
            v,
            r,
            s
        );
        assertEq(ERC20Ubiquity(token_addr).allowance(owner, spender), 1e18);
        assertEq(ERC20Ubiquity(token_addr).nonces(owner), noncesBefore + 1);
    }

    function testBurn_ShouldRevert_IfContractIsPaused() public {
        vm.prank(admin);
        ERC20Ubiquity(token_addr).pause();
        vm.expectRevert("Pausable: paused");
        ERC20Ubiquity(token_addr).burn(50);
    }

    function testBurn_ShouldBurnTokens() public {
        // mint 100 tokens to user
        address mockAddress = address(0x1);
        vm.prank(admin);
        ERC20Ubiquity(token_addr).mint(mockAddress, 100);
        assertEq(ERC20Ubiquity(token_addr).balanceOf(mockAddress), 100);
        // burn 50 tokens from user
        vm.prank(mockAddress);
        vm.expectEmit(true, true, true, true);
        emit Burning(mockAddress, 50);
        ERC20Ubiquity(token_addr).burn(50);
        assertEq(ERC20Ubiquity(token_addr).balanceOf(mockAddress), 50);
    }

    function testBurnFrom_ShouldRevert_IfCalledNotByTheBurnerRole() public {
        address mockAddress = address(0x1);
        vm.expectRevert("Governance token: not burner");
        ERC20Ubiquity(token_addr).burnFrom(mockAddress, 50);
    }

    function testBurnFrom_ShouldRevert_IfContractIsPaused() public {
        // mint 100 tokens to user
        address mockAddress = address(0x1);
        vm.prank(admin);
        ERC20Ubiquity(token_addr).mint(mockAddress, 100);
        assertEq(ERC20Ubiquity(token_addr).balanceOf(mockAddress), 100);
        // create burner role
        address burner = address(0x2);
        vm.prank(admin);
        UbiquityDollarManager(dollar_manager_addr).grantRole(
            keccak256("GOVERNANCE_TOKEN_BURNER_ROLE"), burner
        );
        // admin pauses contract
        vm.prank(admin);
        ERC20Ubiquity(token_addr).pause();
        // burn 50 tokens for user
        vm.prank(burner);
        vm.expectRevert("Pausable: paused");
        ERC20Ubiquity(token_addr).burnFrom(mockAddress, 50);
    }

    function testBurnFrom_ShouldBurnTokensFromAddress() public {
        // mint 100 tokens to user
        address mockAddress = address(0x1);
        vm.prank(admin);
        ERC20Ubiquity(token_addr).mint(mockAddress, 100);
        assertEq(ERC20Ubiquity(token_addr).balanceOf(mockAddress), 100);
        // create burner role
        address burner = address(0x2);
        vm.prank(admin);
        UbiquityDollarManager(dollar_manager_addr).grantRole(
            keccak256("GOVERNANCE_TOKEN_BURNER_ROLE"), burner
        );
        // burn 50 tokens for user
        vm.prank(burner);
        vm.expectEmit(true, true, true, true);
        emit Burning(mockAddress, 50);
        ERC20Ubiquity(token_addr).burnFrom(mockAddress, 50);
        assertEq(ERC20Ubiquity(token_addr).balanceOf(mockAddress), 50);
    }

    function testMint_ShouldRevert_IfCalledNotByTheMinterRole() public {
        address mockAddress = address(0x1);
        vm.expectRevert("Governance token: not minter");
        ERC20Ubiquity(token_addr).mint(mockAddress, 100);
    }

    function testMint_ShouldRevert_IfContractIsPaused() public {
        vm.startPrank(admin);
        ERC20Ubiquity(token_addr).pause();
        address mockAddress = address(0x1);
        vm.expectRevert("Pausable: paused");
        ERC20Ubiquity(token_addr).mint(mockAddress, 100);
        vm.stopPrank();
    }

    function testMint_ShouldMintTokens() public {
        address mockAddress = address(0x1);
        uint balanceBefore = ERC20Ubiquity(token_addr).balanceOf(mockAddress);
        vm.prank(admin);
        vm.expectEmit(true, true, false, true);
        emit Minting(mockAddress, admin, 100);
        ERC20Ubiquity(token_addr).mint(mockAddress, 100);
        uint256 balanceAfter = ERC20Ubiquity(token_addr).balanceOf(mockAddress);
        assertEq(balanceAfter - balanceBefore, 100);
    }

    function testPause_ShouldRevert_IfCalledNotByThePauserRole() public {
        vm.expectRevert("Governance token: not pauser");
        ERC20Ubiquity(token_addr).pause();
    }

    function testPause_ShouldPauseContract() public {
        assertFalse(ERC20Ubiquity(token_addr).paused());
        vm.prank(admin);
        ERC20Ubiquity(token_addr).pause();
        assertTrue(ERC20Ubiquity(token_addr).paused());
    }

    function testUnpause_ShouldRevert_IfCalledNotByThePauserRole() public {
        vm.expectRevert("Governance token: not pauser");
        ERC20Ubiquity(token_addr).unpause();
    }

    function testUnpause_ShouldUnpauseContract() public {
        vm.startPrank(admin);
        ERC20Ubiquity(token_addr).pause();
        assertTrue(ERC20Ubiquity(token_addr).paused());
        ERC20Ubiquity(token_addr).unpause();
        assertFalse(ERC20Ubiquity(token_addr).paused());
        vm.stopPrank();
    }

    function testName_ShouldReturnTokenName() public {
        assertEq(ERC20Ubiquity(token_addr).name(), "Test");
    }

    function testSymbol_ShouldReturnSymbolName() public {
        assertEq(ERC20Ubiquity(token_addr).symbol(), "Test");
    }

    function testTransfer_ShouldRevert_IfContractIsPaused() public {
        // deploy contract with exposed internal methods
        vm.prank(admin);
        ERC20UbiquityHarness erc20Ubiquity = new ERC20UbiquityHarness(dollar_manager_addr, "Test", "Test");
        // admin pauses contract
        vm.prank(admin);
        erc20Ubiquity.pause();
        // transfer tokens to user
        address userAddress = address(0x1);
        vm.prank(admin);
        vm.expectRevert("Pausable: paused");
        erc20Ubiquity.exposed_transfer(admin, userAddress, 10);
    }

    function testTransfer_ShouldTransferTokens() public {
        // deploy contract with exposed internal methods
        vm.prank(admin);
        ERC20UbiquityHarness erc20Ubiquity = new ERC20UbiquityHarness(dollar_manager_addr, "Test", "Test");
        // mint tokens to admin
        vm.prank(admin);
        erc20Ubiquity.mint(admin, 100);
        // transfer tokens to user
        address userAddress = address(0x1);
        assertEq(erc20Ubiquity.balanceOf(userAddress), 0);
        vm.prank(admin);
        erc20Ubiquity.exposed_transfer(admin, userAddress, 10);
        assertEq(erc20Ubiquity.balanceOf(userAddress), 10);
    }
}