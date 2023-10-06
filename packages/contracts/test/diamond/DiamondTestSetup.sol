// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {Diamond, DiamondArgs} from "../../src/dollar/Diamond.sol";
import {ERC1155Ubiquity} from "../../src/dollar/core/ERC1155Ubiquity.sol";
import {IDiamondCut} from "../../src/dollar/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../../src/dollar/interfaces/IDiamondLoupe.sol";
import {IERC173} from "../../src/dollar/interfaces/IERC173.sol";
import {AccessControlFacet} from "../../src/dollar/facets/AccessControlFacet.sol";
import {BondingCurveFacet} from "../../src/dollar/facets/BondingCurveFacet.sol";
import {ChefFacet} from "../../src/dollar/facets/ChefFacet.sol";
import {CollectableDustFacet} from "../../src/dollar/facets/CollectableDustFacet.sol";
import {CreditNftManagerFacet} from "../../src/dollar/facets/CreditNftManagerFacet.sol";
import {CreditNftRedemptionCalculatorFacet} from "../../src/dollar/facets/CreditNftRedemptionCalculatorFacet.sol";
import {CreditRedemptionCalculatorFacet} from "../../src/dollar/facets/CreditRedemptionCalculatorFacet.sol";
import {CurveDollarIncentiveFacet} from "../../src/dollar/facets/CurveDollarIncentiveFacet.sol";
import {DiamondCutFacet} from "../../src/dollar/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../../src/dollar/facets/DiamondLoupeFacet.sol";
import {DollarMintCalculatorFacet} from "../../src/dollar/facets/DollarMintCalculatorFacet.sol";
import {DollarMintExcessFacet} from "../../src/dollar/facets/DollarMintExcessFacet.sol";
import {ManagerFacet} from "../../src/dollar/facets/ManagerFacet.sol";
import {OwnershipFacet} from "../../src/dollar/facets/OwnershipFacet.sol";
import {StakingFacet} from "../../src/dollar/facets/StakingFacet.sol";
import {StakingFormulasFacet} from "../../src/dollar/facets/StakingFormulasFacet.sol";
import {TWAPOracleDollar3poolFacet} from "../../src/dollar/facets/TWAPOracleDollar3poolFacet.sol";
import {UbiquityPoolFacet} from "../../src/dollar/facets/UbiquityPoolFacet.sol";
import {DiamondInit} from "../../src/dollar/upgradeInitializers/DiamondInit.sol";
import {DiamondTestHelper} from "../helpers/DiamondTestHelper.sol";
import {CREDIT_NFT_MANAGER_ROLE, CREDIT_TOKEN_BURNER_ROLE, CREDIT_TOKEN_MINTER_ROLE, CURVE_DOLLAR_MANAGER_ROLE, DOLLAR_TOKEN_BURNER_ROLE, DOLLAR_TOKEN_MINTER_ROLE, GOVERNANCE_TOKEN_BURNER_ROLE, GOVERNANCE_TOKEN_MANAGER_ROLE, GOVERNANCE_TOKEN_MINTER_ROLE, STAKING_SHARE_MINTER_ROLE} from "../../src/dollar/libraries/Constants.sol";

/**
 * @notice Deploys diamond contract with all of the facets
 */
abstract contract DiamondTestSetup is DiamondTestHelper {
    // diamond related contracts
    Diamond diamond;
    DiamondInit diamondInit;

    // diamond facets (which point to the core diamond and should be used across the tests)
    AccessControlFacet IAccessControl;
    BondingCurveFacet IBondingCurveFacet;
    ChefFacet IChefFacet;
    CollectableDustFacet collectableDustFacet;
    CreditNftManagerFacet creditNftManagerFacet;
    CreditNftRedemptionCalculatorFacet creditNftRedemptionCalculationFacet;
    CreditRedemptionCalculatorFacet creditRedemptionCalculationFacet;
    CurveDollarIncentiveFacet curveDollarIncentiveFacet;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    DollarMintCalculatorFacet dollarMintCalculatorFacet;
    DollarMintExcessFacet dollarMintExcessFacet;
    ManagerFacet managerFacet;
    OwnershipFacet ownershipFacet;
    StakingFacet stakingFacet;
    StakingFormulasFacet stakingFormulasFacet;
    TWAPOracleDollar3poolFacet twapOracleDollar3PoolFacet;
    UbiquityPoolFacet ubiquityPoolFacet;

    // diamond facet implementation instances (should not be used in tests, use only on upgrades)
    AccessControlFacet accessControlFacetImplementation;
    BondingCurveFacet bondingCurveFacetImplementation;
    ChefFacet chefFacetImplementation;
    CollectableDustFacet collectableDustFacetImplementation;
    CreditNftManagerFacet creditNftManagerFacetImplementation;
    CreditNftRedemptionCalculatorFacet creditNftRedemptionCalculatorFacetImplementation;
    CreditRedemptionCalculatorFacet creditRedemptionCalculatorFacetImplementation;
    CurveDollarIncentiveFacet curveDollarIncentiveFacetImplementation;
    DiamondCutFacet diamondCutFacetImplementation;
    DiamondLoupeFacet diamondLoupeFacetImplementation;
    DollarMintCalculatorFacet dollarMintCalculatorFacetImplementation;
    DollarMintExcessFacet dollarMintExcessFacetImplementation;
    ManagerFacet managerFacetImplementation;
    OwnershipFacet ownershipFacetImplementation;
    StakingFacet stakingFacetImplementation;
    StakingFormulasFacet stakingFormulasFacetImplementation;
    TWAPOracleDollar3poolFacet twapOracleDollar3PoolFacetImplementation;
    UbiquityPoolFacet ubiquityPoolFacetImplementation;

    // facet names with addresses
    string[] facetNames;
    address[] facetAddressList;

    // helper addresses
    address owner;
    address admin;
    address user1;
    address contract1;
    address contract2;

    // selectors for all of the facets
    bytes4[] selectorsOfAccessControlFacet;
    bytes4[] selectorsOfBondingCurveFacet;
    bytes4[] selectorsOfChefFacet;
    bytes4[] selectorsOfCollectableDustFacet;
    bytes4[] selectorsOfCreditNftManagerFacet;
    bytes4[] selectorsOfCreditNftRedemptionCalculatorFacet;
    bytes4[] selectorsOfCreditRedemptionCalculatorFacet;
    bytes4[] selectorsOfCurveDollarIncentiveFacet;
    bytes4[] selectorsOfDiamondCutFacet;
    bytes4[] selectorsOfDiamondLoupeFacet;
    bytes4[] selectorsOfDollarMintCalculatorFacet;
    bytes4[] selectorsOfDollarMintExcessFacet;
    bytes4[] selectorsOfManagerFacet;
    bytes4[] selectorsOfOwnershipFacet;
    bytes4[] selectorsOfStakingFacet;
    bytes4[] selectorsOfStakingFormulasFacet;
    bytes4[] selectorsOfTWAPOracleDollar3poolFacet;
    bytes4[] selectorsOfUbiquityPoolFacet;

    /// @notice Deploys diamond and connects facets
    function setUp() public virtual {
        // setup helper addresses
        owner = generateAddress("Owner", false, 10 ether);
        admin = generateAddress("Admin", false, 10 ether);
        user1 = generateAddress("User1", false, 10 ether);
        contract1 = generateAddress("Contract1", true, 10 ether);
        contract2 = generateAddress("Contract2", true, 10 ether);

        // set all function selectors
        // Diamond Cut selectors
        selectorsOfDiamondCutFacet.push(IDiamondCut.diamondCut.selector);

        // Diamond Loupe
        selectorsOfDiamondLoupeFacet.push(
            diamondLoupeFacetImplementation.facets.selector
        );
        selectorsOfDiamondLoupeFacet.push(
            diamondLoupeFacetImplementation.facetFunctionSelectors.selector
        );
        selectorsOfDiamondLoupeFacet.push(
            diamondLoupeFacetImplementation.facetAddresses.selector
        );
        selectorsOfDiamondLoupeFacet.push(
            diamondLoupeFacetImplementation.facetAddress.selector
        );
        selectorsOfDiamondLoupeFacet.push(
            diamondLoupeFacetImplementation.supportsInterface.selector
        );

        // Ownership
        selectorsOfOwnershipFacet.push(IERC173.transferOwnership.selector);
        selectorsOfOwnershipFacet.push(IERC173.owner.selector);

        // Manager selectors
        selectorsOfManagerFacet.push(
            managerFacetImplementation.setCreditTokenAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.setCreditNftAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.setGovernanceTokenAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.setDollarTokenAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.setUbiquistickAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.setSushiSwapPoolAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.setDollarMintCalculatorAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.setExcessDollarsDistributor.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.setMasterChefAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.setFormulasAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.setStakingShareAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.setCurveDollarIncentiveAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.setStableSwapMetaPoolAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.setStakingContractAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.setBondingCurveAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.setTreasuryAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.setIncentiveToDollar.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.deployStableSwapPool.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.twapOracleAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.dollarTokenAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.creditTokenAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.creditNftAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.curve3PoolTokenAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.governanceTokenAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.sushiSwapPoolAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.creditCalculatorAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.creditNftCalculatorAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.dollarMintCalculatorAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.excessDollarsDistributor.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.masterChefAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.formulasAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.stakingShareAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.stableSwapMetaPoolAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.stakingContractAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacetImplementation.treasuryAddress.selector
        );

        // Access Control
        selectorsOfAccessControlFacet.push(
            accessControlFacetImplementation.grantRole.selector
        );
        selectorsOfAccessControlFacet.push(
            accessControlFacetImplementation.hasRole.selector
        );
        selectorsOfAccessControlFacet.push(
            accessControlFacetImplementation.renounceRole.selector
        );
        selectorsOfAccessControlFacet.push(
            accessControlFacetImplementation.getRoleAdmin.selector
        );
        selectorsOfAccessControlFacet.push(
            accessControlFacetImplementation.revokeRole.selector
        );
        selectorsOfAccessControlFacet.push(
            accessControlFacetImplementation.pause.selector
        );
        selectorsOfAccessControlFacet.push(
            accessControlFacetImplementation.unpause.selector
        );
        selectorsOfAccessControlFacet.push(
            accessControlFacetImplementation.paused.selector
        );

        // TWAP Oracle
        selectorsOfTWAPOracleDollar3poolFacet.push(
            twapOracleDollar3PoolFacetImplementation.setPool.selector
        );
        selectorsOfTWAPOracleDollar3poolFacet.push(
            twapOracleDollar3PoolFacetImplementation.update.selector
        );
        selectorsOfTWAPOracleDollar3poolFacet.push(
            twapOracleDollar3PoolFacetImplementation.consult.selector
        );

        // Collectable Dust
        selectorsOfCollectableDustFacet.push(
            collectableDustFacetImplementation.addProtocolToken.selector
        );
        selectorsOfCollectableDustFacet.push(
            collectableDustFacetImplementation.removeProtocolToken.selector
        );
        selectorsOfCollectableDustFacet.push(
            collectableDustFacetImplementation.sendDust.selector
        );
        // Chef
        selectorsOfChefFacet.push(
            chefFacetImplementation.setGovernancePerBlock.selector
        );
        selectorsOfChefFacet.push(
            chefFacetImplementation.governancePerBlock.selector
        );
        selectorsOfChefFacet.push(
            chefFacetImplementation.governanceDivider.selector
        );
        selectorsOfChefFacet.push(
            chefFacetImplementation.minPriceDiffToUpdateMultiplier.selector
        );
        selectorsOfChefFacet.push(
            chefFacetImplementation.setGovernanceShareForTreasury.selector
        );
        selectorsOfChefFacet.push(
            chefFacetImplementation.setMinPriceDiffToUpdateMultiplier.selector
        );
        selectorsOfChefFacet.push(chefFacetImplementation.getRewards.selector);
        selectorsOfChefFacet.push(
            chefFacetImplementation.pendingGovernance.selector
        );
        selectorsOfChefFacet.push(
            chefFacetImplementation.getStakingShareInfo.selector
        );
        selectorsOfChefFacet.push(chefFacetImplementation.totalShares.selector);
        selectorsOfChefFacet.push(chefFacetImplementation.pool.selector);

        // Staking
        selectorsOfStakingFacet.push(
            stakingFacetImplementation.dollarPriceReset.selector
        );
        selectorsOfStakingFacet.push(
            stakingFacetImplementation.crvPriceReset.selector
        );
        selectorsOfStakingFacet.push(
            stakingFacetImplementation.setStakingDiscountMultiplier.selector
        );
        selectorsOfStakingFacet.push(
            stakingFacetImplementation.stakingDiscountMultiplier.selector
        );
        selectorsOfStakingFacet.push(
            stakingFacetImplementation.setBlockCountInAWeek.selector
        );
        selectorsOfStakingFacet.push(
            stakingFacetImplementation.blockCountInAWeek.selector
        );
        selectorsOfStakingFacet.push(
            stakingFacetImplementation.deposit.selector
        );
        selectorsOfStakingFacet.push(
            stakingFacetImplementation.addLiquidity.selector
        );
        selectorsOfStakingFacet.push(
            stakingFacetImplementation.removeLiquidity.selector
        );
        selectorsOfStakingFacet.push(
            stakingFacetImplementation.pendingLpRewards.selector
        );
        selectorsOfStakingFacet.push(
            stakingFacetImplementation.lpRewardForShares.selector
        );
        selectorsOfStakingFacet.push(
            stakingFacetImplementation.currentShareValue.selector
        );

        // UbiquityPool
        selectorsOfUbiquityPoolFacet.push(
            ubiquityPoolFacetImplementation.mintDollar.selector
        );
        selectorsOfUbiquityPoolFacet.push(
            ubiquityPoolFacetImplementation.redeemDollar.selector
        );
        selectorsOfUbiquityPoolFacet.push(
            ubiquityPoolFacetImplementation.collectRedemption.selector
        );
        selectorsOfUbiquityPoolFacet.push(
            ubiquityPoolFacetImplementation.addToken.selector
        );
        selectorsOfUbiquityPoolFacet.push(
            ubiquityPoolFacetImplementation.setRedeemActive.selector
        );
        selectorsOfUbiquityPoolFacet.push(
            ubiquityPoolFacetImplementation.getRedeemActive.selector
        );
        selectorsOfUbiquityPoolFacet.push(
            ubiquityPoolFacetImplementation.setMintActive.selector
        );
        selectorsOfUbiquityPoolFacet.push(
            ubiquityPoolFacetImplementation.getRedeemCollateralBalances.selector
        );
        selectorsOfUbiquityPoolFacet.push(
            ubiquityPoolFacetImplementation.getMintActive.selector
        );

        // Staking Formulas
        selectorsOfStakingFormulasFacet.push(
            stakingFormulasFacetImplementation.sharesForLP.selector
        );
        selectorsOfStakingFormulasFacet.push(
            stakingFormulasFacetImplementation
                .lpRewardsRemoveLiquidityNormalization
                .selector
        );
        selectorsOfStakingFormulasFacet.push(
            stakingFormulasFacetImplementation
                .lpRewardsAddLiquidityNormalization
                .selector
        );
        selectorsOfStakingFormulasFacet.push(
            stakingFormulasFacetImplementation
                .correctedAmountToWithdraw
                .selector
        );
        selectorsOfStakingFormulasFacet.push(
            stakingFormulasFacetImplementation.durationMultiply.selector
        );

        // Bonding Curve
        selectorsOfBondingCurveFacet.push(
            bondingCurveFacetImplementation.setParams.selector
        );
        selectorsOfBondingCurveFacet.push(
            bondingCurveFacetImplementation.connectorWeight.selector
        );
        selectorsOfBondingCurveFacet.push(
            bondingCurveFacetImplementation.baseY.selector
        );
        selectorsOfBondingCurveFacet.push(
            bondingCurveFacetImplementation.poolBalance.selector
        );
        selectorsOfBondingCurveFacet.push(
            bondingCurveFacetImplementation.deposit.selector
        );
        selectorsOfBondingCurveFacet.push(
            bondingCurveFacetImplementation.getShare.selector
        );
        selectorsOfBondingCurveFacet.push(
            bondingCurveFacetImplementation.withdraw.selector
        );
        selectorsOfBondingCurveFacet.push(
            bondingCurveFacetImplementation.purchaseTargetAmount.selector
        );
        selectorsOfBondingCurveFacet.push(
            bondingCurveFacetImplementation
                .purchaseTargetAmountFromZero
                .selector
        );

        // Curve Dollar Incentive Facet
        selectorsOfCurveDollarIncentiveFacet.push(
            curveDollarIncentiveFacetImplementation.incentivize.selector
        );
        selectorsOfCurveDollarIncentiveFacet.push(
            curveDollarIncentiveFacetImplementation.setExemptAddress.selector
        );
        selectorsOfCurveDollarIncentiveFacet.push(
            curveDollarIncentiveFacetImplementation.switchSellPenalty.selector
        );
        selectorsOfCurveDollarIncentiveFacet.push(
            curveDollarIncentiveFacetImplementation.switchBuyIncentive.selector
        );
        selectorsOfCurveDollarIncentiveFacet.push(
            curveDollarIncentiveFacetImplementation.isExemptAddress.selector
        );
        selectorsOfCurveDollarIncentiveFacet.push(
            curveDollarIncentiveFacetImplementation.isSellPenaltyOn.selector
        );
        selectorsOfCurveDollarIncentiveFacet.push(
            curveDollarIncentiveFacetImplementation.isBuyIncentiveOn.selector
        );

        // Credit facets
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacetImplementation.creditNftLengthBlocks.selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacetImplementation
                .expiredCreditNftConversionRate
                .selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacetImplementation
                .setExpiredCreditNftConversionRate
                .selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacetImplementation.setCreditNftLength.selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacetImplementation
                .exchangeDollarsForCreditNft
                .selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacetImplementation
                .exchangeDollarsForCredit
                .selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacetImplementation
                .getCreditNftReturnedForDollars
                .selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacetImplementation
                .getCreditReturnedForDollars
                .selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacetImplementation.onERC1155Received.selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacetImplementation.onERC1155BatchReceived.selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacetImplementation
                .burnExpiredCreditNftForGovernance
                .selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacetImplementation.burnCreditNftForCredit.selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacetImplementation
                .burnCreditTokensForDollars
                .selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacetImplementation.redeemCreditNft.selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacetImplementation.mintClaimableDollars.selector
        );

        // Credit NFT Redemption Calculator
        selectorsOfCreditNftRedemptionCalculatorFacet.push(
            creditNftRedemptionCalculatorFacetImplementation
                .getCreditNftAmount
                .selector
        );

        // Credit Redemption Calculator
        selectorsOfCreditRedemptionCalculatorFacet.push(
            (creditRedemptionCalculatorFacetImplementation.setConstant.selector)
        );
        selectorsOfCreditRedemptionCalculatorFacet.push(
            (creditRedemptionCalculatorFacetImplementation.getConstant.selector)
        );
        selectorsOfCreditRedemptionCalculatorFacet.push(
            (
                creditRedemptionCalculatorFacetImplementation
                    .getCreditAmount
                    .selector
            )
        );

        // Dollar Mint Calculator
        selectorsOfDollarMintCalculatorFacet.push(
            (dollarMintCalculatorFacetImplementation.getDollarsToMint.selector)
        );
        // Dollar Mint Excess
        selectorsOfDollarMintExcessFacet.push(
            (dollarMintExcessFacetImplementation.distributeDollars.selector)
        );

        // deploy facet implementation instances
        accessControlFacetImplementation = new AccessControlFacet();
        bondingCurveFacetImplementation = new BondingCurveFacet();
        chefFacetImplementation = new ChefFacet();
        collectableDustFacetImplementation = new CollectableDustFacet();
        creditNftManagerFacetImplementation = new CreditNftManagerFacet();
        creditNftRedemptionCalculatorFacetImplementation = new CreditNftRedemptionCalculatorFacet();
        creditRedemptionCalculatorFacetImplementation = new CreditRedemptionCalculatorFacet();
        curveDollarIncentiveFacetImplementation = new CurveDollarIncentiveFacet();
        diamondCutFacetImplementation = new DiamondCutFacet();
        diamondLoupeFacetImplementation = new DiamondLoupeFacet();
        dollarMintCalculatorFacetImplementation = new DollarMintCalculatorFacet();
        dollarMintExcessFacetImplementation = new DollarMintExcessFacet();
        managerFacetImplementation = new ManagerFacet();
        ownershipFacetImplementation = new OwnershipFacet();
        stakingFacetImplementation = new StakingFacet();
        stakingFormulasFacetImplementation = new StakingFormulasFacet();
        twapOracleDollar3PoolFacetImplementation = new TWAPOracleDollar3poolFacet();
        ubiquityPoolFacetImplementation = new UbiquityPoolFacet();

        // prepare diamond init args
        diamondInit = new DiamondInit();
        facetNames = [
            "AccessControlFacet",
            "BondingCurveFacet",
            "ChefFacet",
            "CollectableDustFacet",
            "CreditNftManagerFacet",
            "CreditNftRedemptionCalculatorFacet",
            "CreditRedemptionCalculatorFacet",
            "CurveDollarIncentiveFacet",
            "DiamondCutFacet",
            "DiamondLoupeFacet",
            "DollarMintCalculatorFacet",
            "DollarMintExcessFacet",
            "ManagerFacet",
            "OwnershipFacet",
            "StakingFacet",
            "StakingFormulasFacet",
            "TWAPOracleDollar3poolFacet",
            "UbiquityPoolFacet"
        ];
        DiamondInit.Args memory initArgs = DiamondInit.Args({
            admin: admin,
            tos: new address[](0),
            amounts: new uint256[](0),
            stakingShareIDs: new uint256[](0),
            governancePerBlock: 10e18,
            creditNftLengthBlocks: 100
        });
        // diamond arguments
        DiamondArgs memory _args = DiamondArgs({
            owner: owner,
            init: address(diamondInit),
            initCalldata: abi.encodeWithSelector(
                DiamondInit.init.selector,
                initArgs
            )
        });

        FacetCut[] memory cuts = new FacetCut[](18);

        cuts[0] = (
            FacetCut({
                facetAddress: address(accessControlFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfAccessControlFacet
            })
        );
        cuts[1] = (
            FacetCut({
                facetAddress: address(bondingCurveFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfBondingCurveFacet
            })
        );
        cuts[2] = (
            FacetCut({
                facetAddress: address(chefFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfChefFacet
            })
        );
        cuts[3] = (
            FacetCut({
                facetAddress: address(collectableDustFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfCollectableDustFacet
            })
        );
        cuts[4] = (
            FacetCut({
                facetAddress: address(creditNftManagerFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfCreditNftManagerFacet
            })
        );
        cuts[5] = (
            FacetCut({
                facetAddress: address(
                    creditNftRedemptionCalculatorFacetImplementation
                ),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfCreditNftRedemptionCalculatorFacet
            })
        );
        cuts[6] = (
            FacetCut({
                facetAddress: address(
                    creditRedemptionCalculatorFacetImplementation
                ),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfCreditRedemptionCalculatorFacet
            })
        );
        cuts[7] = (
            FacetCut({
                facetAddress: address(curveDollarIncentiveFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfCurveDollarIncentiveFacet
            })
        );
        cuts[8] = (
            FacetCut({
                facetAddress: address(diamondCutFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfDiamondCutFacet
            })
        );
        cuts[9] = (
            FacetCut({
                facetAddress: address(diamondLoupeFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfDiamondLoupeFacet
            })
        );
        cuts[10] = (
            FacetCut({
                facetAddress: address(dollarMintCalculatorFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfDollarMintCalculatorFacet
            })
        );
        cuts[11] = (
            FacetCut({
                facetAddress: address(dollarMintExcessFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfDollarMintExcessFacet
            })
        );
        cuts[12] = (
            FacetCut({
                facetAddress: address(managerFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfManagerFacet
            })
        );
        cuts[13] = (
            FacetCut({
                facetAddress: address(ownershipFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfOwnershipFacet
            })
        );
        cuts[14] = (
            FacetCut({
                facetAddress: address(stakingFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfStakingFacet
            })
        );
        cuts[15] = (
            FacetCut({
                facetAddress: address(stakingFormulasFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfStakingFormulasFacet
            })
        );
        cuts[16] = (
            FacetCut({
                facetAddress: address(twapOracleDollar3PoolFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfTWAPOracleDollar3poolFacet
            })
        );
        cuts[17] = (
            FacetCut({
                facetAddress: address(ubiquityPoolFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfUbiquityPoolFacet
            })
        );

        // deploy diamond
        vm.prank(owner);
        diamond = new Diamond(_args, cuts);

        // initialize diamond facets which point to the core diamond contract
        IAccessControl = AccessControlFacet(address(diamond));
        IBondingCurveFacet = BondingCurveFacet(address(diamond));
        IChefFacet = ChefFacet(address(diamond));
        collectableDustFacet = CollectableDustFacet(address(diamond));
        creditNftManagerFacet = CreditNftManagerFacet(address(diamond));
        creditNftRedemptionCalculationFacet = CreditNftRedemptionCalculatorFacet(
            address(diamond)
        );
        creditRedemptionCalculationFacet = CreditRedemptionCalculatorFacet(
            address(diamond)
        );
        curveDollarIncentiveFacet = CurveDollarIncentiveFacet(address(diamond));
        diamondCutFacet = DiamondCutFacet(address(diamond));
        diamondLoupeFacet = DiamondLoupeFacet(address(diamond));
        dollarMintCalculatorFacet = DollarMintCalculatorFacet(address(diamond));
        dollarMintExcessFacet = DollarMintExcessFacet(address(diamond));
        managerFacet = ManagerFacet(address(diamond));
        ownershipFacet = OwnershipFacet(address(diamond));
        stakingFacet = StakingFacet(address(diamond));
        stakingFormulasFacet = StakingFormulasFacet(address(diamond));
        twapOracleDollar3PoolFacet = TWAPOracleDollar3poolFacet(
            address(diamond)
        );
        ubiquityPoolFacet = UbiquityPoolFacet(address(diamond));

        // get all addresses
        facetAddressList = diamondLoupeFacet.facetAddresses();
        vm.startPrank(admin);
        // grant diamond dollar minting and burning rights
        IAccessControl.grantRole(CURVE_DOLLAR_MANAGER_ROLE, address(diamond));
        // grant diamond dollar minting and burning rights
        IAccessControl.grantRole(DOLLAR_TOKEN_MINTER_ROLE, address(diamond));
        IAccessControl.grantRole(DOLLAR_TOKEN_BURNER_ROLE, address(diamond));
        // grand diamond Credit token minting and burning rights
        IAccessControl.grantRole(CREDIT_TOKEN_MINTER_ROLE, address(diamond));
        IAccessControl.grantRole(CREDIT_TOKEN_BURNER_ROLE, address(diamond));
        // grant diamond token admin rights
        IAccessControl.grantRole(
            GOVERNANCE_TOKEN_MANAGER_ROLE,
            address(diamond)
        );
        // grant diamond token minter rights
        IAccessControl.grantRole(STAKING_SHARE_MINTER_ROLE, address(diamond));
        // init UUPS core contracts
        __setupUUPS(address(diamond));
        vm.stopPrank();
    }
}
