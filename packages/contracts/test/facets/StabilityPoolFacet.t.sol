// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/dollar/facets/StabilityPoolFacet.sol";
import "../../src/interfaces/ILiquityStabilityPool.sol";
import "../../src/dollar/libraries/LibAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @dev Test wrapper — наследует StabilityPoolFacet, добавляет выдачу роли
contract TestStabilityPoolFacet is StabilityPoolFacet {
    function grantAdminForTest(address account) external {
        LibAccessControl.grantRole(DEFAULT_ADMIN_ROLE, account);
    }
}

contract MockLUSD is ERC20 {
    constructor() ERC20("Mock LUSD", "LUSD") {}
    function mint(address to, uint256 amount) external { _mint(to, amount); }
}

contract MockLQTY is ERC20 {
    constructor() ERC20("Mock LQTY", "LQTY") {}
    function mint(address to, uint256 amount) external { _mint(to, amount); }
}

contract MockStabilityPool {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public lqtyRewards;
    mapping(address => uint256) public ethRewards;

    IERC20 public lusdToken;
    bool public returnLusdOnWithdraw = true;

    function setLusdToken(address _lusd) external {
        lusdToken = IERC20(_lusd);
    }

    function setReturnLusdOnWithdraw(bool _return) external {
        returnLusdOnWithdraw = _return;
    }

    function provideToSP(uint256 amount, address) external {
        deposits[msg.sender] += amount;
        if (address(lusdToken) != address(0)) {
            lusdToken.transferFrom(msg.sender, address(this), amount);
        }
    }

    function withdrawFromSP(uint256 amount) external {
        if (amount == 0) {
            uint256 ethReward = ethRewards[msg.sender];
            if (ethReward > 0) {
                ethRewards[msg.sender] = 0;
                (bool success, ) = msg.sender.call{value: ethReward}("");
                require(success, "ETH transfer failed");
            }
            lqtyRewards[msg.sender] = 0;
        } else {
            deposits[msg.sender] -= amount;
            if (address(lusdToken) != address(0) && returnLusdOnWithdraw) {
                lusdToken.transfer(msg.sender, amount);
            }
        }
    }

    function getDepositorLQTYGain(address d) external view returns (uint256) {
        return lqtyRewards[d];
    }

    function getDepositorETHGain(address d) external view returns (uint256) {
        return ethRewards[d];
    }

    function getCompoundedLUSDDeposit(address d) external view returns (uint256) {
        return deposits[d];
    }

    function simulateLQTYReward(address to, uint256 amt) external {
        lqtyRewards[to] += amt;
    }

    function simulateETHReward(address to, uint256 amt) external {
        ethRewards[to] += amt;
    }

    receive() external payable {}
}

/// @dev Treasury that always rejects ETH
contract RevertingTreasury {
    receive() external payable { revert("no ETH"); }
}

contract StabilityPoolFacetTest is Test {
    TestStabilityPoolFacet facet;
    MockLUSD lusd;
    MockLQTY lqty;
    MockStabilityPool sp;
    address admin = makeAddr("admin");
    address treasury = makeAddr("treasury");
    address user = makeAddr("user");

    function setUp() public {
        lusd = new MockLUSD();
        lqty = new MockLQTY();
        sp = new MockStabilityPool();
        facet = new TestStabilityPoolFacet();

        facet.grantAdminForTest(admin);

        facet.initialize(
            treasury,
            address(sp),
            address(lusd),
            address(lqty),
            1 ether
        );

        sp.setLusdToken(address(lusd));

        lusd.mint(admin, 10_000 ether);
        vm.startPrank(admin);
        lusd.approve(address(facet), type(uint256).max);
        vm.stopPrank();

        vm.deal(address(sp), 100 ether);
    }

    // ============================================================
    // EXISTING TESTS
    // ============================================================

    function testDepositWithdraw() public {
        uint256 amt = 1000 ether;
        vm.prank(admin);
        facet.depositToPool(amt);

        assertEq(sp.getCompoundedLUSDDeposit(address(facet)), amt);
        assertEq(facet.totalPrincipalInPool(), amt);

        vm.prank(admin);
        facet.withdrawFromPool(amt);

        assertEq(sp.getCompoundedLUSDDeposit(address(facet)), 0);
        assertEq(facet.totalPrincipalInPool(), 0);
    }

    function testHarvestRewards() public {
        uint256 amt = 500 ether;
        vm.prank(admin);
        facet.depositToPool(amt);

        sp.simulateLQTYReward(address(facet), 25 ether);
        sp.simulateETHReward(address(facet), 1 ether);
        lqty.mint(address(facet), 25 ether);

        uint256 treasuryEthBefore = treasury.balance;
        vm.prank(admin);
        facet.harvestRewards();

        assertEq(lqty.balanceOf(treasury), 25 ether);
        assertEq(treasury.balance - treasuryEthBefore, 1 ether);
    }

    function testHarvestBelowThresholdReverts() public {
        vm.prank(admin);
        facet.depositToPool(500 ether);

        sp.simulateLQTYReward(address(facet), 0.5 ether);

        vm.expectRevert(StabilityPoolFacet.BelowThreshold.selector);
        vm.prank(admin);
        facet.harvestRewards();
    }

    function testPausedReverts() public {
        vm.prank(admin);
        facet.togglePause();

        vm.expectRevert(StabilityPoolFacet.Paused.selector);
        vm.prank(admin);
        facet.depositToPool(100 ether);
    }

    function testNonAdminCannotDeposit() public {
        vm.expectRevert(StabilityPoolFacet.NotAdmin.selector);
        vm.prank(user);
        facet.depositToPool(100 ether);
    }

    function testNonAdminCannotWithdraw() public {
        vm.prank(admin);
        facet.depositToPool(1000 ether);

        vm.expectRevert(StabilityPoolFacet.NotAdmin.selector);
        vm.prank(user);
        facet.withdrawFromPool(100 ether);
    }

    function testNonAdminCannotHarvest() public {
        vm.prank(admin);
        facet.depositToPool(500 ether);

        sp.simulateLQTYReward(address(facet), 25 ether);
        lqty.mint(address(facet), 25 ether);

        vm.expectRevert(StabilityPoolFacet.NotAdmin.selector);
        vm.prank(user);
        facet.harvestRewards();
    }

    function testFuzzDepositWithdraw(uint256 amount) public {
        amount = bound(amount, 1 ether, 900 ether);
        vm.prank(admin);
        facet.depositToPool(amount);
        vm.prank(admin);
        facet.withdrawFromPool(amount);
        assertEq(facet.totalPrincipalInPool(), 0);
    }

    function testGasLimit() public {
        uint256 gasBefore = gasleft();
        vm.prank(admin);
        facet.depositToPool(500 ether);
        uint256 gasUsed = gasBefore - gasleft();
        assertLt(gasUsed, 180_000, "Gas limit exceeded");
    }

    // ============================================================
    // NEW — Uncovered functions
    // ============================================================

    function testSetTreasury() public {
        address newTreasury = makeAddr("newTreasury");
        vm.prank(admin);
        facet.setTreasury(newTreasury);
    }

    function testNonAdminCannotSetTreasury() public {
        vm.expectRevert(StabilityPoolFacet.NotAdmin.selector);
        vm.prank(user);
        facet.setTreasury(makeAddr("newTreasury"));
    }

    function testSetThreshold() public {
        // setThreshold has no access control — anyone can call
        facet.setThreshold(5 ether);
    }

    function testEmergencyWithdraw() public {
        lusd.mint(address(facet), 100 ether);

        uint256 adminBalBefore = lusd.balanceOf(admin);
        vm.prank(admin);
        facet.emergencyWithdraw(address(lusd), 100 ether);

        assertEq(lusd.balanceOf(admin) - adminBalBefore, 100 ether);
    }

    function testNonAdminCannotEmergencyWithdraw() public {
        lusd.mint(address(facet), 100 ether);

        vm.expectRevert(StabilityPoolFacet.NotAdmin.selector);
        vm.prank(user);
        facet.emergencyWithdraw(address(lusd), 100 ether);
    }

    function testGetPendingRewards() public {
        vm.prank(admin);
        facet.depositToPool(500 ether);

        sp.simulateLQTYReward(address(facet), 10 ether);
        sp.simulateETHReward(address(facet), 2 ether);

        (uint256 lqtyGain, uint256 ethGain) = facet.getPendingRewards();
        assertEq(lqtyGain, 10 ether);
        assertEq(ethGain, 2 ether);
    }

    // ============================================================
    // NEW — Uncovered branches
    // ============================================================

    function testAlreadyInitializedReverts() public {
        vm.expectRevert(StabilityPoolFacet.AlreadyInitialized.selector);
        facet.initialize(treasury, address(sp), address(lusd), address(lqty), 1 ether);
    }

    function testDepositZeroReverts() public {
        vm.expectRevert(StabilityPoolFacet.ZeroAmount.selector);
        vm.prank(admin);
        facet.depositToPool(0);
    }

    function testWithdrawZeroReverts() public {
        vm.prank(admin);
        facet.depositToPool(500 ether);

        vm.expectRevert(StabilityPoolFacet.ZeroAmount.selector);
        vm.prank(admin);
        facet.withdrawFromPool(0);
    }

    function testWithdrawInsufficientBalanceReverts() public {
        vm.prank(admin);
        facet.depositToPool(500 ether);

        vm.expectRevert(StabilityPoolFacet.InsufficientBalance.selector);
        vm.prank(admin);
        facet.withdrawFromPool(1000 ether);
    }

    function testWithdrawPartial() public {
        vm.prank(admin);
        facet.depositToPool(1000 ether);

        vm.prank(admin);
        facet.withdrawFromPool(400 ether);

        assertEq(sp.getCompoundedLUSDDeposit(address(facet)), 600 ether);
        assertEq(facet.totalPrincipalInPool(), 600 ether);
    }

    function testWithdrawWithZeroReceived() public {
        vm.prank(admin);
        facet.depositToPool(500 ether);

        // Simulate pool not returning LUSD (deposit consumed by liquidations)
        sp.setReturnLusdOnWithdraw(false);

        vm.prank(admin);
        facet.withdrawFromPool(500 ether);

        assertEq(facet.totalPrincipalInPool(), 0);
        assertEq(sp.getCompoundedLUSDDeposit(address(facet)), 0);
    }

    function testHarvestWithEthOnly() public {
        // LQTY below threshold but ETH > 0 — should NOT revert
        vm.prank(admin);
        facet.depositToPool(500 ether);

        sp.simulateLQTYReward(address(facet), 0.5 ether);
        sp.simulateETHReward(address(facet), 1 ether);

        uint256 treasuryEthBefore = treasury.balance;
        vm.prank(admin);
        facet.harvestRewards();

        assertEq(treasury.balance - treasuryEthBefore, 1 ether);
    }

    function testPausedWithdrawReverts() public {
        vm.prank(admin);
        facet.depositToPool(500 ether);

        vm.prank(admin);
        facet.togglePause();

        vm.expectRevert(StabilityPoolFacet.Paused.selector);
        vm.prank(admin);
        facet.withdrawFromPool(100 ether);
    }

    function testPausedHarvestReverts() public {
        vm.prank(admin);
        facet.depositToPool(500 ether);

        sp.simulateLQTYReward(address(facet), 25 ether);
        lqty.mint(address(facet), 25 ether);

        vm.prank(admin);
        facet.togglePause();

        vm.expectRevert(StabilityPoolFacet.Paused.selector);
        vm.prank(admin);
        facet.harvestRewards();
    }

    // ============================================================
    // NEW — EthTransferFailed branch (100% coverage)
    // ============================================================

    function testEthTransferFailedReverts() public {
        vm.prank(admin);
        facet.depositToPool(500 ether);

        // Set treasury to a contract that rejects ETH
        RevertingTreasury badTreasury = new RevertingTreasury();
        vm.prank(admin);
        facet.setTreasury(address(badTreasury));

        sp.simulateLQTYReward(address(facet), 25 ether);
        sp.simulateETHReward(address(facet), 1 ether);
        lqty.mint(address(facet), 25 ether);

        vm.expectRevert(StabilityPoolFacet.EthTransferFailed.selector);
        vm.prank(admin);
        facet.harvestRewards();
    }
}
