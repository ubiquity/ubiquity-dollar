// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UbiquityAlgorithmicDollar} from "../../src/dollar/UbiquityAlgorithmicDollar.sol";
import {SellPressureDampeningIncentive} from "../../src/dollar/SellPressureDampeningIncentive.sol";
import "../../src/dollar/interfaces/IERC20Ubiquity.sol";
import "../../src/dollar/interfaces/IMetaPool.sol";
import "../../src/dollar/UbiquityAlgorithmicDollarManager.sol";
import "forge-std/Test.sol";

contract SellPressureDampeningTest is Test {
    address incentive_addr;
    SellPressureDampeningIncentive incentive;
    address crvminter = address(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    address uad_addr; // = address(0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6);
    UbiquityAlgorithmicDollarManager manager;
    UbiquityAlgorithmicDollar dollar;
    IERC20Ubiquity curve3crv;
    address uad_manager_address =
        address(0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98);
    address treasury;
    address mock_sender = address(0x111);
    address mock_recipient = address(0x222);
    address mock_operator = address(0x333);
    address curve3CRVTokenAddress;
    address metaPoolAddress; //=  address(0x20955CB69Ae1515962177D164dfC9522feef567E);
    IMetaPool pool;
    address admin = address(0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd);
    event Incentivized(
        address indexed sender,
        address indexed recipient,
        address operator,
        uint256 amount
    );

    function setUp() public {
        //  uad_manager_address = helpers_deployUbiquityAlgorithmicDollarManager();
        incentive = new SellPressureDampeningIncentive(uad_manager_address);
        incentive_addr = address(incentive);
        manager = UbiquityAlgorithmicDollarManager(uad_manager_address);
        metaPoolAddress = manager.stableSwapMetaPoolAddress();
        pool = IMetaPool(metaPoolAddress);
        uad_addr = manager.dollarTokenAddress();
        dollar = UbiquityAlgorithmicDollar(uad_addr);

        curve3CRVTokenAddress = manager.curve3PoolTokenAddress();
        curve3crv = IERC20Ubiquity(curve3CRVTokenAddress);
        treasury = manager.treasuryAddress();
        vm.startPrank(admin);
        /*    uad_addr = address(new UbiquityAlgorithmicDollar(uad_manager_address));
        metaPoolAddress = address(
            new MockMetaPool(uad_addr, curve3CRVTokenAddress)
        ); */
        // set the mock data for meta pool
        /*    uint256[2] memory _price_cumulative_last = [
            uint256(100e18),
            uint256(100e18)
        ];
        uint256 _last_block_timestamp = 20000;
        uint256[2] memory _twap_balances = [uint256(100e18), uint256(100e18)];
        uint256[2] memory _dy_values = [uint256(100e18), uint256(100e18)];
        MockMetaPool(metaPoolAddress).updateMockParams(
            _price_cumulative_last,
            _last_block_timestamp,
            _twap_balances,
            _dy_values
        ); 
        UbiquityAlgorithmicDollar(uad_addr).setStableSwapMetaPoolAddress(
            metaPoolAddress
        );
        UbiquityAlgorithmicDollarManager(uad_manager_address).grantRole(
            keccak256("UBQ_TOKEN_MANAGER_ROLE"),
            admin
        );*/
        // set incentive on metapool
        dollar.setIncentiveContract(metaPoolAddress, incentive_addr);
        vm.stopPrank();
    }

    /*   function test_transferIncentive() public {
        address userA = address(0x100001);

        vm.startPrank(admin);
        uint256 amount = 10000 ether;
        dollar.mint(userA, amount);

        vm.stopPrank();

        vm.startPrank(userA);
        // we need to approve  metaPool
        dollar.approve(metaPoolAddress, 0);
        dollar.approve(metaPoolAddress, amount);

        vm.expectEmit(true, true, true, true);
        emit Incentivized(userA, metaPoolAddress, metaPoolAddress, amount);

        vm.expectCall(
            incentive_addr,
            abi.encodeWithSelector(
                SellPressureDampeningIncentive.incentivize.selector,
                userA,
                metaPoolAddress,
                metaPoolAddress,
                amount
            )
        );
        // swap  amount of uAD => 3CRV
        uint256 amount3CRVReceived = pool.exchange(0, 1, amount, 0);

        vm.stopPrank();

        // UbiquityAlgorithmicDollar(uad_addr).transfer(mock_recipient, 1);
    }

    function test_transferIncentiveShouldNotTriggerForBuy() public {
        address userA = address(0x100001);
        vm.startPrank(crvminter);
        uint256 amount = 10000 ether;
        curve3crv.mint(userA, amount);

        vm.stopPrank();

        vm.startPrank(userA);
        // we need to approve  metaPool
        curve3crv.approve(metaPoolAddress, 0);
        curve3crv.approve(metaPoolAddress, amount);
        uint256 amountuADReceived = pool.get_dy(1, 0, amount);

        vm.expectCall(
            incentive_addr,
            abi.encodeWithSelector(
                SellPressureDampeningIncentive.incentivize.selector,
                metaPoolAddress,
                userA,
                metaPoolAddress,
                amountuADReceived
            )
        );
        // swap  amount of 3CRV => uAD
        pool.exchange(1, 0, amount, 0);

        vm.stopPrank();

        // UbiquityAlgorithmicDollar(uad_addr).transfer(mock_recipient, 1);
    }

    function test_transferERC20ShouldBeAbleToTransferToTreasury() public {
        address userA = address(0x100001);

        uint256 balanceTreasuryBefore = curve3crv.balanceOf(treasury);
        uint256 balanceIncentiveBefore = curve3crv.balanceOf(incentive_addr);
        vm.startPrank(crvminter);
        uint256 amount = 10000 ether;

        curve3crv.mint(incentive_addr, amount);
        vm.stopPrank();
        uint256 balanceIncentiveAfter = curve3crv.balanceOf(incentive_addr);
        assertEq(balanceIncentiveAfter, balanceIncentiveBefore + amount);
        vm.startPrank(admin);
        incentive.withdrawToken(curve3CRVTokenAddress, amount);
        vm.stopPrank();
        uint256 balanceTreasuryAfter = curve3crv.balanceOf(treasury);
        assertEq(balanceTreasuryAfter, balanceTreasuryBefore + amount);
        // UbiquityAlgorithmicDollar(uad_addr).transfer(mock_recipient, 1);
    } */

    function test_IncentiveShouldTriggerLiquidityDeposit() public {
        // incentive needs 3CRV token to work
        vm.startPrank(crvminter);
        uint256 crvAmount = 10000 ether;
        curve3crv.mint(incentive_addr, crvAmount);
        vm.stopPrank();
        uint256 balanceIncentiveBefore = curve3crv.balanceOf(incentive_addr);
        address userA = address(0x100001);
        vm.startPrank(admin);
        uint256 amount = 10000 ether;
        dollar.mint(userA, amount);
        dollar.mint(incentive_addr, amount); // to remove
        vm.stopPrank();

        vm.startPrank(userA);
        // we need to approve  metaPool
        curve3crv.approve(metaPoolAddress, 0);
        curve3crv.approve(metaPoolAddress, amount);

        /*  vm.expectEmit(true, true, true, true);
        emit Incentivized(userA, metaPoolAddress, metaPoolAddress, amount); */

        vm.expectCall(
            incentive_addr,
            abi.encodeWithSelector(
                SellPressureDampeningIncentive.incentivize.selector,
                userA,
                metaPoolAddress,
                metaPoolAddress,
                amount
            )
        );
        // swap  amount of uAD => 3CRV
        uint256 amount3CRVReceived = pool.exchange(0, 1, amount, 0);

        vm.stopPrank();
        uint256 balanceIncentiveAfter = curve3crv.balanceOf(incentive_addr);
        assertLt(balanceIncentiveAfter, balanceIncentiveBefore);
        // UbiquityAlgorithmicDollar(uad_addr).transfer(mock_recipient, 1);
    }

    //TODO check incentive when removing liquidity one coin. It will transfer uAD from metapool to user
}
