// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "operator-filter-registry/OperatorFilterer.sol";

import "../../src/ubiquistick/UbiquiStick.sol";

contract UbiquiStickHarness is UbiquiStick {
    function exposed_random() public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.prevrandao,
                        block.timestamp,
                        msg.sender,
                        tokenIdNext
                    )
                )
            );
    }

    function exposed_beforeConsecutiveTokenTransfer(
        address address1,
        address address2,
        uint256 value1,
        uint96 value2
    ) public pure {
        _beforeConsecutiveTokenTransfer(address1, address2, value1, value2);
    }
}

contract UbiquiStickTest is Test {
    UbiquiStickHarness ubiquiStick;

    // NFT types
    uint256 public constant STANDARD_TYPE = 0;
    uint256 public constant GOLD_TYPE = 1;
    uint256 public constant INVISIBLE_TYPE = 2;

    // mint frequency of gold type tokens
    uint256 public constant GOLD_FREQ = 64;

    // test users
    address minter;
    address user;

    function setUp() public {
        minter = address(0x01);
        user = address(0x02);

        vm.prank(minter);
        ubiquiStick = new UbiquiStickHarness();
    }

    function testConstructor_ShouldInitContract() public {
        assertEq(ubiquiStick.minter(), minter);
    }

    function testTokenURI_ShouldRevert_IfTokenDoesNotExist() public {
        vm.expectRevert("Nonexistent token");
        ubiquiStick.tokenURI(0);
    }

    function testTokenURI_ShouldReturnTokenURIForTokenTypeGold() public {
        // set gold token URI
        vm.startPrank(minter);
        ubiquiStick.setTokenURI(GOLD_TYPE, "TOKEN_URI_GOLD");
        // mint gold token
        // mint 57 tokens to user (needed for random() to return a gold type)
        for (uint i = 1; i <= 57; i++) {
            ubiquiStick.safeMint(user);
        }
        // with the default "block.prevrandao = 0" the 58th token is gold
        ubiquiStick.safeMint(user);

        assertEq(ubiquiStick.tokenURI(58), "TOKEN_URI_GOLD");

        vm.stopPrank();
    }

    function testTokenURI_ShouldReturnTokenURIForTokenTypeInvisible() public {
        // set invisible token URI
        vm.prank(minter);
        ubiquiStick.setTokenURI(INVISIBLE_TYPE, "TOKEN_URI_INVISIBLE");
        // mint 42 tokens, token with id 42 is invisible
        for (uint256 i = 1; i <= 42; i++) {
            vm.prank(minter);
            ubiquiStick.safeMint(user);
        }

        assertEq(ubiquiStick.tokenURI(42), "TOKEN_URI_INVISIBLE");
    }

    function testTokenURI_ShouldReturnTokenURIForTokenTypeStandard() public {
        // set invisible token URI
        vm.prank(minter);
        ubiquiStick.setTokenURI(STANDARD_TYPE, "TOKEN_URI_STANDARD");
        // mint 1 token
        vm.prank(minter);
        ubiquiStick.safeMint(user);

        assertEq(ubiquiStick.tokenURI(1), "TOKEN_URI_STANDARD");
    }

    function testSetTokenURI_ShouldRevert_IfCalledNotByMinter() public {
        vm.prank(user);
        vm.expectRevert("Not minter");
        ubiquiStick.setTokenURI(STANDARD_TYPE, "TOKEN_URI");
    }

    function testSetMinter_ShouldRevert_IfCalledNotByOwner() public {
        vm.prank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        ubiquiStick.setMinter(user);
    }

    function testSetMinter_ShouldUpdateMinter() public {
        address newMinter = address(0x03);
        vm.prank(minter);
        ubiquiStick.setMinter(newMinter);
        assertEq(ubiquiStick.minter(), newMinter);
    }

    function testSafeMint_ShouldRevert_IfCalledNotByMinter() public {
        vm.prank(user);
        vm.expectRevert("Not minter");
        ubiquiStick.safeMint(user);
    }

    function testSafeMint_ShouldMint() public {
        vm.prank(minter);
        ubiquiStick.safeMint(user);
        assertEq(ubiquiStick.tokenIdNext(), 2);
        assertEq(ubiquiStick.ownerOf(1), user);
    }

    function testSafeMint_ShouldMintGoldToken() public {
        vm.startPrank(minter);
        // mint 57 tokens to user (needed for random() to return a gold type)
        for (uint i = 1; i <= 57; i++) {
            ubiquiStick.safeMint(user);
        }
        // with the default "block.prevrandao = 0" the 58th token is gold
        ubiquiStick.safeMint(user);
        assertEq(ubiquiStick.ownerOf(58), user);
        assertEq(ubiquiStick.gold(58), true);

        vm.stopPrank();
    }

    function testBatchSafeMint_ShouldRevert_IfCalledNotByMinter() public {
        vm.prank(user);
        vm.expectRevert("Not minter");
        ubiquiStick.batchSafeMint(user, 2);
    }

    function testBatchSafeMint_ShouldMintMultipleTokens() public {
        vm.prank(minter);
        ubiquiStick.batchSafeMint(user, 2);
        assertEq(ubiquiStick.ownerOf(1), user);
        assertEq(ubiquiStick.ownerOf(2), user);
    }

    function testRandom_ShouldReturnRandomValue() public {
        // by default "block.prevrandao = 0"
        assertEq(
            ubiquiStick.exposed_random(),
            59314673252666873280629439252894990696031209845167399747113266702537979136323
        );
    }

    function testBeforeConsecutiveTokenTransfer_ShouldRevert() public {
        vm.expectRevert(
            "ERC721Enumerable: consecutive transfers not supported"
        );
        ubiquiStick.exposed_beforeConsecutiveTokenTransfer(
            address(0),
            address(0),
            0,
            0
        );
    }

    function testSupportsInterface_ShouldReturnTrue_IfInterfaceIsSupported()
        public
    {
        assertEq(
            ubiquiStick.supportsInterface(type(IERC721).interfaceId),
            true
        );
    }

    function testSupportsInterface_ShouldReturnFalse_IfInterfaceIsNotSupported()
        public
    {
        assertEq(ubiquiStick.supportsInterface(bytes4(0x00000000)), false);
    }

    function testSetApprovalForAll_ShouldRevert_IfOperatorIsNotAllowed()
        public
    {
        // mock OperatorFilterer
        vm.mockCall(
            address(ubiquiStick.OPERATOR_FILTER_REGISTRY()),
            abi.encodeWithSelector(
                IOperatorFilterRegistry.isOperatorAllowed.selector
            ),
            abi.encode(false)
        );
        // mint 1 token to minter
        vm.prank(minter);
        ubiquiStick.safeMint(minter);
        // minter approves user to spend his tokens
        vm.prank(minter);
        vm.expectRevert(
            abi.encodeWithSelector(
                OperatorFilterer.OperatorNotAllowed.selector,
                user
            )
        );
        ubiquiStick.setApprovalForAll(user, true);
    }

    function testSetApprovalForAll_ShouldApproveOperatorToSpendAllTokens()
        public
    {
        // mint 1 token to minter
        vm.prank(minter);
        ubiquiStick.safeMint(minter);
        // minter approves user to spend his tokens
        vm.prank(minter);
        ubiquiStick.setApprovalForAll(user, true);

        assertEq(ubiquiStick.isApprovedForAll(minter, user), true);
    }

    function testApprove_ShouldRevert_IfOperatorIsNotAllowed() public {
        // mock OperatorFilterer
        vm.mockCall(
            address(ubiquiStick.OPERATOR_FILTER_REGISTRY()),
            abi.encodeWithSelector(
                IOperatorFilterRegistry.isOperatorAllowed.selector
            ),
            abi.encode(false)
        );

        vm.prank(minter);
        vm.expectRevert(
            abi.encodeWithSelector(
                OperatorFilterer.OperatorNotAllowed.selector,
                user
            )
        );
        ubiquiStick.approve(user, 1);
    }

    function testApprove_ShouldApprove() public {
        // mint 1 token to minter
        vm.prank(minter);
        ubiquiStick.safeMint(minter);

        vm.prank(minter);
        ubiquiStick.approve(user, 1);
        assertEq(ubiquiStick.getApproved(1), user);
    }

    function testTransferFrom_ShouldRevert_IfOperatorIsNotAllowed() public {
        // mint 1 token to minter
        vm.prank(minter);
        ubiquiStick.safeMint(minter);
        // approve user to spend minter's token 1
        vm.prank(minter);
        ubiquiStick.approve(user, 1);
        // mock OperatorFilterer
        vm.mockCall(
            address(ubiquiStick.OPERATOR_FILTER_REGISTRY()),
            abi.encodeWithSelector(
                IOperatorFilterRegistry.isOperatorAllowed.selector
            ),
            abi.encode(false)
        );

        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                OperatorFilterer.OperatorNotAllowed.selector,
                user
            )
        );
        ubiquiStick.transferFrom(minter, user, 1);
    }

    function testTransferFrom_ShouldTransferToken() public {
        // mint 1 token to minter
        vm.prank(minter);
        ubiquiStick.safeMint(minter);
        // approve user to spend minter's token 1
        vm.prank(minter);
        ubiquiStick.approve(user, 1);

        vm.prank(user);
        ubiquiStick.transferFrom(minter, user, 1);
        assertEq(ubiquiStick.ownerOf(1), user);
    }

    function testSafeTransferFrom_ShouldRevert_IfOperatorIsNotAllowed() public {
        // mint 1 token to minter
        vm.prank(minter);
        ubiquiStick.safeMint(minter);
        // approve user to spend minter's token 1
        vm.prank(minter);
        ubiquiStick.approve(user, 1);
        // mock OperatorFilterer
        vm.mockCall(
            address(ubiquiStick.OPERATOR_FILTER_REGISTRY()),
            abi.encodeWithSelector(
                IOperatorFilterRegistry.isOperatorAllowed.selector
            ),
            abi.encode(false)
        );

        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                OperatorFilterer.OperatorNotAllowed.selector,
                user
            )
        );
        ubiquiStick.safeTransferFrom(minter, user, 1);
    }

    function testSafeTransferFrom_ShouldTransferToken() public {
        // mint 1 token to minter
        vm.prank(minter);
        ubiquiStick.safeMint(minter);
        // approve user to spend minter's token 1
        vm.prank(minter);
        ubiquiStick.approve(user, 1);

        vm.prank(user);
        ubiquiStick.safeTransferFrom(minter, user, 1);
        assertEq(ubiquiStick.ownerOf(1), user);
    }

    function testSafeTransferFromWith4Params_ShouldRevert_IfOperatorIsNotAllowed()
        public
    {
        // mint 1 token to minter
        vm.prank(minter);
        ubiquiStick.safeMint(minter);
        // approve user to spend minter's token 1
        vm.prank(minter);
        ubiquiStick.approve(user, 1);
        // mock OperatorFilterer
        vm.mockCall(
            address(ubiquiStick.OPERATOR_FILTER_REGISTRY()),
            abi.encodeWithSelector(
                IOperatorFilterRegistry.isOperatorAllowed.selector
            ),
            abi.encode(false)
        );

        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                OperatorFilterer.OperatorNotAllowed.selector,
                user
            )
        );
        ubiquiStick.safeTransferFrom(minter, user, 1, "");
    }

    function testSafeTransferFromWith4Params_ShouldTransferToken() public {
        // mint 1 token to minter
        vm.prank(minter);
        ubiquiStick.safeMint(minter);
        // approve user to spend minter's token 1
        vm.prank(minter);
        ubiquiStick.approve(user, 1);

        vm.prank(user);
        ubiquiStick.safeTransferFrom(minter, user, 1, "");
        assertEq(ubiquiStick.ownerOf(1), user);
    }
}
