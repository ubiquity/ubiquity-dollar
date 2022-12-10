// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../../src/dollar/DirectGovernanceFarmer.sol";
import "../../src/dollar/mocks/MockERC20.sol";
import "../helpers/LocalTestHelper.sol";
import {ERC20Ubiquity} from "../../src/dollar/ERC20Ubiquity.sol";

contract DirectGovernanceFarmerHarness is DirectGovernanceFarmer {
    constructor(
        address _manager,
        address base3Pool,
        address depositZap
    ) DirectGovernanceFarmer(_manager, base3Pool, depositZap) {}

    function exposed_isIdIncluded(uint256[] memory idList, uint256 id)
        external
        pure
        returns (bool)
    {
        return isIdIncluded(idList, id);
    }
}

contract DirectGovernanceFarmerTest is LocalTestHelper {
    // DAI
    MockERC20 token0;
    // USDC
    MockERC20 token1;
    // USDT
    MockERC20 token2;

    ERC20Ubiquity dollar;

    DirectGovernanceFarmer directGovernanceFarmer;
    MockERC20 stableSwapMetaPool;
    address dollarManagerAddress;
    address depositZapAddress = address(0x4);
    address base3PoolAddress = address(0x5);
    event Deposit(
        address indexed sender,
        address token,
        uint256 amount,
        uint256 durationWeeks,
        uint256 stakingShareId
    );
    event DepositMultiple(
        address indexed sender,
        uint256[4] amount,
        uint256 durationWeeks,
        uint256 stakingShareId
    );
    event WithdrawAll(
        address indexed sender,
        uint256 stakingShareId,
        uint256[4] amounts
    );

    function setUp() public {
        dollarManagerAddress = helpers_deployUbiquityDollarManager();
        dollar = ERC20Ubiquity(
            UbiquityDollarManager(dollarManagerAddress).dollarTokenAddress()
        );
        // deploy mocked tokens
        token0 = new MockERC20("DAI", "DAI", 18);
        token1 = new MockERC20("USDC", "USDC", 6);
        token2 = new MockERC20("USDT", "USDT", 6);
        // deploy stable swap meta pool
        stableSwapMetaPool = new MockERC20(
            "Stable swap meta pool token",
            "Stable swap meta pool token",
            18
        );
        vm.prank(admin);
        IUbiquityDollarManager(dollarManagerAddress)
            .setStableSwapMetaPoolAddress(address(stableSwapMetaPool));
        // mock base3Pool to return mocked token addresses
        vm.mockCall(
            base3PoolAddress,
            abi.encodeWithSelector(IStableSwap3Pool.coins.selector, 0),
            abi.encode(token0)
        );
        vm.mockCall(
            base3PoolAddress,
            abi.encodeWithSelector(IStableSwap3Pool.coins.selector, 1),
            abi.encode(token1)
        );
        vm.mockCall(
            base3PoolAddress,
            abi.encodeWithSelector(IStableSwap3Pool.coins.selector, 2),
            abi.encode(token2)
        );
        // create direct governance farmer contract instance
        directGovernanceFarmer = new DirectGovernanceFarmer(
            dollarManagerAddress,
            base3PoolAddress,
            depositZapAddress
        );
    }

    function testConstructor_ShouldInitContract() public {
        assertEq(
            address(directGovernanceFarmer.manager()),
            dollarManagerAddress
        );
        assertEq(
            directGovernanceFarmer.ubiquity3PoolLP(),
            address(stableSwapMetaPool)
        );
        assertEq(
            directGovernanceFarmer.ubiquityDollar(),
            IUbiquityDollarManager(dollarManagerAddress).dollarTokenAddress()
        );
        assertEq(
            directGovernanceFarmer.depositZapUbiquityDollar(),
            depositZapAddress
        );
        assertEq(directGovernanceFarmer.token0(), address(token0));
        assertEq(directGovernanceFarmer.token1(), address(token1));
        assertEq(directGovernanceFarmer.token2(), address(token2));
    }

    function testOnERC1155Received_ShouldReturnSelector() public {
        assertEq(
            directGovernanceFarmer.onERC1155Received(
                address(0x1),
                address(0x2),
                3,
                4,
                ""
            ),
            DirectGovernanceFarmer.onERC1155Received.selector
        );
    }

    function testDeposit_ShouldRevert_IfTokenIsNotInMetapool() public {
        address userAddress = address(0x100);
        vm.prank(userAddress);
        vm.expectRevert(
            "Invalid token: must be DAI, USD Coin, Tether, or Ubiquity Dollar"
        );
        directGovernanceFarmer.deposit(address(0), 1, 1);
    }

    function testDeposit_ShouldRevert_IfAmountIsNotPositive() public {
        address userAddress = address(0x100);
        vm.prank(userAddress);
        vm.expectRevert("amount must be positive vale");
        directGovernanceFarmer.deposit(address(token0), 0, 1);
    }

    function testDeposit_ShouldRevert_IfDurationIsNotValid() public {
        address userAddress = address(0x100);
        vm.prank(userAddress);
        vm.expectRevert("duration weeks must be between 1 and 208");
        directGovernanceFarmer.deposit(address(token0), 1, 0);
    }

    function testDeposit_ShouldDepositTokens() public {
        address userAddress = address(0x100);
        address stakingAddress = address(0x101);
        address stakingShareAddress = address(0x102);

        // admin sets staking and staking share addresses
        vm.startPrank(admin);
        IUbiquityDollarManager(dollarManagerAddress).setStakingContractAddress(
            stakingAddress
        );
        IUbiquityDollarManager(dollarManagerAddress).setStakingShareAddress(
            stakingShareAddress
        );
        vm.stopPrank();

        vm.startPrank(userAddress);

        // mint 100 DAI to user
        token0.mint(userAddress, 100e18);
        // user allows DirectGovernanceFarmerHarness to spend user's DAI
        token0.approve(address(directGovernanceFarmer), 100e18);

        // prepare mocks
        vm.mockCall(
            depositZapAddress,
            abi.encodeWithSelector(IDepositZap.add_liquidity.selector),
            abi.encode(100e18)
        );
        vm.mockCall(
            stakingAddress,
            abi.encodeWithSelector(IStaking.deposit.selector),
            abi.encode(1)
        );
        vm.mockCall(
            stakingShareAddress,
            abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256,uint256,bytes)",
                address(directGovernanceFarmer),
                userAddress,
                1,
                1,
                "0x"
            ),
            ""
        );

        vm.expectEmit(true, true, true, true, address(directGovernanceFarmer));
        emit Deposit(userAddress, address(token0), uint256(100e18), 1, 1);
        // user deposits 100 DAI for 1 week
        uint256 stakingShareId = directGovernanceFarmer.deposit(
            address(token0),
            100e18,
            1
        );
        assertEq(stakingShareId, 1);
    }

    // Multiple
    function testDeposit_Multiple_Tokens_ShouldRevert_IfAmountsIsNotPositive()
        public
    {
        address userAddress = address(0x100);
        vm.prank(userAddress);
        vm.expectRevert("amounts==0");
        // uint256[4] calldata amounts = ;
        directGovernanceFarmer.deposit(
            [uint256(0), uint256(0), uint256(0), uint256(0)],
            1
        );
    }

    function testDeposit_Multiple_Tokens_ShouldRevert_IfDurationIsNotValid()
        public
    {
        address userAddress = address(0x100);
        vm.prank(userAddress);
        vm.expectRevert("duration weeks must be between 1 and 208");
        directGovernanceFarmer.deposit(
            [uint256(1), uint256(0), uint256(0), uint256(0)],
            0
        );
    }

    function testDeposit_Multiple_Tokens_ShouldDepositTokens() public {
        address userAddress = address(0x100);
        address stakingAddress = address(0x101);
        address stakingShareAddress = address(0x102);

        // admin sets staking and staking share addresses
        vm.startPrank(admin);
        IUbiquityDollarManager(dollarManagerAddress).setStakingContractAddress(
            stakingAddress
        );
        IUbiquityDollarManager(dollarManagerAddress).setStakingShareAddress(
            stakingShareAddress
        );
        vm.stopPrank();

        vm.startPrank(userAddress);

        // mint 100 uAD to user
        dollar.mint(userAddress, 100e18);
        // user allows DirectGovernanceFarmerHarness to spend user's uAD
        dollar.approve(address(directGovernanceFarmer), 100e18);
        assertEq(dollar.balanceOf(userAddress), 100e18);
        // mint 100 DAI to user
        token0.mint(userAddress, 99e18);
        // user allows DirectGovernanceFarmerHarness to spend user's DAI
        token0.approve(address(directGovernanceFarmer), 99e18);
        assertEq(token0.balanceOf(userAddress), 99e18);
        // mint 100 USDC to user
        token1.mint(userAddress, 98e18);
        // user allows DirectGovernanceFarmerHarness to spend user's USDC
        token1.approve(address(directGovernanceFarmer), 98e18);
        assertEq(token1.balanceOf(userAddress), 98e18);
        // mint 100 USDT to user
        token2.mint(userAddress, 97e18);
        // user allows DirectGovernanceFarmerHarness to spend user's USDT
        token2.approve(address(directGovernanceFarmer), 97e18);
        assertEq(token2.balanceOf(userAddress), 97e18);

        // prepare mocks
        vm.mockCall(
            depositZapAddress,
            abi.encodeWithSelector(
                IDepositZap.add_liquidity.selector,
                address(stableSwapMetaPool),
                [
                    uint256(100e18),
                    uint256(99e18),
                    uint256(98e18),
                    uint256(97e18)
                ],
                0
            ),
            abi.encode(42e18)
        );
        vm.mockCall(
            stakingAddress,
            abi.encodeWithSelector(IStaking.deposit.selector, 42e18, 8),
            abi.encode(12)
        );
        vm.mockCall(
            stakingShareAddress,
            abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256,uint256,bytes)",
                address(directGovernanceFarmer),
                userAddress,
                12,
                1,
                "0x"
            ),
            ""
        );

        vm.expectEmit(true, true, true, true, address(directGovernanceFarmer));
        emit DepositMultiple(
            userAddress,
            [uint256(100e18), uint256(99e18), uint256(98e18), uint256(97e18)],
            8,
            12
        );

        // user deposits 100 uAD 99 DAI 98 USDC 97 USDT
        uint256 stakingShareId = directGovernanceFarmer.deposit(
            [uint256(100e18), uint256(99e18), uint256(98e18), uint256(97e18)],
            8
        );
        assertEq(stakingShareId, 12);
        assertEq(dollar.balanceOf(userAddress), 0);
        assertEq(token0.balanceOf(userAddress), 0);
        assertEq(token1.balanceOf(userAddress), 0);
        assertEq(token2.balanceOf(userAddress), 0);
    }

    function testWithdraw__Multiple_ShouldRevert_IfSenderIsNotBondOwner()
        public
    {
        address userAddress = address(0x100);
        address stakingShareAddress = address(0x102);

        // admin sets staking share addresses
        vm.prank(admin);
        IUbiquityDollarManager(dollarManagerAddress).setStakingShareAddress(
            stakingShareAddress
        );

        vm.mockCall(
            stakingShareAddress,
            abi.encodeWithSelector(IERC1155Ubiquity.holderTokens.selector),
            abi.encode([0])
        );

        vm.prank(userAddress);
        vm.expectRevert("!bond owner");
        directGovernanceFarmer.withdraw(1);
    }

    function testWithdraw_Multiple_ShouldWithdraw() public {
        address userAddress = address(0x100);
        address stakingAddress = address(0x101);
        address stakingShareAddress = address(0x102);

        // admin sets staking and staking share addresses
        vm.startPrank(admin);
        IUbiquityDollarManager(dollarManagerAddress).setStakingContractAddress(
            stakingAddress
        );
        IUbiquityDollarManager(dollarManagerAddress).setStakingShareAddress(
            stakingShareAddress
        );
        vm.stopPrank();

        vm.startPrank(userAddress);

        // mint 100 uAD to user
        dollar.mint(userAddress, 100e18);
        // user allows DirectGovernanceFarmerHarness to spend user's uAD
        dollar.approve(address(directGovernanceFarmer), 100e18);
        assertEq(dollar.balanceOf(userAddress), 100e18);
        // mint 100 DAI to user
        token0.mint(userAddress, 99e18);
        // user allows DirectGovernanceFarmerHarness to spend user's DAI
        token0.approve(address(directGovernanceFarmer), 99e18);
        assertEq(token0.balanceOf(userAddress), 99e18);
        // mint 100 USDC to user
        token1.mint(userAddress, 98e18);
        // user allows DirectGovernanceFarmerHarness to spend user's USDC
        token1.approve(address(directGovernanceFarmer), 98e18);
        assertEq(token1.balanceOf(userAddress), 98e18);
        // mint 100 USDT to user
        token2.mint(userAddress, 97e18);
        // user allows DirectGovernanceFarmerHarness to spend user's USDT
        token2.approve(address(directGovernanceFarmer), 97e18);
        assertEq(token2.balanceOf(userAddress), 97e18);

        // prepare mocks for deposit
        vm.mockCall(
            depositZapAddress,
            abi.encodeWithSelector(IDepositZap.add_liquidity.selector),
            abi.encode(100e18)
        );
        vm.mockCall(
            stakingAddress,
            abi.encodeWithSelector(IStaking.deposit.selector),
            abi.encode(1)
        );
        vm.mockCall(
            stakingShareAddress,
            abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256,uint256,bytes)",
                address(directGovernanceFarmer),
                userAddress,
                1,
                1,
                "0x"
            ),
            ""
        );

        // user deposits 100 uAD, 99 DAI 98 USDC 97 USDT for 1 week
        directGovernanceFarmer.deposit(
            [uint256(100e18), uint256(99e18), uint256(98e18), uint256(97e18)],
            1
        );

        // wait 1 week + 1 day
        vm.warp(block.timestamp + 8 days);

        // prepare mocks for withdraw
        uint256[] memory stakingShareIds = new uint256[](1);
        stakingShareIds[0] = 1;
        vm.mockCall(
            stakingShareAddress,
            abi.encodeWithSelector(IERC1155Ubiquity.holderTokens.selector),
            abi.encode(stakingShareIds)
        );

        IStakingShare.Stake memory stake;
        stake.lpAmount = 100e18;
        vm.mockCall(
            stakingShareAddress,
            abi.encodeWithSelector(IStakingShare.getStake.selector),
            abi.encode(stake)
        );

        vm.mockCall(
            depositZapAddress,
            abi.encodeWithSelector(IDepositZap.remove_liquidity.selector),
            abi.encode([100e18, 99e18, 98e18, 97e18])
        );
        vm.expectEmit(true, true, true, true, address(directGovernanceFarmer));
        emit WithdrawAll(
            userAddress,
            1,
            [uint256(100e18), uint256(99e18), uint256(98e18), uint256(97e18)]
        );
        uint256[4] memory tokenAmounts = directGovernanceFarmer.withdraw(1);
        assertEq(tokenAmounts[0], 100e18);
        assertEq(tokenAmounts[1], 99e18);
        assertEq(tokenAmounts[2], 98e18);
        assertEq(tokenAmounts[3], 97e18);
        assertEq(dollar.balanceOf(userAddress), 100e18);
        assertEq(token0.balanceOf(userAddress), 99e18);
        assertEq(token1.balanceOf(userAddress), 98e18);
        assertEq(token2.balanceOf(userAddress), 97e18);
    }

    // END Multiple

    function testWithdraw_ShouldRevert_IfTokenIsNotInMetaPool() public {
        address userAddress = address(0x100);
        vm.prank(userAddress);
        vm.expectRevert(
            "Invalid token: must be DAI, USD Coin, Tether, or Ubiquity Dollar"
        );
        directGovernanceFarmer.withdraw(1, address(0));
    }

    function testWithdraw_ShouldRevert_IfSenderIsNotBondOwner() public {
        address userAddress = address(0x100);
        address stakingShareAddress = address(0x102);

        // admin sets staking share addresses
        vm.prank(admin);
        IUbiquityDollarManager(dollarManagerAddress).setStakingShareAddress(
            stakingShareAddress
        );

        vm.mockCall(
            stakingShareAddress,
            abi.encodeWithSelector(IERC1155Ubiquity.holderTokens.selector),
            abi.encode([0])
        );

        vm.prank(userAddress);
        vm.expectRevert("sender is not true bond owner");
        directGovernanceFarmer.withdraw(1, address(token0));
    }

    function testWithdraw_ShouldWithdraw() public {
        address userAddress = address(0x100);
        address stakingAddress = address(0x101);
        address stakingShareAddress = address(0x102);

        // admin sets staking and staking share addresses
        vm.startPrank(admin);
        IUbiquityDollarManager(dollarManagerAddress).setStakingContractAddress(
            stakingAddress
        );
        IUbiquityDollarManager(dollarManagerAddress).setStakingShareAddress(
            stakingShareAddress
        );
        vm.stopPrank();

        vm.startPrank(userAddress);

        // mint 100 DAI to user
        token0.mint(userAddress, 100e18);
        // user allows DirectGovernanceFarmerHarness to spend user's DAI
        token0.approve(address(directGovernanceFarmer), 100e18);

        // prepare mocks for deposit
        vm.mockCall(
            depositZapAddress,
            abi.encodeWithSelector(IDepositZap.add_liquidity.selector),
            abi.encode(100e18)
        );
        vm.mockCall(
            stakingAddress,
            abi.encodeWithSelector(IStaking.deposit.selector),
            abi.encode(1)
        );
        vm.mockCall(
            stakingShareAddress,
            abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256,uint256,bytes)",
                address(directGovernanceFarmer),
                userAddress,
                1,
                1,
                "0x"
            ),
            ""
        );

        // user deposits 100 DAI for 1 week
        directGovernanceFarmer.deposit(address(token0), 100e18, 1);

        // wait 1 week + 1 day
        vm.warp(block.timestamp + 8 days);

        // prepare mocks for withdraw
        uint256[] memory stakingShareIds = new uint256[](1);
        stakingShareIds[0] = 1;
        vm.mockCall(
            stakingShareAddress,
            abi.encodeWithSelector(IERC1155Ubiquity.holderTokens.selector),
            abi.encode(stakingShareIds)
        );

        IStakingShare.Stake memory stake;
        stake.lpAmount = 100e18;
        vm.mockCall(
            stakingShareAddress,
            abi.encodeWithSelector(IStakingShare.getStake.selector),
            abi.encode(stake)
        );

        vm.mockCall(
            depositZapAddress,
            abi.encodeWithSelector(
                IDepositZap.remove_liquidity_one_coin.selector
            ),
            abi.encode(100e18)
        );

        uint256 tokenAmount = directGovernanceFarmer.withdraw(
            1,
            address(token0)
        );
        assertEq(tokenAmount, 100e18);
    }

    function testIsIdIncluded_ReturnTrue_IfIdIsInTheList() public {
        // deploy contract with exposed internal methods
        DirectGovernanceFarmerHarness directGovernanceFarmerHarness = new DirectGovernanceFarmerHarness(
                dollarManagerAddress,
                base3PoolAddress,
                depositZapAddress
            );
        // run assertions
        uint256[] memory list = new uint256[](1);
        list[0] = 1;
        assertTrue(directGovernanceFarmerHarness.exposed_isIdIncluded(list, 1));
    }

    function testIsIdIncluded_ReturnFalse_IfIdIsNotInTheList() public {
        // deploy contract with exposed internal methods
        DirectGovernanceFarmerHarness directGovernanceFarmerHarness = new DirectGovernanceFarmerHarness(
                dollarManagerAddress,
                base3PoolAddress,
                depositZapAddress
            );
        // run assertions
        uint256[] memory list = new uint256[](1);
        assertFalse(
            directGovernanceFarmerHarness.exposed_isIdIncluded(list, 1)
        );
    }

    function testIsMetaPoolCoin_ReturnTrue_IfToken0IsPassed() public {
        assertTrue(directGovernanceFarmer.isMetaPoolCoin(address(token0)));
    }

    function testIsMetaPoolCoin_ReturnTrue_IfToken1IsPassed() public {
        assertTrue(directGovernanceFarmer.isMetaPoolCoin(address(token1)));
    }

    function testIsMetaPoolCoin_ReturnTrue_IfToken2IsPassed() public {
        assertTrue(directGovernanceFarmer.isMetaPoolCoin(address(token2)));
    }

    function testIsMetaPoolCoin_ReturnTrue_IfUbiquityDollarTokenIsPassed()
        public
    {
        assertTrue(
            directGovernanceFarmer.isMetaPoolCoin(
                directGovernanceFarmer.ubiquityDollar()
            )
        );
    }

    function testIsMetaPoolCoin_ReturnFalse_IfTokenAddressIsNotInMetaPool()
        public
    {
        assertFalse(directGovernanceFarmer.isMetaPoolCoin(address(0)));
    }
}
