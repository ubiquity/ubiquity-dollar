// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/dollar/facets/StabilityPoolFacet.sol";
import "../../src/interfaces/ILiquityStabilityPool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Мокаем LUSD (наследуемся от ERC20 для совместимости)
contract MockLUSD is ERC20 {
    constructor() ERC20("Mock LUSD", "LUSD") {}
    function mint(address to, uint256 amount) external { _mint(to, amount); }
}

// Мокаем Stability Pool
contract MockStabilityPool {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public rewards;

    function provideToSP(uint256 amount) external { deposits[msg.sender] += amount; }
    function withdrawFromSP(uint256 amount) external { deposits[msg.sender] -= amount; }
    function getDepositorLQTYGain(address d) external view returns (uint256) { return rewards[d]; }
    function getCompoundedLUSDDeposit(address d) external view returns (uint256) { return deposits[d]; }
    function claimLQTY() external { rewards[msg.sender] = 0; }
    function simulateReward(address to, uint256 amt) external { rewards[to] += amt; }
}

contract StabilityPoolFacetTest is Test {
    StabilityPoolFacet facet;
    MockLUSD lusd;
    MockStabilityPool sp;
    
    // Адрес Mainnet LUSD, который захардкожен в контракте
    address constant LUSD_ADDR = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;
    
    address treasury = makeAddr("treasury");
    address user = makeAddr("user");

    function setUp() public {
        // 1. Создаем мок LUSD
        MockLUSD _mockLusd = new MockLUSD();
        
        // 2. Подменяем код по адресу Mainnet LUSD на код нашего мока
        // Это позволит контракту взаимодействовать с моком, даже если он обращается по захардкоженному адресу
        vm.etch(LUSD_ADDR, address(_mockLusd).code);
        
        // 3. Привязываем переменную к этому адресу
        lusd = MockLUSD(LUSD_ADDR);

        // Инициализируем остальные компоненты
        sp = new MockStabilityPool();
        facet = new StabilityPoolFacet();
        
        // Вызываем инициализацию (модификатор onlyAdmin мы уберем в Шаге 2)
        facet.initialize(treasury, address(sp), 1 ether); 
        
        // Раздаем токены пользователю
        lusd.mint(user, 10_000 ether);
        vm.startPrank(user);
        lusd.approve(address(facet), type(uint256).max);
        vm.stopPrank();
    }

    function testDepositWithdraw() public {
        uint256 amt = 1000 ether;
        
        // Депозит
        vm.prank(user);
        facet.depositToPool(amt);
        
        assertEq(sp.getCompoundedLUSDDeposit(address(facet)), amt);
        assertEq(facet.totalPrincipalInPool(), amt);

        // Симулируем награду (для полноты картины)
        sp.simulateReward(address(facet), 10 ether);
        
        // Вывод
        vm.prank(user);
        facet.withdrawFromPool(amt);
        
        assertEq(sp.getCompoundedLUSDDeposit(address(facet)), 0);
        assertEq(lusd.balanceOf(user), 10_000 ether); // Баланс пользователя должен вернуться к исходному
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
