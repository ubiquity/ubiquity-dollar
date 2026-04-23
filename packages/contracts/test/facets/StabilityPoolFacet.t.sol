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
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public rewards;

    function provideToSP(uint256 amount, address) external { deposits[msg.sender] += amount; }
    
    function withdrawFromSP(uint256 amount) external {
        deposits[msg.sender] -= amount;
        // Моковый пул реально переводит LUSD вызывающему
        MockLUSD(0x5f98805A4E8be255a32880FDeC7F6728C6568bA0).transfer(msg.sender, amount);
    }
    
    function getDepositorLQTYGain(address d) external view returns (uint256) { return rewards[d]; }
    function getCompoundedLUSDDeposit(address d) external view returns (uint256) { return deposits[d]; }
    function claimLQTY() external { rewards[msg.sender] = 0; }
    function simulateReward(address to, uint256 amt) external { rewards[to] += amt; }
}

contract StabilityPoolFacetTest is Test {
    StabilityPoolFacet facet;
    MockLUSD lusd;
    MockStabilityPool sp;
    address treasury = makeAddr("treasury");
    address user = makeAddr("user");
    address constant LUSD_ADDR = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;

    function setUp() public {
        lusd = new MockLUSD();
        sp = new MockStabilityPool();
        facet = new StabilityPoolFacet();

        // Подменяем код по адресу Mainnet LUSD на код нашего мока
        vm.etch(LUSD_ADDR, address(lusd).code);
        lusd = MockLUSD(LUSD_ADDR);

        facet.initialize(treasury, address(sp), 1 ether);

        // Раздаем токены пользователю
        lusd.mint(user, 10_000 ether);
        
        // 🛑 ИСПРАВЛЕНИЕ: Выдаем токены пулу, чтобы он мог их вернуть при withdrawFromSP
        lusd.mint(address(sp), 10_000 ether);

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

        sp.simulateReward(address(facet), 10 ether);
        
        vm.prank(user);
        facet.withdrawFromPool(amt);
        
        assertEq(sp.getCompoundedLUSDDeposit(address(facet)), 0);
        assertEq(lusd.balanceOf(user), 10_000 ether);
    }

    function testFuzzDepositWithdraw(uint256 amount) public {
        amount = bound(amount, 1 ether, 900 ether);
        vm.prank(user);
        facet.depositToPool(amount);
        vm.prank(user);
        facet.withdrawFromPool(amount);
        assertEq(facet.totalPrincipalInPool(), 0);
    }

    function testGasUsage() public {
        uint256 gasBefore = gasleft();
        vm.prank(user);
        facet.depositToPool(500 ether);
        uint256 gasUsed = gasBefore - gasleft();
        assertLt(gasUsed, 180_000, "Gas limit exceeded");
    }
}
