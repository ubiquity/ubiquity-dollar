// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/dollar/facets/StabilityPoolFacet.sol";
import "../../src/interfaces/ILiquityStabilityPool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockLUSD is ERC20 {
    constructor() ERC20("Mock LUSD", "LUSD") {}
    function mint(address to, uint256 amount) external { _mint(to, amount); }
}

contract MockStabilityPool {
    address constant LUSD_ADDR = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public lqtyRewards;
    mapping(address => uint256) public ethRewards;

    function provideToSP(uint256 amount, address) external {
        deposits[msg.sender] += amount;
    }

    function withdrawFromSP(uint256 amount) external {
        deposits[msg.sender] -= amount;
        // ВАЖНО: реально возвращаем LUSD обратно фасету
        require(MockLUSD(LUSD_ADDR).transfer(msg.sender, amount), "transfer failed");
    }

    function getDepositorLQTYGain(address d) external view returns (uint256) { return lqtyRewards[d]; }
    function getDepositorETHGain(address d) external view returns (uint256) { return ethRewards[d]; }
    function getCompoundedLUSDDeposit(address d) external view returns (uint256) { return deposits[d]; }
    function simulateLQTYReward(address to, uint256 amt) external { lqtyRewards[to] += amt; }
    function simulateETHReward(address to, uint256 amt) external { ethRewards[to] += amt; }
}

contract StabilityPoolFacetTest is Test {
    StabilityPoolFacet facet;
    MockLUSD lusd;
    MockStabilityPool sp;
    address treasury = makeAddr("treasury");
    address admin = makeAddr("admin");
    address user = makeAddr("user");

    address constant LUSD_ADDR = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;

    function setUp() public {
        lusd = new MockLUSD();
        sp = new MockStabilityPool();
        facet = new StabilityPoolFacet();

        vm.etch(LUSD_ADDR, address(lusd).code);
        lusd = MockLUSD(LUSD_ADDR);

        // initialize без onlyAdmin (для тестов)
        facet.initialize(treasury, address(sp), address(lusd), address(lusd), 1 ether);

        lusd.mint(user, 10_000 ether);
        lusd.mint(address(sp), 1_000_000 ether);
        vm.startPrank(user);
        lusd.approve(address(facet), type(uint256).max);
        vm.stopPrank();
    }

    function testDepositWithdraw() public {
        uint256 amt = 1000 ether;
        vm.prank(user);
        facet.depositToPool(amt);

        assertEq(sp.getCompoundedLUSDDeposit(address(facet)), amt);
        assertEq(facet.totalPrincipalInPool(), amt);

        vm.prank(user);
        facet.withdrawFromPool(amt);

        assertEq(sp.getCompoundedLUSDDeposit(address(facet)), 0);
        assertEq(facet.totalPrincipalInPool(), 0);
        assertEq(lusd.balanceOf(user), 10_000 ether);
    }

    function testHarvestRewards() public {
        uint256 amt = 500 ether;
        vm.prank(user);
        facet.depositToPool(amt);

        sp.simulateLQTYReward(address(facet), 25 ether);
        sp.simulateETHReward(address(facet), 1 ether);
        // начисляем "LQTY" (используем lusd, т.к. адрес LQTY подменён на lusd)
        lusd.mint(address(facet), 25 ether);

        vm.prank(admin);
        facet.harvestRewards();

        // LQTY отправлены в treasury
        assertEq(lusd.balanceOf(treasury), 25 ether);
    }

    function testHarvestBelowThresholdReverts() public {
        uint256 amt = 500 ether;
        vm.prank(user);
        facet.depositToPool(amt);

        sp.simulateLQTYReward(address(facet), 0.5 ether);

        vm.expectRevert(StabilityPoolFacet.BelowThreshold.selector);
        vm.prank(admin);
        facet.harvestRewards();
    }

    function testPausedReverts() public {
        vm.prank(admin);
        facet.togglePause();

        vm.expectRevert(StabilityPoolFacet.Paused.selector);
        vm.prank(user);
        facet.depositToPool(100 ether);
    }

    function testFuzzDepositWithdraw(uint256 amount) public {
        amount = bound(amount, 1 ether, 900 ether);
        vm.prank(user);
        facet.depositToPool(amount);
        vm.prank(user);
        facet.withdrawFromPool(amount);
        assertEq(facet.totalPrincipalInPool(), 0);
    }

    function testGasLimit() public {
        uint256 gasBefore = gasleft();
        vm.prank(user);
        facet.depositToPool(500 ether);
        uint256 gasUsed = gasBefore - gasleft();
        assertLt(gasUsed, 180_000, "Gas limit exceeded");
    }
}
