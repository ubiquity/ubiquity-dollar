// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Diamond, DiamondArgs} from "../../src/dollar/Diamond.sol";
import {IDiamondCut} from "../../src/dollar/interfaces/IDiamondCut.sol";
import {DiamondCutFacet} from "../../src/dollar/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../../src/dollar/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../../src/dollar/facets/OwnershipFacet.sol";
import {AccessControlFacet} from "../../src/dollar/facets/AccessControlFacet.sol";
import {StabilityPoolFacet} from "../../src/dollar/facets/StabilityPoolFacet.sol";
import {ILiquityStabilityPool} from "../../src/dollar/interfaces/ILiquityStabilityPool.sol";
import {MockERC20} from "../../src/dollar/mocks/MockERC20.sol";

/// @title MockLiquityStabilityPool
/// @notice Mock implementation of the Liquity Stability Pool for testing
contract MockLiquityStabilityPool is ILiquityStabilityPool {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public ethGains;
    mapping(address => uint256) public lqtyGains;

    function provideToSP(uint256 _amount) external override {
        provideToSP(_amount, address(0));
    }

    function provideToSP(uint256 _amount, address) public override {
        deposits[msg.sender] += _amount;
        emit UserDepositChanged(msg.sender, deposits[msg.sender]);
    }

    function withdrawFromSP(uint256 _amount) external override {
        uint256 toWithdraw = _amount;
        if (toWithdraw > deposits[msg.sender]) {
            toWithdraw = deposits[msg.sender];
        }
        deposits[msg.sender] -= toWithdraw;

        // Auto-claim rewards on withdrawal
        uint256 eth = ethGains[msg.sender];
        uint256 lqty = lqtyGains[msg.sender];
        ethGains[msg.sender] = 0;
        lqtyGains[msg.sender] = 0;

        if (eth > 0) emit ETHGainWithdrawn(msg.sender, eth, 0);
        if (lqty > 0) emit LQTYPaidToDepositor(msg.sender, lqty);
    }

    function withdrawFromSP() external override {
        uint256 bal = deposits[msg.sender];
        if (bal > 0) this.withdrawFromSP(bal);
    }

    function getDepositorETHGain(address _depositor) external view override returns (uint256) {
        return ethGains[_depositor];
    }

    function getDepositorLQTYGain(address _depositor) external view override returns (uint256) {
        return lqtyGains[_depositor];
    }

    function getCompoundedLUSDDeposit(address _depositor) external view override returns (uint256) {
        return deposits[_depositor];
    }

    function getDepositorInfo(address _depositor) external view override returns (uint256, uint256, uint256) {
        return (deposits[_depositor], ethGains[_depositor], lqtyGains[_depositor]);
    }

    /// @notice Helper to set rewards for testing
    function setRewards(address depositor, uint256 ethGain, uint256 lqtyGain) external {
        ethGains[depositor] = ethGain;
        lqtyGains[depositor] = lqtyGain;
    }
}

contract StabilityPoolFacetTest is Test {
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    OwnershipFacet ownershipFacet;
    AccessControlFacet accessControlFacet;
    StabilityPoolFacet stabilityPoolFacet;

    MockERC20 lusdToken;
    MockERC20 lqtyToken;
    MockLiquityStabilityPool mockStabilityPool;

    address owner;
    address user1;

    bytes4 constant ADMIN_ROLE = 0x00;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");

        // Deploy mocks
        lusdToken = new MockERC20("LUSD", "LUSD", 18);
        lqtyToken = new MockERC20("LQTY", "LQTY", 18);
        mockStabilityPool = new MockLiquityStabilityPool();

        // Deploy facet implementations
        diamondCutFacet = new DiamondCutFacet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();
        accessControlFacet = new AccessControlFacet();
        stabilityPoolFacet = new StabilityPoolFacet();

        // Prepare selectors
        bytes4[] memory cutSelectors = new bytes4[](1);
        cutSelectors[0] = DiamondCutFacet.diamondCut.selector;

        bytes4[] memory loupeSelectors = new bytes4[](4);
        loupeSelectors[0] = DiamondLoupeFacet.facets.selector;
        loupeSelectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
        loupeSelectors[2] = DiamondLoupeFacet.facetAddresses.selector;
        loupeSelectors[3] = DiamondLoupeFacet.facetAddress.selector;

        bytes4[] memory ownershipSelectors = new bytes4[](2);
        ownershipSelectors[0] = OwnershipFacet.transferOwnership.selector;
        ownershipSelectors[1] = OwnershipFacet.owner.selector;

        bytes4[] memory acSelectors = new bytes4[](2);
        acSelectors[0] = AccessControlFacet.grantRole.selector;
        acSelectors[1] = AccessControlFacet.hasRole.selector;

        bytes4[] memory spSelectors = new bytes4[](17);
        spSelectors[0] = StabilityPoolFacet.stabilityPoolAddress.selector;
        spSelectors[1] = StabilityPoolFacet.lusdTokenAddress.selector;
        spSelectors[2] = StabilityPoolFacet.lqtyTokenAddress.selector;
        spSelectors[3] = StabilityPoolFacet.isAutoDepositEnabled.selector;
        spSelectors[4] = StabilityPoolFacet.totalDeposited.selector;
        spSelectors[5] = StabilityPoolFacet.accumulatedEthGains.selector;
        spSelectors[6] = StabilityPoolFacet.accumulatedLqtyRewards.selector;
        spSelectors[7] = StabilityPoolFacet.compoundedLusdDeposit.selector;
        spSelectors[8] = StabilityPoolFacet.pendingEthGain.selector;
        spSelectors[9] = StabilityPoolFacet.pendingLqtyGain.selector;
        spSelectors[10] = StabilityPoolFacet.depositToStabilityPool.selector;
        spSelectors[11] = StabilityPoolFacet.withdrawFromStabilityPool.selector;
        spSelectors[12] = StabilityPoolFacet.withdrawAllFromStabilityPool.selector;
        spSelectors[13] = StabilityPoolFacet.claimStabilityPoolRewards.selector;
        spSelectors[14] = StabilityPoolFacet.depositAndClaim.selector;
        spSelectors[15] = StabilityPoolFacet.setStabilityPoolAddresses.selector;
        spSelectors[16] = StabilityPoolFacet.toggleAutoDeposit.selector;

        // Build cuts
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](5);
        cuts[0] = IDiamondCut.FacetCut({facetAddress: address(diamondCutFacet), action: IDiamondCut.FacetCutAction.Add, functionSelectors: cutSelectors});
        cuts[1] = IDiamondCut.FacetCut({facetAddress: address(diamondLoupeFacet), action: IDiamondCut.FacetCutAction.Add, functionSelectors: loupeSelectors});
        cuts[2] = IDiamondCut.FacetCut({facetAddress: address(ownershipFacet), action: IDiamondCut.FacetCutAction.Add, functionSelectors: ownershipSelectors});
        cuts[3] = IDiamondCut.FacetCut({facetAddress: address(accessControlFacet), action: IDiamondCut.FacetCutAction.Add, functionSelectors: acSelectors});
        cuts[4] = IDiamondCut.FacetCut({facetAddress: address(stabilityPoolFacet), action: IDiamondCut.FacetCutAction.Add, functionSelectors: spSelectors});

        DiamondArgs memory args = DiamondArgs({owner: owner, init: address(0), initCalldata: ""});
        diamond = new Diamond(args);

        // Add facets
        IDiamondCut(address(diamond)).diamondCut(cuts, address(0), "");

        // Grant admin role to owner
        AccessControlFacet(address(diamond)).grantRole(ADMIN_ROLE, owner);
    }

    /// @dev Helper to interact with StabilityPoolFacet through diamond
    function sp() internal view returns (StabilityPoolFacet) {
        return StabilityPoolFacet(address(diamond));
    }

    // ============ View Tests ============

    function test_InitialValuesAreZero() public view {
        assertEq(sp().stabilityPoolAddress(), address(0));
        assertEq(sp().lusdTokenAddress(), address(0));
        assertEq(sp().lqtyTokenAddress(), address(0));
        assertFalse(sp().isAutoDepositEnabled());
        assertEq(sp().totalDeposited(), 0);
        assertEq(sp().accumulatedEthGains(), 0);
        assertEq(sp().accumulatedLqtyRewards(), 0);
        assertEq(sp().compoundedLusdDeposit(), 0);
        assertEq(sp().pendingEthGain(), 0);
        assertEq(sp().pendingLqtyGain(), 0);
    }

    // ============ Admin Tests ============

    function test_SetStabilityPoolAddresses() public {
        sp().setStabilityPoolAddresses(address(mockStabilityPool), address(lusdToken), address(lqtyToken));

        assertEq(sp().stabilityPoolAddress(), address(mockStabilityPool));
        assertEq(sp().lusdTokenAddress(), address(lusdToken));
        assertEq(sp().lqtyTokenAddress(), address(lqtyToken));
    }

    function test_RevertWhenSetStabilityPoolZero() public {
        vm.expectRevert("Invalid stability pool");
        sp().setStabilityPoolAddresses(address(0), address(lusdToken), address(lqtyToken));
    }

    function test_RevertWhenSetLusdZero() public {
        vm.expectRevert("Invalid LUSD token");
        sp().setStabilityPoolAddresses(address(mockStabilityPool), address(0), address(lqtyToken));
    }

    function test_RevertWhenSetLqtyZero() public {
        vm.expectRevert("Invalid LQTY token");
        sp().setStabilityPoolAddresses(address(mockStabilityPool), address(lusdToken), address(0));
    }

    function test_ToggleAutoDeposit() public {
        sp().toggleAutoDeposit(true);
        assertTrue(sp().isAutoDepositEnabled());

        sp().toggleAutoDeposit(false);
        assertFalse(sp().isAutoDepositEnabled());
    }

    // ============ Deposit Tests ============

    function test_DepositToStabilityPool() public {
        sp().setStabilityPoolAddresses(address(mockStabilityPool), address(lusdToken), address(lqtyToken));

        uint256 depositAmount = 1000e18;
        lusdToken.mint(address(diamond), depositAmount);

        sp().depositToStabilityPool(depositAmount);

        assertEq(sp().totalDeposited(), depositAmount);
        assertEq(sp().compoundedLusdDeposit(), depositAmount);
    }

    function test_DepositZeroDoesNothing() public {
        sp().setStabilityPoolAddresses(address(mockStabilityPool), address(lusdToken), address(lqtyToken));
        sp().depositToStabilityPool(0);
        assertEq(sp().totalDeposited(), 0);
    }

    // ============ Withdrawal Tests ============

    function test_WithdrawFromStabilityPool() public {
        sp().setStabilityPoolAddresses(address(mockStabilityPool), address(lusdToken), address(lqtyToken));

        uint256 depositAmount = 1000e18;
        lusdToken.mint(address(diamond), depositAmount);
        sp().depositToStabilityPool(depositAmount);

        uint256 withdrawAmount = 500e18;
        sp().withdrawFromStabilityPool(withdrawAmount);

        assertEq(sp().totalDeposited(), depositAmount - withdrawAmount);
    }

    function test_WithdrawAllFromStabilityPool() public {
        sp().setStabilityPoolAddresses(address(mockStabilityPool), address(lusdToken), address(lqtyToken));

        uint256 depositAmount = 1000e18;
        lusdToken.mint(address(diamond), depositAmount);
        sp().depositToStabilityPool(depositAmount);

        sp().withdrawAllFromStabilityPool();

        assertEq(sp().totalDeposited(), 0);
        assertEq(sp().compoundedLusdDeposit(), 0);
    }

    function test_WithdrawZeroDoesNothing() public {
        sp().setStabilityPoolAddresses(address(mockStabilityPool), address(lusdToken), address(lqtyToken));
        sp().withdrawFromStabilityPool(0);
        assertEq(sp().totalDeposited(), 0);
    }

    // ============ Reward Claim Tests ============

    function test_ClaimRewards() public {
        sp().setStabilityPoolAddresses(address(mockStabilityPool), address(lusdToken), address(lqtyToken));

        uint256 depositAmount = 1000e18;
        lusdToken.mint(address(diamond), depositAmount);
        sp().depositToStabilityPool(depositAmount);

        // Simulate rewards
        uint256 ethReward = 1e18;
        uint256 lqtyReward = 50e18;
        mockStabilityPool.setRewards(address(diamond), ethReward, lqtyReward);

        // Verify pending gains
        assertEq(sp().pendingEthGain(), ethReward);
        assertEq(sp().pendingLqtyGain(), lqtyReward);

        // Claim
        sp().claimStabilityPoolRewards();

        assertEq(sp().accumulatedEthGains(), ethReward);
        assertEq(sp().accumulatedLqtyRewards(), lqtyReward);
        assertEq(sp().pendingEthGain(), 0);
        assertEq(sp().pendingLqtyGain(), 0);
    }

    // ============ Integration Flow Tests ============

    function test_FullDepositWithdrawCycle() public {
        sp().setStabilityPoolAddresses(address(mockStabilityPool), address(lusdToken), address(lqtyToken));
        sp().toggleAutoDeposit(true);

        // Deposit
        uint256 amount = 5000e18;
        lusdToken.mint(address(diamond), amount);
        sp().depositToStabilityPool(amount);

        assertEq(sp().totalDeposited(), amount);
        assertEq(sp().compoundedLusdDeposit(), amount);

        // Simulate rewards accrual
        mockStabilityPool.setRewards(address(diamond), 2e18, 100e18);

        // Claim rewards
        sp().claimStabilityPoolRewards();
        assertEq(sp().accumulatedEthGains(), 2e18);
        assertEq(sp().accumulatedLqtyRewards(), 100e18);

        // Withdraw all (simulating redemption)
        sp().withdrawAllFromStabilityPool();
        assertEq(sp().totalDeposited(), 0);
    }

    function test_DepositAndClaim() public {
        sp().setStabilityPoolAddresses(address(mockStabilityPool), address(lusdToken), address(lqtyToken));

        // First deposit
        uint256 amount1 = 1000e18;
        lusdToken.mint(address(diamond), amount1);
        sp().depositToStabilityPool(amount1);

        // Simulate rewards
        mockStabilityPool.setRewards(address(diamond), 0.5e18, 25e18);

        // Deposit more and claim rewards at the same time
        uint256 amount2 = 500e18;
        lusdToken.mint(address(diamond), amount2);
        sp().depositAndClaim(amount2);

        assertEq(sp().accumulatedEthGains(), 0.5e18);
        assertEq(sp().accumulatedLqtyRewards(), 25e18);
        assertEq(sp().totalDeposited(), amount1 + amount2);
    }

    function test_RevertWhenNotConfigured() public {
        vm.expectRevert("StabilityPool not set");
        sp().depositToStabilityPool(100e18);
    }

    function test_RevertWithdrawWhenNotConfigured() public {
        vm.expectRevert("StabilityPool not set");
        sp().withdrawFromStabilityPool(100e18);
    }
}
