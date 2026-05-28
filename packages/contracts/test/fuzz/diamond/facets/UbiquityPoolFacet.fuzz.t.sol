// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/console.sol";
import "abdk/ABDKMathQuad.sol";
import {DiamondTestSetup} from "../../../../test/diamond/DiamondTestSetup.sol";
import {IDollarAmoMinter} from "../../../../src/dollar/interfaces/IDollarAmoMinter.sol";
import {LibUbiquityPool} from "../../../../src/dollar/libraries/LibUbiquityPool.sol";
import {MockChainLinkFeed} from "../../../../src/dollar/mocks/MockChainLinkFeed.sol";
import {MockERC20} from "../../../../src/dollar/mocks/MockERC20.sol";
import {MockCurveStableSwapNG} from "../../../../src/dollar/mocks/MockCurveStableSwapNG.sol";
import {MockCurveTwocryptoOptimized} from "../../../../src/dollar/mocks/MockCurveTwocryptoOptimized.sol";

contract UbiquityPoolFacetFuzzTest is DiamondTestSetup {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    // mock three tokens: collateral token, stable token, wrapped ETH token
    MockERC20 collateralToken;
    MockERC20 stableToken;
    MockERC20 wethToken;

    // mock three ChainLink price feeds, one for each token
    MockChainLinkFeed collateralTokenPriceFeed;
    MockChainLinkFeed ethUsdPriceFeed;
    MockChainLinkFeed stableUsdPriceFeed;

    // mock two curve pools Stablecoin/Dollar and Governance/WETH
    MockCurveStableSwapNG curveDollarPlainPool;
    MockCurveTwocryptoOptimized curveGovernanceEthPool;

    address user = address(1);

    function setUp() public override {
        super.setUp();

        vm.startPrank(admin);

        collateralToken = new MockERC20("COLLATERAL", "CLT", 18);
        wethToken = new MockERC20("WETH", "WETH", 18);
        stableToken = new MockERC20("STABLE", "STABLE", 18);

        collateralTokenPriceFeed = new MockChainLinkFeed();
        ethUsdPriceFeed = new MockChainLinkFeed();
        stableUsdPriceFeed = new MockChainLinkFeed();

        curveDollarPlainPool = new MockCurveStableSwapNG(
            address(stableToken),
            address(dollarToken)
        );

        curveGovernanceEthPool = new MockCurveTwocryptoOptimized(
            address(governanceToken),
            address(wethToken)
        );

        // add collateral token to the pool
        uint256 poolCeiling = 50_000e18; // max 50_000 of collateral tokens is allowed
        ubiquityPoolFacet.addCollateralToken(
            address(collateralToken),
            address(collateralTokenPriceFeed),
            poolCeiling
        );

        // set collateral price initial feed mock params
        collateralTokenPriceFeed.updateMockParams(
            1, // round id
            100_000_000, // answer, 100_000_000 = $1.00 (chainlink 8 decimals answer is converted to 6 decimals pool price)
            block.timestamp, // started at
            block.timestamp, // updated at
            1 // answered in round
        );

        // set ETH/USD price initial feed mock params
        ethUsdPriceFeed.updateMockParams(
            1, // round id
            2000_00000000, // answer, 2000_00000000 = $2000 (8 decimals)
            block.timestamp, // started at
            block.timestamp, // updated at
            1 // answered in round
        );

        // set stable/USD price feed initial mock params
        stableUsdPriceFeed.updateMockParams(
            1, // round id
            100_000_000, // answer, 100_000_000 = $1.00 (8 decimals)
            block.timestamp, // started at
            block.timestamp, // updated at
            1 // answered in round
        );

        // set ETH/Governance initial price to 20k in Curve pool mock (20k GOV == 1 ETH)
        curveGovernanceEthPool.updateMockParams(20_000e18);

        // set price feed for collateral token
        ubiquityPoolFacet.setCollateralChainLinkPriceFeed(
            address(collateralToken), // collateral token address
            address(collateralTokenPriceFeed), // price feed address
            1 days // price feed staleness threshold in seconds
        );

        // set price feed for ETH/USD pair
        ubiquityPoolFacet.setEthUsdChainLinkPriceFeed(
            address(ethUsdPriceFeed), // price feed address
            1 days // price feed staleness threshold in seconds
        );

        // set price feed for stable/USD pair
        ubiquityPoolFacet.setStableUsdChainLinkPriceFeed(
            address(stableUsdPriceFeed), // price feed address
            1 days // price feed staleness threshold in seconds
        );

        // enable collateral at index 0
        ubiquityPoolFacet.toggleCollateral(0);
        // set mint and redeem initial fees
        ubiquityPoolFacet.setFees(
            0, // collateral index
            10000, // 1% mint fee
            20000 // 2% redeem fee
        );
        // set redemption delay to 2 blocks
        ubiquityPoolFacet.setRedemptionDelayBlocks(2);
        // set mint price threshold to $1.01 and redeem price to $0.99
        ubiquityPoolFacet.setPriceThresholds(1010000, 990000);
        // set collateral ratio to 100%
        ubiquityPoolFacet.setCollateralRatio(1_000_000);
        // set Governance-ETH pool
        ubiquityPoolFacet.setGovernanceEthPoolAddress(
            address(curveGovernanceEthPool)
        );

        // set Curve plain pool in manager facet
        managerFacet.setStableSwapPlainPoolAddress(
            address(curveDollarPlainPool)
        );

        // stop being admin
        vm.stopPrank();

        // mint 2000 Governance tokens to the user
        deal(address(governanceToken), user, 2000e18);
        // mint 2000 collateral tokens to the user
        collateralToken.mint(address(user), 2000e18);
        // user approves the pool to transfer collateral
        vm.prank(user);
        collateralToken.approve(address(ubiquityPoolFacet), 100e18);
    }

    //========================
    // Dollar Mint fuzz tests
    //========================

    function testMintDollar_FuzzCollateralRatio(
        uint256 newCollateralRatio
    ) public {
        uint256 maxCollateralRatio = 1_000_000; // 100%
        vm.assume(newCollateralRatio <= maxCollateralRatio);
        // fuzz collateral ratio
        vm.prank(admin);
        ubiquityPoolFacet.setCollateralRatio(newCollateralRatio);
        curveDollarPlainPool.updateMockParams(1.01e18);
        // set ETH/Governance initial price to 2k in Curve pool mock (2k GOV == 1 ETH, 1 GOV == 1 USD)
        curveGovernanceEthPool.updateMockParams(2_000e18);

        // balances before
        assertEq(collateralToken.balanceOf(address(ubiquityPoolFacet)), 0);
        assertEq(dollarToken.balanceOf(user), 0);
        assertEq(governanceToken.balanceOf(user), 2000e18);
        assertEq(collateralToken.balanceOf(user), 2000e18);

        // dollars and governance tokens should be provided to meet ratio requirements
        uint256 maxCollateralIn;
        uint256 totalCollateralMaxAmount = 100e18; // total collateral from both should be enough to mint Dollar tokens
        if (newCollateralRatio == 0) maxCollateralIn = 0;
        else
            maxCollateralIn = totalCollateralMaxAmount
                .fromUInt()
                .mul(newCollateralRatio.fromUInt())
                .div(maxCollateralRatio.fromUInt())
                .toUInt();
        uint256 maxGovernanceIn = totalCollateralMaxAmount - maxCollateralIn;

        vm.prank(user);
        (
            uint256 totalDollarMint,
            uint256 collateralNeeded,
            uint256 governanceNeeded
        ) = ubiquityPoolFacet.mintDollar(
                0, // collateral index
                100e18, // Dollar amount
                99e18, // min amount of Dollars to mint
                maxCollateralIn, // max collateral to send
                maxGovernanceIn, // max Governance tokens to send
                false // fractional mint allowed
            );

        assertEq(totalDollarMint, 99e18);

        // balances after
        assertEq(dollarToken.balanceOf(user), 99e18);
        assertEq(
            collateralToken.balanceOf(address(ubiquityPoolFacet)),
            collateralNeeded
        );
        assertEq(governanceToken.balanceOf(user), 2000e18 - governanceNeeded);
        assertEq(collateralToken.balanceOf(user), 2000e18 - collateralNeeded);
    }

    /**
     * @notice Fuzz Dollar minting scenario for Dollar price below threshold
     * @param dollarPriceUsd Ubiquity Dollar token price from Curve pool (Stable coin/Ubiquity Dollar)
     */
    function testMintDollar_FuzzDollarPriceUsdTooLow(
        uint256 dollarPriceUsd
    ) public {
        // Stable coin/USD ChainLink feed is mocked to $1.00
        // Mint price threshold set up to $1.01 == 1010000
        // Fuzz Dollar price in Curve plain pool (1 Stable coin / x Dollar)
        vm.assume(dollarPriceUsd < 1010000000000000000); // 1.01e18 , less than threshold
        curveDollarPlainPool.updateMockParams(dollarPriceUsd);
        vm.prank(user);
        vm.expectRevert("Dollar price too low");
        ubiquityPoolFacet.mintDollar(
            0, // collateral index
            100e18, // Dollar amount
            90e18, // min amount of Dollars to mint
            100e18, // max collateral to send
            0, // max Governance tokens to send
            false // force 1-to-1 mint (i.e. provide only collateral without Governance tokens)
        );
    }

    /**
     * @notice Fuzz Dollar minting scenario for Dollar amount slippage. Max slippage is the acceptable
     *         difference between amount asked to mint, and the actual minted amount, including the minting fee.
     *         As an example if mint fee is set to 1%, any value above 99% of the amount should revert
     *         the mint with `Dollar slippage` error.
     * @param dollarOutMin Minimal Ubiquity Dollar amount to mint, including the minting fee.
     */
    function testMintDollar_FuzzDollarAmountSlippage(
        uint256 dollarOutMin
    ) public {
        vm.assume(dollarOutMin > 99e18);
        vm.prank(admin);
        curveDollarPlainPool.updateMockParams(1.01e18);
        vm.prank(user);
        vm.expectRevert("Dollar slippage");
        ubiquityPoolFacet.mintDollar(
            0, // collateral index
            100e18, // Dollar amount
            dollarOutMin, // min amount of Dollars to mint
            100e18, // max collateral to send
            0, // max Governance tokens to send
            false // force 1-to-1 mint (i.e. provide only collateral without Governance tokens)
        );
    }

    function testMintDollar_FuzzCollateralAmountSlippage(
        uint256 maxCollateralIn
    ) public {
        vm.assume(maxCollateralIn < 100e18);
        vm.prank(admin);
        curveDollarPlainPool.updateMockParams(1.01e18);
        vm.prank(user);
        vm.expectRevert("Collateral slippage");
        ubiquityPoolFacet.mintDollar(
            0, // collateral index
            100e18, // Dollar amount
            99e18, // min amount of Dollars to mint
            maxCollateralIn, // max collateral to send
            0, // max Governance tokens to send
            false // force 1-to-1 mint (i.e. provide only collateral without Governance tokens)
        );
    }

    function testMintDollar_FuzzGovernanceAmountSlippage(
        uint256 maxGovernanceIn
    ) public {
        vm.assume(maxGovernanceIn < 1e18);
        vm.prank(admin);
        curveDollarPlainPool.updateMockParams(1.01e18);
        // set ETH/Governance initial price to 2k in Curve pool mock (2k GOV == 1 ETH, 1 GOV == 1 USD)
        curveGovernanceEthPool.updateMockParams(2_000e18);
        // admin sets collateral ratio to 0%
        vm.prank(admin);
        ubiquityPoolFacet.setCollateralRatio(0);
        vm.prank(user);
        vm.expectRevert("Governance slippage");
        ubiquityPoolFacet.mintDollar(
            0, // collateral index
            100e18, // Dollar amount
            99e18, // min amount of Dollars to mint (1% fee included)
            0, // max collateral to send
            maxGovernanceIn, // max Governance tokens to send
            false // force 1-to-1 mint (i.e. provide only collateral without Governance tokens)
        );
    }

    function testMintDollar_FuzzCorrectDollarAmountMinted(
        uint256 tokenAmountToMint
    ) public {
        vm.assume(tokenAmountToMint < 50_000e18); // collateral pool ceiling also set to 50k tokens
        vm.startPrank(admin);
        curveDollarPlainPool.updateMockParams(1.01e18);
        // set ETH/Governance initial price to 2k in Curve pool mock (2k GOV == 1 ETH, 1 GOV == 1 USD)
        curveGovernanceEthPool.updateMockParams(2_000e18);
        // admin sets collateral ratio to 0%
        ubiquityPoolFacet.setCollateralRatio(0);
        deal(address(governanceToken), user, 50000e18);
        vm.stopPrank();
        uint256 minDollarsToMint = tokenAmountToMint
            .fromUInt()
            .mul(uint(99).fromUInt())
            .div(uint(100).fromUInt())
            .toUInt(); // dollars to mint (1% fee included)
        vm.prank(user);
        (uint256 dollarsMinted, , ) = ubiquityPoolFacet.mintDollar(
            0, // collateral index
            tokenAmountToMint, // Dollar amount to mint
            minDollarsToMint,
            0, // max collateral to send
            tokenAmountToMint, // max Governance tokens to send (1 GOV == 1 USD)
            false // force 1-to-1 mint (i.e. provide only collateral without Governance tokens)
        );
        assertEq(dollarsMinted, minDollarsToMint);
    }

    //========================
    // Dollar Redeem fuzz tests
    //========================

    function testRedeemDollar_FuzzRedemptionDelayBlocks(
        uint8 delayBlocks
    ) public {
        vm.assume(delayBlocks > 0);
        vm.startPrank(admin);
        curveDollarPlainPool.updateMockParams(0.99e18);
        collateralToken.mint(address(ubiquityPoolFacet), 100e18);
        dollarToken.mint(address(user), 1e18);
        // set redemption delay to delayBlocks
        ubiquityPoolFacet.setRedemptionDelayBlocks(delayBlocks);
        vm.stopPrank();
        vm.prank(user);
        ubiquityPoolFacet.redeemDollar(
            0, // collateral index
            1e18, // Dollar amount
            0, // min Governance out
            1e17 // min collateral out
        );
        vm.roll(delayBlocks); // redemption possible at delayBlocks + 1 block, before that revert
        vm.expectRevert("Too soon to collect redemption");
        ubiquityPoolFacet.collectRedemption(0);
    }

    /**
     * @notice Fuzz Dollar redeeming scenario for Dollar price above threshold
     * @param dollarPriceUsd Ubiquity Dollar token price from Curve pool (Stable coin/Ubiquity Dollar)
     */
    function testRedeemDollar_FuzzDollarPriceUsdTooHigh(
        uint256 dollarPriceUsd
    ) public {
        // Stable coin/USD ChainLink feed is mocked to $1.00
        // Redeem price threshold set up to $0.99 == 990_000
        // Fuzz Dollar price in Curve plain pool (1 Stable coin / x Dollar)
        vm.assume(dollarPriceUsd > 990000999999999999); // 0.99e18 , greater than redeem threshold
        vm.assume(dollarPriceUsd < 9900000000000000000);
        vm.prank(admin);
        curveDollarPlainPool.updateMockParams(dollarPriceUsd);
        vm.prank(user);
        vm.expectRevert("Dollar price too high");
        ubiquityPoolFacet.redeemDollar(
            0, // collateral index
            1e18, // Dollar amount
            0, // min Governance out
            1e18 // min collateral out
        );
    }

    /**
     * @notice Fuzz Dollar redeeming scenario for insufficient collateral available in pool.
     * @param collateralOut Minimal collateral amount to redeem.
     */
    function testRedeemDollar_FuzzInsufficientCollateralAvailable(
        uint256 collateralOut
    ) public {
        vm.assume(collateralOut > 1e18);
        vm.startPrank(admin);
        curveDollarPlainPool.updateMockParams(0.99e18);
        collateralToken.mint(address(ubiquityPoolFacet), 1e18);
        dollarToken.mint(address(user), 1e18);
        vm.stopPrank();
        vm.prank(user);
        vm.expectRevert("Insufficient pool collateral");
        ubiquityPoolFacet.redeemDollar(
            0, // collateral index
            10e18, // Dollar amount
            0, // min Governance out
            collateralOut // min collateral out
        );
    }

    /**
     * @notice Fuzz Dollar redeeming scenario for collateral slippage.
     * @param collateralOut Minimal collateral amount to redeem.
     */
    function testRedeemDollar_FuzzCollateralSlippage(
        uint256 collateralOut
    ) public {
        vm.assume(collateralOut >= 1e18);
        vm.startPrank(admin);
        curveDollarPlainPool.updateMockParams(0.99e18);
        collateralToken.mint(address(ubiquityPoolFacet), 100e18);
        dollarToken.mint(address(user), 1e18);
        vm.stopPrank();
        vm.prank(user);
        vm.expectRevert("Collateral slippage");
        ubiquityPoolFacet.redeemDollar(
            0, // collateral index
            1e18, // Dollar amount
            0, // min Governance out
            collateralOut // min collateral out
        );
    }

    /**
     * @notice Fuzz Dollar redeeming scenario for governance token slippage.
     * @param governanceOut Minimal governance token amount to redeem.
     */
    function testRedeemDollar_FuzzGovernanceAmountSlippage(
        uint256 governanceOut
    ) public {
        vm.assume(governanceOut >= 1e18);
        vm.startPrank(admin);
        curveDollarPlainPool.updateMockParams(0.99e18);
        collateralToken.mint(address(ubiquityPoolFacet), 100e18);
        dollarToken.mint(address(user), 1e18);
        vm.stopPrank();
        vm.prank(user);
        vm.expectRevert("Governance slippage");
        ubiquityPoolFacet.redeemDollar(
            0, // collateral index
            1e18, // Dollar amount
            governanceOut, // min Governance out
            0 // min collateral out
        );
    }

    function testMintDollar_FuzzCorrectDollarAmountRedeemed(
        uint256 tokenAmountToRedeem
    ) public {
        vm.assume(tokenAmountToRedeem < 50_000e18);
        vm.startPrank(admin);
        curveDollarPlainPool.updateMockParams(0.99e18);
        dollarToken.mint(address(user), tokenAmountToRedeem); // make sure user has enough Dollars
        collateralToken.mint(address(ubiquityPoolFacet), tokenAmountToRedeem); // make sure pool has enough collateral
        uint256 dollarTokenBalanceBeforeRedeem = dollarToken.balanceOf(user);
        vm.stopPrank();
        vm.prank(user);
        ubiquityPoolFacet.redeemDollar(
            0, // collateral index
            tokenAmountToRedeem, // Dollar amount
            0, // min Governance out
            0 // min collateral out
        );
        vm.roll(3); // redemption delay set to 2 blocks
        ubiquityPoolFacet.collectRedemption(0);
        // balances after
        assertEq(
            dollarToken.balanceOf(user),
            dollarTokenBalanceBeforeRedeem - tokenAmountToRedeem
        );
    }
}
