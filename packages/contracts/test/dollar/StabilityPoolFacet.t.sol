// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Diamond, DiamondArgs} from "../../src/dollar/Diamond.sol";
import {IDiamondCut} from "../../src/dollar/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../../src/dollar/interfaces/IDiamondLoupe.sol";
import {DiamondCutFacet} from "../../src/dollar/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../../src/dollar/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../../src/dollar/facets/OwnershipFacet.sol";
import {AccessControlFacet} from "../../src/dollar/facets/AccessControlFacet.sol";
import {ManagerFacet} from "../../src/dollar/facets/ManagerFacet.sol";
import {StabilityPoolFacet} from "../../src/dollar/facets/StabilityPoolFacet.sol";
import {ILiquityStabilityPool} from "../../src/dollar/interfaces/ILiquityStabilityPool.sol";
import {MockERC20} from "../../src/dollar/mocks/MockERC20.sol";
import {MockLiquityStabilityPool} from "../../src/dollar/mocks/MockLiquityStabilityPool.sol";
import {DiamondInit} from "../../src/dollar/upgradeInitializers/DiamondInit.sol";
import {LibStabilityPool} from "../../src/dollar/libraries/LibStabilityPool.sol";

/// @title MockLiquityStabilityPool
/// @notice Mock implementation of the Liquity Stability Pool for testing
contract MockLiquityStabilityPool is ILiquityStabilityPool {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public ethGains;
    mapping(address => uint256) public lqtyGains;
    uint256 public totalDeposits;

    function provideToSP(uint256 _amount) external override {
        provideToSP(_amount, address(0));
    }

    function provideToSP(uint256 _amount, address) public override {
        deposits[msg.sender] += _amount;
        totalDeposits += _amount;
        emit UserDepositChanged(msg.sender, deposits[msg.sender]);
    }

    function withdrawFromSP(uint256 _amount) external override {
        uint256 toWithdraw = _amount;
        if (toWithdraw > deposits[msg.sender]) {
            toWithdraw = deposits[msg.sender];
        }
        deposits[msg.sender] -= toWithdraw;
        totalDeposits -= toWithdraw;

        // Auto-claim rewards on withdrawal
        uint256 eth = ethGains[msg.sender];
        uint256 lqty = lqtyGains[msg.sender];
        ethGains[msg.sender] = 0;
        lqtyGains[msg.sender] = 0;

        if (eth > 0) emit ETHGainWithdrawn(msg.sender, eth, 0);
        if (lqty > 0) emit LQTYPaidToDepositor(msg.sender, lqty);
    }

    function withdrawFromSP() external override {
        withdrawFromSP(deposits[msg.sender]);
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

    // Unused events but required by interface
    event UserDepositChanged(address indexed _depositor, uint256 _newDeposit);
    event ETHGainWithdrawn(address indexed _depositor, uint256 _ETH, uint256 _LUSDLoss);
    event LQTYPaidToDepositor(address indexed _depositor, uint256 _LQTY);
    event EpochUpdated(uint128 _currentEpoch);
    event SnapshotUpdated(uint128 _currentEpoch, uint128 _currentEpochScaled);
}

contract StabilityPoolFacetTest is Test {
    Diamond diamond;
    DiamondInit diamondInit;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    OwnershipFacet ownershipFacet;
    AccessControlFacet accessControlFacet;
    ManagerFacet managerFacet;
    StabilityPoolFacet stabilityPoolFacet;

    MockERC20 lusdToken;
    MockERC20 lqtyToken;
    MockLiquityStabilityPool mockStabilityPool;

    address owner;
    address admin;
    address user1;

    function setUp() public {
        owner = address(this);
        admin = makeAddr("admin");
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
        managerFacet = new ManagerFacet();
        stabilityPoolFacet = new StabilityPoolFacet();
        diamondInit = new DiamondInit();

        // Prepare selectors for base facets
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

        bytes4[] memory managerSelectors = new bytes4[](1);
        managerSelectors[0] = ManagerFacet.setDollarTokenAddress.selector;

        // StabilityPoolFacet selectors
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
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](6);
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondCutFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: cutSelectors
        });
        cuts[1] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });
        cuts[2] = IDiamondCut.FacetCut({
            facetAddress: address(ownershipFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: ownershipSelectors
        });
        cuts[3] = IDiamondCut.FacetCut({
            facetAddress: address(accessControlFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: acSelectors
        });
        cuts[4] = IDiamondCut.FacetCut({
            facetAddress: address(managerFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: managerSelectors
        });
        cuts[5] = IDiamondCut.FacetCut({
            facetAddress: address(stabilityPoolFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: spSelectors
        });

        DiamondArgs memory args = DiamondArgs({
            owner: owner,
            init: address(0),
            initCalldata: ""
        });

        diamond = new Diamond(args);

        // Add facets via diamond cut
        IDiamondCut(address(diamond)).diamondCut(cuts, address(0), "");

        // Setup: configure stability pool addresses (need admin role)
        // For testing, we'll interact directly with the facet through the diamond
    }

    /// @dev Helper to get StabilityPoolFacet at diamond address
    function spFacet() internal view returns (StabilityPoolFacet) {
        return StabilityPoolFacet(address(diamond));
    }

    // ============ View Tests ============

    function test_InitialValuesAreZero() public view {
        assertEq(spFacet().stabilityPoolAddress(), address(0));
        assertEq(spFacet().lusdTokenAddress(), address(0));
        assertEq(spFacet().lqtyTokenAddress(), address(0));
        assertFalse(spFacet().isAutoDepositEnabled());
        assertEq(spFacet().totalDeposited(), 0);
        assertEq(spFacet().accumulatedEthGains(), 0);
        assertEq(spFacet().accumulatedLqtyRewards(), 0);
        assertEq(spFacet().compoundedLusdDeposit(), 0);
        assertEq(spFacet().pendingEthGain(), 0);
        assertEq(spFacet().pendingLqtyGain(), 0);
    }

    // ============ Admin Tests ============

    function test_SetStabilityPoolAddresses() public {
        // Grant admin role to this address (owner)
        AccessControlFacet(address(diamond)).grantRole(0x00, owner);

        spFacet().setStabilityPoolAddresses(
            address(mockStabilityPool),
            address(lusdToken),
            address(lqtyToken)
        );

        assertEq(spFacet().stabilityPoolAddress(), address(mockStabilityPool));
        assertEq(spFacet().lusdTokenAddress(), address(lusdToken));
        assertEq(spFacet().lqtyTokenAddress(), address(lqtyToken));
    }

    function test_RevertWhenSetAddressesWithZero() public {
        AccessControlFacet(address(diamond)).grantRole(0x00, owner);
        vm.expectRevert("Invalid stability pool");
        spFacet().setStabilityPoolAddresses(address(0), address(lusdToken), address(lqtyToken));
    }

    function test_ToggleAutoDeposit() public {
        AccessControlFacet(address(diamond)).grantRole(0x00, owner);
        spFacet().toggleAutoDeposit(true);
        assertTrue(spFacet().isAutoDepositEnabled());

        spFacet().toggleAutoDeposit(false);
        assertFalse(spFacet().isAutoDepositEnabled());
    }

    // ============ Deposit Tests ============

    function test_DepositToStabilityPool() public {
        // Setup
        spFacet().setStabilityPoolAddresses(
            address(mockStabilityPool),
            address(lusdToken),
            address(lqtyToken)
        );

        // Mint LUSD to diamond
        uint256 depositAmount = 1000e18;
        lusdToken.mint(address(diamond), depositAmount);

        // Deposit
        spFacet().depositToStabilityPool(depositAmount);

        assertEq(spFacet().totalDeposited(), depositAmount);
        assertEq(spFacet().compoundedLusdDeposit(), depositAmount);
    }

    function test_DepositZeroDoesNothing() public {
        spFacet().setStabilityPoolAddresses(
            address(mockStabilityPool),
            address(lusdToken),
            address(lqtyToken)
        );

        spFacet().depositToStabilityPool(0);
        assertEq(spFacet().totalDeposited(), 0);
    }

    // ============ Withdrawal Tests ============

    function test_WithdrawFromStabilityPool() public {
        // Setup and deposit
        spFacet().setStabilityPoolAddresses(
            address(mockStabilityPool),
            address(lusdToken),
            address(lqtyToken)
        );

        uint256 depositAmount = 1000e18;
        lusdToken.mint(address(diamond), depositAmount);
        spFacet().depositToStabilityPool(depositAmount);

        // Withdraw half
        uint256 withdrawAmount = 500e18;
        spFacet().withdrawFromStabilityPool(withdrawAmount);

        assertEq(spFacet().totalDeposited(), depositAmount - withdrawAmount);
    }

    function test_WithdrawAllFromStabilityPool() public {
        // Setup and deposit
        spFacet().setStabilityPoolAddresses(
            address(mockStabilityPool),
            address(lusdToken),
            address(lqtyToken)
        );

        uint256 depositAmount = 1000e18;
        lusdToken.mint(address(diamond), depositAmount);
        spFacet().depositToStabilityPool(depositAmount);

        // Withdraw all
        spFacet().withdrawAllFromStabilityPool();

        assertEq(spFacet().totalDeposited(), 0);
        assertEq(spFacet().compoundedLusdDeposit(), 0);
    }

    function test_WithdrawZeroDoesNothing() public {
        spFacet().setStabilityPoolAddresses(
            address(mockStabilityPool),
            address(lusdToken),
            address(lqtyToken)
        );

        spFacet().withdrawFromStabilityPool(0);
        assertEq(spFacet().totalDeposited(), 0);
    }

    // ============ Reward Claim Tests ============

    function test_ClaimRewards() public {
        // Setup and deposit
        spFacet().setStabilityPoolAddresses(
            address(mockStabilityPool),
            address(lusdToken),
            address(lqtyToken)
        );

        uint256 depositAmount = 1000e18;
        lusdToken.mint(address(diamond), depositAmount);
        spFacet().depositToStabilityPool(depositAmount);

        // Simulate rewards
        uint256 ethReward = 1e18;
        uint256 lqtyReward = 50e18;
        mockStabilityPool.setRewards(address(diamond), ethReward, lqtyReward);

        // Verify pending gains
        assertEq(spFacet().pendingEthGain(), ethReward);
        assertEq(spFacet().pendingLqtyGain(), lqtyReward);

        // Claim
        spFacet().claimStabilityPoolRewards();

        assertEq(spFacet().accumulatedEthGains(), ethReward);
        assertEq(spFacet().accumulatedLqtyRewards(), lqtyReward);
        assertEq(spFacet().pendingEthGain(), 0);
        assertEq(spFacet().pendingLqtyGain(), 0);
    }

    // ============ Integration Flow Tests ============

    function test_FullDepositWithdrawCycle() public {
        // Setup
        spFacet().setStabilityPoolAddresses(
            address(mockStabilityPool),
            address(lusdToken),
            address(lqtyToken)
        );
        spFacet().toggleAutoDeposit(true);

        // Deposit
        uint256 amount = 5000e18;
        lusdToken.mint(address(diamond), amount);
        spFacet().depositToStabilityPool(amount);

        assertEq(spFacet().totalDeposited(), amount);
        assertEq(spFacet().compoundedLusdDeposit(), amount);

        // Simulate rewards accrual
        mockStabilityPool.setRewards(address(diamond), 2e18, 100e18);

        // Claim rewards
        spFacet().claimStabilityPoolRewards();
        assertEq(spFacet().accumulatedEthGains(), 2e18);
        assertEq(spFacet().accumulatedLqtyRewards(), 100e18);

        // Withdraw all (simulating redemption)
        spFacet().withdrawAllFromStabilityPool();
        assertEq(spFacet().totalDeposited(), 0);
    }

    function test_RevertWhenNotConfigured() public {
        vm.expectRevert("StabilityPool not set");
        spFacet().depositToStabilityPool(100e18);
    }
}
