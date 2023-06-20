// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IDiamondCut} from "../../../../src/dollar/interfaces/i-diamond-cut.sol";
import {DiamondCutFacet} from "../../../../src/dollar/facets/diamond-cut-facet.sol";
import {DiamondLoupeFacet} from "../../../../src/dollar/facets/diamond-loupe-facet.sol";
import {IERC173} from "../../../../src/dollar/interfaces/ierc-173.sol";
import {IDiamondLoupe} from "../../../../src/dollar/interfaces/i-diamond-loupe.sol";
import {OwnershipFacet} from "../../../../src/dollar/facets/ownership-facet.sol";
import {ManagerFacet} from "../../../../src/dollar/facets/manager-facet.sol";
import {AccessControlFacet} from "../../../../src/dollar/facets/access-control-facet.sol";
import {TWAPOracleDollar3poolFacet} from "../../../../src/dollar/facets/twap-oracle-dollar-3-pool-facet.sol";
import {CollectableDustFacet} from "../../../../src/dollar/facets/collectable-dust-facet.sol";
import {ChefFacet} from "../../../../src/dollar/facets/chef-facet.sol";
import {StakingFacet} from "../../../../src/dollar/facets/staking-facet.sol";
import {StakingFormulasFacet} from "../../../../src/dollar/facets/staking-formulas-facet.sol";
import {CreditNftManagerFacet} from "../../../../src/dollar/facets/credit-nft-manager-facet.sol";
import {CreditNftRedemptionCalculatorFacet} from "../../../../src/dollar/facets/credit-nft-redemption-calculator-facet.sol";
import {CreditRedemptionCalculatorFacet} from "../../../../src/dollar/facets/credit-redemption-calculator-facet.sol";
import {DollarMintCalculatorFacet} from "../../../../src/dollar/facets/dollar-mint-calculator-facet.sol";
import {DollarMintExcessFacet} from "../../../../src/dollar/facets/dollar-mint-excess-facet.sol";
import {Diamond, DiamondArgs} from "../../../../src/dollar/diamond.sol";
import {DiamondInit} from "../../../../src/dollar/upgradeInitializers/diamond-init.sol";
import {UbiquityDollarToken} from "../../../../src/dollar/core/ubiquity-dollar-token.sol";
import {StakingShare} from "../../../../src/dollar/core/staking-share.sol";
import {UbiquityGovernanceToken} from "../../../../src/dollar/core/ubiquity-governance-token.sol";
import {IDiamondCut} from "../../../../src/dollar/interfaces/i-diamond-cut.sol";
//import "../../src/dollar/interfaces/i-diamond-loupe.sol";

import "./constants-s.sol";

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

    bytes4[] selectorsOfCreditNFTManagerFacet;
    bytes4[] selectorsOfCreditNFTRedemptionCalculatorFacet;
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
    AccessControlFacet IAccessCtrl;
    DiamondInit dInit;
    // actual implementation of facets
    AccessControlFacet accessControlFacet;
    TWAPOracleDollar3poolFacet twapOracleDollar3PoolFacet;
    CollectableDustFacet collectableDustFacet;
    ChefFacet chefFacet;
    StakingFacet stakingFacet;
    StakingFormulasFacet stakingFormulasFacet;

    CreditNftManagerFacet creditNFTManagerFacet;
    CreditNftRedemptionCalculatorFacet creditNFTRedemptionCalculatorFacet;
    CreditRedemptionCalculatorFacet creditRedemptionCalculatorFacet;

    DollarMintCalculatorFacet dollarMintCalculatorFacet;
    DollarMintExcessFacet dollarMintExcessFacet;

    UbiquityDollarToken IDollar;

    address incentive_addr;
    string[] facetNames;
    address[] facetAddressList;

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

        creditNFTManagerFacet = new CreditNftManagerFacet();
        creditNFTRedemptionCalculatorFacet = new CreditNftRedemptionCalculatorFacet();
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
            "CreditNFTManagerFacet",
            "CreditNFTRedemptionCalculatorFacet",
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
            creditNFTLengthBlocks: 100
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
        IAccessCtrl = AccessControlFacet(address(diamond));
        StakingFacet IStakingFacet = StakingFacet(address(diamond));
        IStakingFacet.setBlockCountInAWeek(420);
        vm.stopBroadcast();
    }

    function setFacet(IDiamondCut.FacetCut[] memory cuts) internal {
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
                facetAddress: address(creditNFTManagerFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfCreditNFTManagerFacet
            })
        );
        cuts[11] = (
            IDiamondCut.FacetCut({
                facetAddress: address(creditNFTRedemptionCalculatorFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectorsOfCreditNFTRedemptionCalculatorFacet
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
            managerFacet.creditNFTCalculatorAddress.selector
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
        selectorsOfCreditNFTManagerFacet.push(
            creditNFTManagerFacet.creditNFTLengthBlocks.selector
        );
        selectorsOfCreditNFTManagerFacet.push(
            creditNFTManagerFacet.expiredCreditNFTConversionRate.selector
        );
        selectorsOfCreditNFTManagerFacet.push(
            creditNFTManagerFacet.setExpiredCreditNFTConversionRate.selector
        );
        selectorsOfCreditNFTManagerFacet.push(
            creditNFTManagerFacet.setCreditNFTLength.selector
        );
        selectorsOfCreditNFTManagerFacet.push(
            creditNFTManagerFacet.exchangeDollarsForCreditNft.selector
        );
        selectorsOfCreditNFTManagerFacet.push(
            creditNFTManagerFacet.exchangeDollarsForCredit.selector
        );
        selectorsOfCreditNFTManagerFacet.push(
            creditNFTManagerFacet.getCreditNFTReturnedForDollars.selector
        );
        selectorsOfCreditNFTManagerFacet.push(
            creditNFTManagerFacet.getCreditReturnedForDollars.selector
        );
        selectorsOfCreditNFTManagerFacet.push(
            creditNFTManagerFacet.onERC1155Received.selector
        );
        selectorsOfCreditNFTManagerFacet.push(
            creditNFTManagerFacet.onERC1155BatchReceived.selector
        );
        selectorsOfCreditNFTManagerFacet.push(
            creditNFTManagerFacet.burnExpiredCreditNFTForGovernance.selector
        );
        selectorsOfCreditNFTManagerFacet.push(
            creditNFTManagerFacet.burnCreditNFTForCredit.selector
        );
        selectorsOfCreditNFTManagerFacet.push(
            creditNFTManagerFacet.burnCreditTokensForDollars.selector
        );
        selectorsOfCreditNFTManagerFacet.push(
            creditNFTManagerFacet.redeemCreditNft.selector
        );
        selectorsOfCreditNFTManagerFacet.push(
            creditNFTManagerFacet.mintClaimableDollars.selector
        );

        // Credit NFT Redemption Calculator
        selectorsOfCreditNFTRedemptionCalculatorFacet.push(
            creditNFTRedemptionCalculatorFacet.getCreditNftAmount.selector
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
