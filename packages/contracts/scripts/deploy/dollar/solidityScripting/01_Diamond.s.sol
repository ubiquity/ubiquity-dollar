// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IDiamondCut} from "../../../../src/dollar/interfaces/IDiamondCut.sol";
import {DiamondCutFacet} from "../../../../src/dollar/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../../../../src/dollar/facets/DiamondLoupeFacet.sol";
import {IERC173} from "../../../../src/dollar/interfaces/IERC173.sol";
import {IDiamondLoupe} from "../../../../src/dollar/interfaces/IDiamondLoupe.sol";
import {OwnershipFacet} from "../../../../src/dollar/facets/OwnershipFacet.sol";
import {ManagerFacet} from "../../../../src/dollar/facets/ManagerFacet.sol";
import {AccessControlFacet} from "../../../../src/dollar/facets/AccessControlFacet.sol";
import {TWAPOracleDollar3poolFacet} from "../../../../src/dollar/facets/TWAPOracleDollar3poolFacet.sol";
import {CollectableDustFacet} from "../../../../src/dollar/facets/CollectableDustFacet.sol";
import {ChefFacet} from "../../../../src/dollar/facets/ChefFacet.sol";
import {StakingFacet} from "../../../../src/dollar/facets/StakingFacet.sol";
import {StakingFormulasFacet} from "../../../../src/dollar/facets/StakingFormulasFacet.sol";
import {CreditNftManagerFacet} from "../../../../src/dollar/facets/CreditNftManagerFacet.sol";
import {CreditNftRedemptionCalculatorFacet} from "../../../../src/dollar/facets/CreditNftRedemptionCalculatorFacet.sol";
import {CreditRedemptionCalculatorFacet} from "../../../../src/dollar/facets/CreditRedemptionCalculatorFacet.sol";
import {DollarMintCalculatorFacet} from "../../../../src/dollar/facets/DollarMintCalculatorFacet.sol";
import {DollarMintExcessFacet} from "../../../../src/dollar/facets/DollarMintExcessFacet.sol";
import {Diamond, DiamondArgs} from "../../../../src/dollar/Diamond.sol";
import {DiamondInit} from "../../../../src/dollar/upgradeInitializers/DiamondInit.sol";
import {UbiquityDollarToken} from "../../../../src/dollar/core/UbiquityDollarToken.sol";
import {StakingShare} from "../../../../src/dollar/core/StakingShare.sol";
import {UbiquityGovernanceToken} from "../../../../src/dollar/core/UbiquityGovernanceToken.sol";
import {IDiamondCut} from "../../../../src/dollar/interfaces/IDiamondCut.sol";
//import "../../src/dollar/interfaces/IDiamondLoupe.sol";

import "./00_Constants.s.sol";

contract DiamondScript is Constants {
    bytes4[] selectorsOfDiamondCutFacet;
    bytes4[] selectorsOfDiamondLoupeFacet;
    bytes4[] selectorsOfOwnershipFacet;
    bytes4[] selectorsOfManagerFacet;
    bytes4[] selectorsOfAccessControlFacet;
    bytes4[] selectorsOfTWAPOracleDollar3poolFacet;
    bytes4[] selectorsOfCollectableDustFacet;
    bytes4[] selectorsOfChefFacet;
    bytes4[] selectorsOfStakingFacet;
    bytes4[] selectorsOfStakingFormulasFacet;

    bytes4[] selectorsOfCreditNftManagerFacet;
    bytes4[] selectorsOfCreditNftRedemptionCalculatorFacet;
    bytes4[] selectorsOfCreditRedemptionCalculatorFacet;

    bytes4[] selectorsOfDollarMintCalculatorFacet;
    bytes4[] selectorsOfDollarMintExcessFacet;
    // contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupeFacet;
    OwnershipFacet ownerFacet;
    ManagerFacet managerFacet;
    // facet through diamond address
    ManagerFacet IManager;
    AccessControlFacet IAccessControl;
    DiamondInit dInit;
    // actual implementation of facets
    AccessControlFacet accessControlFacet;
    TWAPOracleDollar3poolFacet twapOracleDollar3PoolFacet;
    CollectableDustFacet collectableDustFacet;
    ChefFacet chefFacet;
    StakingFacet stakingFacet;
    StakingFormulasFacet stakingFormulasFacet;

    CreditNftManagerFacet creditNftManagerFacet;
    CreditNftRedemptionCalculatorFacet creditNftRedemptionCalculatorFacet;
    CreditRedemptionCalculatorFacet creditRedemptionCalculatorFacet;

    DollarMintCalculatorFacet dollarMintCalculatorFacet;
    DollarMintExcessFacet dollarMintExcessFacet;

    string[] facetNames;

    function run() public virtual {
        vm.startBroadcast(deployerPrivateKey);
        getSelectors();
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        dLoupeFacet = new DiamondLoupeFacet();
        ownerFacet = new OwnershipFacet();
        managerFacet = new ManagerFacet();
        accessControlFacet = new AccessControlFacet();
        twapOracleDollar3PoolFacet = new TWAPOracleDollar3poolFacet();
        collectableDustFacet = new CollectableDustFacet();
        chefFacet = new ChefFacet();
        stakingFacet = new StakingFacet();
        stakingFormulasFacet = new StakingFormulasFacet();

        creditNftManagerFacet = new CreditNftManagerFacet();
        creditNftRedemptionCalculatorFacet = new CreditNftRedemptionCalculatorFacet();
        creditRedemptionCalculatorFacet = new CreditRedemptionCalculatorFacet();

        dollarMintCalculatorFacet = new DollarMintCalculatorFacet();
        dollarMintExcessFacet = new DollarMintExcessFacet();

        dInit = new DiamondInit();
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
            "StakingFormulasFacet",
            "CreditNftManagerFacet",
            "CreditNftRedemptionCalculatorFacet",
            "CreditRedemptionCalculatorFacet",
            "DollarMintCalculatorFacet",
            "DollarMintExcessFacet"
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
            owner: admin,
            init: address(dInit),
            initCalldata: abi.encodeWithSelector(
                DiamondInit.init.selector,
                initArgs
            )
        });
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](15);
        setFacet(cuts);
        // deploy diamond

        diamond = new Diamond(_args, cuts);
        IManager = ManagerFacet(address(diamond));
        IAccessControl = AccessControlFacet(address(diamond));
        StakingFacet IStakingFacet = StakingFacet(address(diamond));
        IStakingFacet.setBlockCountInAWeek(420);
        vm.stopBroadcast();
    }

    function setFacet(IDiamondCut.FacetCut[] memory cuts) internal view {
        cuts[0] = (
            IDiamondCut.FacetCut({
                facetAddress: address(dCutFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfDiamondCutFacet
            })
        );

        cuts[1] = (
            IDiamondCut.FacetCut({
                facetAddress: address(dLoupeFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfDiamondLoupeFacet
            })
        );

        cuts[2] = (
            IDiamondCut.FacetCut({
                facetAddress: address(ownerFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfOwnershipFacet
            })
        );

        cuts[3] = (
            IDiamondCut.FacetCut({
                facetAddress: address(managerFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfManagerFacet
            })
        );

        cuts[4] = (
            IDiamondCut.FacetCut({
                facetAddress: address(accessControlFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfAccessControlFacet
            })
        );
        cuts[5] = (
            IDiamondCut.FacetCut({
                facetAddress: address(twapOracleDollar3PoolFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfTWAPOracleDollar3poolFacet
            })
        );

        cuts[6] = (
            IDiamondCut.FacetCut({
                facetAddress: address(collectableDustFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfCollectableDustFacet
            })
        );
        cuts[7] = (
            IDiamondCut.FacetCut({
                facetAddress: address(chefFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfChefFacet
            })
        );
        cuts[8] = (
            IDiamondCut.FacetCut({
                facetAddress: address(stakingFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfStakingFacet
            })
        );
        cuts[9] = (
            IDiamondCut.FacetCut({
                facetAddress: address(stakingFormulasFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfStakingFormulasFacet
            })
        );
        cuts[10] = (
            IDiamondCut.FacetCut({
                facetAddress: address(creditNftManagerFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfCreditNftManagerFacet
            })
        );
        cuts[11] = (
            IDiamondCut.FacetCut({
                facetAddress: address(creditNftRedemptionCalculatorFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfCreditNftRedemptionCalculatorFacet
            })
        );
        cuts[12] = (
            IDiamondCut.FacetCut({
                facetAddress: address(creditRedemptionCalculatorFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfCreditRedemptionCalculatorFacet
            })
        );
        cuts[13] = (
            IDiamondCut.FacetCut({
                facetAddress: address(dollarMintCalculatorFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfDollarMintCalculatorFacet
            })
        );
        cuts[14] = (
            IDiamondCut.FacetCut({
                facetAddress: address(dollarMintExcessFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfDollarMintExcessFacet
            })
        );
    }

    function getSelectors() internal {
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
            managerFacet.setStableSwapMetaPoolAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacet.setStakingContractAddress.selector
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
        selectorsOfChefFacet.push(chefFacet.governanceMultiplier.selector);
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
    }
}
