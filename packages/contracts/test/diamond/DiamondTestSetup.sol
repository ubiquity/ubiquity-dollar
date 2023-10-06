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
    CollectableDustFacet ICollectableDustFacet;
    CreditNftManagerFacet ICreditNftManagerFacet;
    CreditNftRedemptionCalculatorFacet ICreditNftRedemptionCalculationFacet;
    CreditRedemptionCalculatorFacet ICreditRedemptionCalculationFacet;
    CurveDollarIncentiveFacet ICurveDollarIncentiveFacet;
    IDiamondCut ICut;
    IDiamondLoupe ILoupe;
    DollarMintCalculatorFacet IDollarMintCalcFacet;
    DollarMintExcessFacet IDollarMintExcessFacet;
    ManagerFacet IManager;
    OwnershipFacet IOwnershipFacet;
    StakingFacet IStakingFacet;
    StakingFormulasFacet IStakingFormulasFacet;
    TWAPOracleDollar3poolFacet ITWAPOracleDollar3pool;
    UbiquityPoolFacet IUbiquityPoolFacet;

    // diamond facet implementation instances (should not be used in tests, use only on upgrades)
    AccessControlFacet accessControlFacet;
    BondingCurveFacet bondingCurveFacet;
    ChefFacet chefFacet;
    CollectableDustFacet collectableDustFacet;
    CreditNftManagerFacet creditNftManagerFacet;
    CreditNftRedemptionCalculatorFacet creditNftRedemptionCalculatorFacet;
    CreditRedemptionCalculatorFacet creditRedemptionCalculatorFacet;
    CurveDollarIncentiveFacet curveDollarIncentiveFacet;
    DiamondCutFacet diamondCutFacetImplementation;
    DiamondLoupeFacet dLoupeFacet;
    DollarMintCalculatorFacet dollarMintCalculatorFacet;
    DollarMintExcessFacet dollarMintExcessFacet;
    ManagerFacet managerFacet;
    OwnershipFacet ownerFacet;
    StakingFacet stakingFacet;
    StakingFormulasFacet stakingFormulasFacet;
    TWAPOracleDollar3poolFacet twapOracleDollar3PoolFacet;
    UbiquityPoolFacet ubiquityPoolFacet;

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
        owner = generateAddress("Owner", false, 10 ether);
        admin = generateAddress("Admin", false, 10 ether);

        user1 = generateAddress("User1", false, 10 ether);
        contract1 = generateAddress("Contract1", true, 10 ether);
        contract2 = generateAddress("Contract2", true, 10 ether);

        // set all function selectors
        // Diamond Cut selectors
        selectorsOfDiamondCutFacet.push(IDiamondCut.diamondCut.selector);

        // Diamond Loupe
        selectorsOfDiamondLoupeFacet.push(IDiamondLoupe.facets.selector);
        selectorsOfDiamondLoupeFacet.push(
            IDiamondLoupe.facetFunctionSelectors.selector
        );
        selectorsOfDiamondLoupeFacet.push(
            IDiamondLoupe.facetAddresses.selector
        );
        selectorsOfDiamondLoupeFacet.push(IDiamondLoupe.facetAddress.selector);
        selectorsOfDiamondLoupeFacet.push(IERC165.supportsInterface.selector);

        // Ownership
        selectorsOfOwnershipFacet.push(IERC173.transferOwnership.selector);
        selectorsOfOwnershipFacet.push(IERC173.owner.selector);

        // Manager selectors
        selectorsOfManagerFacet.push(
            managerFacet.setCreditTokenAddress.selector
        );
        selectorsOfManagerFacet.push(managerFacet.setCreditNftAddress.selector);
        selectorsOfManagerFacet.push(
            managerFacet.setGovernanceTokenAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacet.setDollarTokenAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacet.setUbiquistickAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacet.setSushiSwapPoolAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacet.setDollarMintCalculatorAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacet.setExcessDollarsDistributor.selector
        );
        selectorsOfManagerFacet.push(
            managerFacet.setMasterChefAddress.selector
        );
        selectorsOfManagerFacet.push(managerFacet.setFormulasAddress.selector);
        selectorsOfManagerFacet.push(
            managerFacet.setStakingShareAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacet.setCurveDollarIncentiveAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacet.setStableSwapMetaPoolAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacet.setStakingContractAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacet.setBondingCurveAddress.selector
        );
        selectorsOfManagerFacet.push(managerFacet.setTreasuryAddress.selector);
        selectorsOfManagerFacet.push(
            managerFacet.setIncentiveToDollar.selector
        );
        selectorsOfManagerFacet.push(
            managerFacet.deployStableSwapPool.selector
        );
        selectorsOfManagerFacet.push(managerFacet.twapOracleAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.dollarTokenAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.creditTokenAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.creditNftAddress.selector);
        selectorsOfManagerFacet.push(
            managerFacet.curve3PoolTokenAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacet.governanceTokenAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacet.sushiSwapPoolAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacet.creditCalculatorAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacet.creditNftCalculatorAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacet.dollarMintCalculatorAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacet.excessDollarsDistributor.selector
        );
        selectorsOfManagerFacet.push(managerFacet.masterChefAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.formulasAddress.selector);
        selectorsOfManagerFacet.push(managerFacet.stakingShareAddress.selector);
        selectorsOfManagerFacet.push(
            managerFacet.stableSwapMetaPoolAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacet.stakingContractAddress.selector
        );
        selectorsOfManagerFacet.push(managerFacet.treasuryAddress.selector);

        // Access Control
        selectorsOfAccessControlFacet.push(
            accessControlFacet.grantRole.selector
        );
        selectorsOfAccessControlFacet.push(accessControlFacet.hasRole.selector);
        selectorsOfAccessControlFacet.push(
            accessControlFacet.renounceRole.selector
        );
        selectorsOfAccessControlFacet.push(
            accessControlFacet.getRoleAdmin.selector
        );
        selectorsOfAccessControlFacet.push(
            accessControlFacet.revokeRole.selector
        );
        selectorsOfAccessControlFacet.push(accessControlFacet.pause.selector);
        selectorsOfAccessControlFacet.push(accessControlFacet.unpause.selector);
        selectorsOfAccessControlFacet.push(accessControlFacet.paused.selector);

        // TWAP Oracle
        selectorsOfTWAPOracleDollar3poolFacet.push(
            twapOracleDollar3PoolFacet.setPool.selector
        );
        selectorsOfTWAPOracleDollar3poolFacet.push(
            twapOracleDollar3PoolFacet.update.selector
        );
        selectorsOfTWAPOracleDollar3poolFacet.push(
            twapOracleDollar3PoolFacet.consult.selector
        );

        // Collectable Dust
        selectorsOfCollectableDustFacet.push(
            collectableDustFacet.addProtocolToken.selector
        );
        selectorsOfCollectableDustFacet.push(
            collectableDustFacet.removeProtocolToken.selector
        );
        selectorsOfCollectableDustFacet.push(
            collectableDustFacet.sendDust.selector
        );
        // Chef
        selectorsOfChefFacet.push(chefFacet.setGovernancePerBlock.selector);
        selectorsOfChefFacet.push(chefFacet.governancePerBlock.selector);
        selectorsOfChefFacet.push(chefFacet.governanceDivider.selector);
        selectorsOfChefFacet.push(
            chefFacet.minPriceDiffToUpdateMultiplier.selector
        );
        selectorsOfChefFacet.push(
            chefFacet.setGovernanceShareForTreasury.selector
        );
        selectorsOfChefFacet.push(
            chefFacet.setMinPriceDiffToUpdateMultiplier.selector
        );
        selectorsOfChefFacet.push(chefFacet.getRewards.selector);
        selectorsOfChefFacet.push(chefFacet.pendingGovernance.selector);
        selectorsOfChefFacet.push(chefFacet.getStakingShareInfo.selector);
        selectorsOfChefFacet.push(chefFacet.totalShares.selector);
        selectorsOfChefFacet.push(chefFacet.pool.selector);

        // Staking
        selectorsOfStakingFacet.push(stakingFacet.dollarPriceReset.selector);
        selectorsOfStakingFacet.push(stakingFacet.crvPriceReset.selector);
        selectorsOfStakingFacet.push(
            stakingFacet.setStakingDiscountMultiplier.selector
        );
        selectorsOfStakingFacet.push(
            stakingFacet.stakingDiscountMultiplier.selector
        );
        selectorsOfStakingFacet.push(
            stakingFacet.setBlockCountInAWeek.selector
        );
        selectorsOfStakingFacet.push(stakingFacet.blockCountInAWeek.selector);
        selectorsOfStakingFacet.push(stakingFacet.deposit.selector);
        selectorsOfStakingFacet.push(stakingFacet.addLiquidity.selector);
        selectorsOfStakingFacet.push(stakingFacet.removeLiquidity.selector);
        selectorsOfStakingFacet.push(stakingFacet.pendingLpRewards.selector);
        selectorsOfStakingFacet.push(stakingFacet.lpRewardForShares.selector);
        selectorsOfStakingFacet.push(stakingFacet.currentShareValue.selector);

        // UbiquityPool
        selectorsOfUbiquityPoolFacet.push(
            ubiquityPoolFacet.mintDollar.selector
        );
        selectorsOfUbiquityPoolFacet.push(
            ubiquityPoolFacet.redeemDollar.selector
        );
        selectorsOfUbiquityPoolFacet.push(
            ubiquityPoolFacet.collectRedemption.selector
        );
        selectorsOfUbiquityPoolFacet.push(ubiquityPoolFacet.addToken.selector);
        selectorsOfUbiquityPoolFacet.push(
            ubiquityPoolFacet.setRedeemActive.selector
        );
        selectorsOfUbiquityPoolFacet.push(
            ubiquityPoolFacet.getRedeemActive.selector
        );
        selectorsOfUbiquityPoolFacet.push(
            ubiquityPoolFacet.setMintActive.selector
        );
        selectorsOfUbiquityPoolFacet.push(
            ubiquityPoolFacet.getRedeemCollateralBalances.selector
        );
        selectorsOfUbiquityPoolFacet.push(
            ubiquityPoolFacet.getMintActive.selector
        );

        // Staking Formulas
        selectorsOfStakingFormulasFacet.push(
            stakingFormulasFacet.sharesForLP.selector
        );
        selectorsOfStakingFormulasFacet.push(
            stakingFormulasFacet.lpRewardsRemoveLiquidityNormalization.selector
        );
        selectorsOfStakingFormulasFacet.push(
            stakingFormulasFacet.lpRewardsAddLiquidityNormalization.selector
        );
        selectorsOfStakingFormulasFacet.push(
            stakingFormulasFacet.correctedAmountToWithdraw.selector
        );
        selectorsOfStakingFormulasFacet.push(
            stakingFormulasFacet.durationMultiply.selector
        );

        // Bonding Curve
        selectorsOfBondingCurveFacet.push(bondingCurveFacet.setParams.selector);
        selectorsOfBondingCurveFacet.push(
            bondingCurveFacet.connectorWeight.selector
        );
        selectorsOfBondingCurveFacet.push(bondingCurveFacet.baseY.selector);
        selectorsOfBondingCurveFacet.push(
            bondingCurveFacet.poolBalance.selector
        );
        selectorsOfBondingCurveFacet.push(bondingCurveFacet.deposit.selector);
        selectorsOfBondingCurveFacet.push(bondingCurveFacet.getShare.selector);
        selectorsOfBondingCurveFacet.push(bondingCurveFacet.withdraw.selector);
        selectorsOfBondingCurveFacet.push(
            bondingCurveFacet.purchaseTargetAmount.selector
        );
        selectorsOfBondingCurveFacet.push(
            bondingCurveFacet.purchaseTargetAmountFromZero.selector
        );

        // Curve Dollar Incentive Facet
        selectorsOfCurveDollarIncentiveFacet.push(
            curveDollarIncentiveFacet.incentivize.selector
        );
        selectorsOfCurveDollarIncentiveFacet.push(
            curveDollarIncentiveFacet.setExemptAddress.selector
        );
        selectorsOfCurveDollarIncentiveFacet.push(
            curveDollarIncentiveFacet.switchSellPenalty.selector
        );
        selectorsOfCurveDollarIncentiveFacet.push(
            curveDollarIncentiveFacet.switchBuyIncentive.selector
        );
        selectorsOfCurveDollarIncentiveFacet.push(
            curveDollarIncentiveFacet.isExemptAddress.selector
        );
        selectorsOfCurveDollarIncentiveFacet.push(
            curveDollarIncentiveFacet.isSellPenaltyOn.selector
        );
        selectorsOfCurveDollarIncentiveFacet.push(
            curveDollarIncentiveFacet.isBuyIncentiveOn.selector
        );

        // Credit facets
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacet.creditNftLengthBlocks.selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacet.expiredCreditNftConversionRate.selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacet.setExpiredCreditNftConversionRate.selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacet.setCreditNftLength.selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacet.exchangeDollarsForCreditNft.selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacet.exchangeDollarsForCredit.selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacet.getCreditNftReturnedForDollars.selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacet.getCreditReturnedForDollars.selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacet.onERC1155Received.selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacet.onERC1155BatchReceived.selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacet.burnExpiredCreditNftForGovernance.selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacet.burnCreditNftForCredit.selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacet.burnCreditTokensForDollars.selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacet.redeemCreditNft.selector
        );
        selectorsOfCreditNftManagerFacet.push(
            creditNftManagerFacet.mintClaimableDollars.selector
        );

        // Credit NFT Redemption Calculator
        selectorsOfCreditNftRedemptionCalculatorFacet.push(
            creditNftRedemptionCalculatorFacet.getCreditNftAmount.selector
        );

        // Credit Redemption Calculator
        selectorsOfCreditRedemptionCalculatorFacet.push(
            (creditRedemptionCalculatorFacet.setConstant.selector)
        );
        selectorsOfCreditRedemptionCalculatorFacet.push(
            (creditRedemptionCalculatorFacet.getConstant.selector)
        );
        selectorsOfCreditRedemptionCalculatorFacet.push(
            (creditRedemptionCalculatorFacet.getCreditAmount.selector)
        );

        // Dollar Mint Calculator
        selectorsOfDollarMintCalculatorFacet.push(
            (dollarMintCalculatorFacet.getDollarsToMint.selector)
        );
        // Dollar Mint Excess
        selectorsOfDollarMintExcessFacet.push(
            (dollarMintExcessFacet.distributeDollars.selector)
        );

        //deploy facets
        diamondCutFacetImplementation = new DiamondCutFacet();
        dLoupeFacet = new DiamondLoupeFacet();
        ownerFacet = new OwnershipFacet();
        managerFacet = new ManagerFacet();
        accessControlFacet = new AccessControlFacet();
        twapOracleDollar3PoolFacet = new TWAPOracleDollar3poolFacet();
        collectableDustFacet = new CollectableDustFacet();
        chefFacet = new ChefFacet();
        stakingFacet = new StakingFacet();
        ubiquityPoolFacet = new UbiquityPoolFacet();
        stakingFormulasFacet = new StakingFormulasFacet();
        bondingCurveFacet = new BondingCurveFacet();
        curveDollarIncentiveFacet = new CurveDollarIncentiveFacet();

        creditNftManagerFacet = new CreditNftManagerFacet();
        creditNftRedemptionCalculatorFacet = new CreditNftRedemptionCalculatorFacet();
        creditRedemptionCalculatorFacet = new CreditRedemptionCalculatorFacet();

        dollarMintCalculatorFacet = new DollarMintCalculatorFacet();
        dollarMintExcessFacet = new DollarMintExcessFacet();

        diamondInit = new DiamondInit();
        facetNames = [
            "DiamondCutFacet",
            "DiamondLoupeFacet",
            "OwnershipFacet",
            "ManagerFacet",
            "AccessControlFacet",
            "TWAPOracleDollar3poolFacet",
            "CollectableDustFacet",
            "ChefFacet",
            "StakingFacet",
            "UbiquityPoolFacet",
            "StakingFormulasFacet",
            "CurveDollarIncentiveFacet",
            "CreditNftManagerFacet",
            "CreditNftRedemptionCalculatorFacet",
            "CreditRedemptionCalculatorFacet",
            "DollarMintCalculatorFacet",
            "DollarMintExcessFacet",
            "BondingCurveFacet"
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
                facetAddress: address(diamondCutFacetImplementation),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfDiamondCutFacet
            })
        );

        cuts[1] = (
            FacetCut({
                facetAddress: address(dLoupeFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfDiamondLoupeFacet
            })
        );

        cuts[2] = (
            FacetCut({
                facetAddress: address(ownerFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfOwnershipFacet
            })
        );

        cuts[3] = (
            FacetCut({
                facetAddress: address(managerFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfManagerFacet
            })
        );

        cuts[4] = (
            FacetCut({
                facetAddress: address(accessControlFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfAccessControlFacet
            })
        );
        cuts[5] = (
            FacetCut({
                facetAddress: address(twapOracleDollar3PoolFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfTWAPOracleDollar3poolFacet
            })
        );

        cuts[6] = (
            FacetCut({
                facetAddress: address(collectableDustFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfCollectableDustFacet
            })
        );
        cuts[7] = (
            FacetCut({
                facetAddress: address(chefFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfChefFacet
            })
        );
        cuts[8] = (
            FacetCut({
                facetAddress: address(stakingFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfStakingFacet
            })
        );
        cuts[9] = (
            FacetCut({
                facetAddress: address(stakingFormulasFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfStakingFormulasFacet
            })
        );
        cuts[10] = (
            FacetCut({
                facetAddress: address(creditNftManagerFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfCreditNftManagerFacet
            })
        );
        cuts[11] = (
            FacetCut({
                facetAddress: address(creditNftRedemptionCalculatorFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfCreditNftRedemptionCalculatorFacet
            })
        );
        cuts[12] = (
            FacetCut({
                facetAddress: address(creditRedemptionCalculatorFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfCreditRedemptionCalculatorFacet
            })
        );
        cuts[13] = (
            FacetCut({
                facetAddress: address(dollarMintCalculatorFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfDollarMintCalculatorFacet
            })
        );
        cuts[14] = (
            FacetCut({
                facetAddress: address(dollarMintExcessFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfDollarMintExcessFacet
            })
        );
        cuts[15] = (
            FacetCut({
                facetAddress: address(bondingCurveFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfBondingCurveFacet
            })
        );
        cuts[16] = (
            FacetCut({
                facetAddress: address(curveDollarIncentiveFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfCurveDollarIncentiveFacet
            })
        );
        cuts[17] = (
            FacetCut({
                facetAddress: address(ubiquityPoolFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfUbiquityPoolFacet
            })
        );
        // deploy diamond
        vm.prank(owner);
        diamond = new Diamond(_args, cuts);
        // initialize interfaces
        ILoupe = IDiamondLoupe(address(diamond));
        ICut = IDiamondCut(address(diamond));
        IManager = ManagerFacet(address(diamond));
        IAccessControl = AccessControlFacet(address(diamond));
        ITWAPOracleDollar3pool = TWAPOracleDollar3poolFacet(address(diamond));

        ICollectableDustFacet = CollectableDustFacet(address(diamond));
        IChefFacet = ChefFacet(address(diamond));
        IStakingFacet = StakingFacet(address(diamond));
        IUbiquityPoolFacet = UbiquityPoolFacet(address(diamond));
        IStakingFormulasFacet = StakingFormulasFacet(address(diamond));
        IBondingCurveFacet = BondingCurveFacet(address(diamond));
        ICurveDollarIncentiveFacet = CurveDollarIncentiveFacet(
            address(diamond)
        );
        IOwnershipFacet = OwnershipFacet(address(diamond));

        ICreditNftManagerFacet = CreditNftManagerFacet(address(diamond));
        ICreditNftRedemptionCalculationFacet = CreditNftRedemptionCalculatorFacet(
            address(diamond)
        );
        ICreditRedemptionCalculationFacet = CreditRedemptionCalculatorFacet(
            address(diamond)
        );

        IDollarMintCalcFacet = DollarMintCalculatorFacet(address(diamond));
        IDollarMintExcessFacet = DollarMintExcessFacet(address(diamond));

        // get all addresses
        facetAddressList = ILoupe.facetAddresses();
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
