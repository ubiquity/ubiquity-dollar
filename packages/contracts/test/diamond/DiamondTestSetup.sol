// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../src/diamond/interfaces/IDiamondCut.sol";
import "../../src/diamond/facets/DiamondCutFacet.sol";
import "../../src/diamond/facets/DiamondLoupeFacet.sol";
import "../../src/diamond/facets/OwnershipFacet.sol";
import "../../src/diamond/facets/ManagerFacet.sol";
import "../../src/diamond/facets/AccessControlFacet.sol";
import "../../src/diamond/facets/TWAPOracleDollar3poolFacet.sol";
import "../../src/diamond/facets/UbiquityDollarTokenFacet.sol";
import "../../src/diamond/facets/CollectableDustFacet.sol";
import "../../src/diamond/facets/UbiquityChefFacet.sol";
import "../../src/diamond/facets/StakingFacet.sol";
import "../../src/diamond/facets/StakingFormulasFacet.sol";
import "../../src/diamond/Diamond.sol";
import "../../src/diamond/upgradeInitializers/DiamondInit.sol";
import "../helpers/DiamondTestHelper.sol";
import {MockIncentive} from "../../src/dollar/mocks/MockIncentive.sol";

abstract contract DiamondSetup is DiamondTestHelper {
    // contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupeFacet;
    OwnershipFacet ownerFacet;
    ManagerFacet managerFacet;
    DiamondInit dInit;
    // actual implementation of facets
    AccessControlFacet accessControlFacet;
    TWAPOracleDollar3poolFacet twapOracleDollar3PoolFacet;
    UbiquityDollarTokenFacet dollarTokenFacet;
    CollectableDustFacet collectableDustFacet;
    UbiquityChefFacet ubiquityChefFacet;
    StakingFacet stakingFacet;
    StakingFormulasFacet stakingFormulasFacet;
    // interfaces with Facet ABI connected to diamond address
    IDiamondLoupe ILoupe;
    IDiamondCut ICut;
    ManagerFacet IManager;
    TWAPOracleDollar3poolFacet ITWAPOracleDollar3pool;
    AccessControlFacet IAccessCtrl;
    UbiquityDollarTokenFacet IDollarFacet;

    CollectableDustFacet ICollectableDustFacet;
    UbiquityChefFacet IUbiquityChefFacet;
    StakingFacet IStakingFacet;
    StakingFormulasFacet IStakingFormulasFacet;
    OwnershipFacet IOwnershipFacet;

    address incentive_addr;

    string[] facetNames;
    address[] facetAddressList;

    address owner;
    address admin;
    address tokenMgr;
    address user1;
    address contract1;
    address contract2;

    bytes4[] selectorsOfDiamondCutFacet;
    bytes4[] selectorsOfDiamondLoupeFacet;
    bytes4[] selectorsOfOwnershipFacet;
    bytes4[] selectorsOfManagerFacet;
    bytes4[] selectorsOfAccessControlFacet;
    bytes4[] selectorsOfTWAPOracleDollar3poolFacet;
    bytes4[] selectorsOfUbiquityDollarTokenFacet;
    bytes4[] selectorsOfCollectableDustFacet;
    bytes4[] selectorsOfUbiquityChefFacet;
    bytes4[] selectorsOfStakingFacet;
    bytes4[] selectorsOfStakingFormulasFacet;

    // deploys diamond and connects facets
    function setUp() public virtual {
        incentive_addr = address(new MockIncentive());
        owner = generateAddress("Owner", false, 10 ether);
        admin = generateAddress("Admin", false, 10 ether);
        tokenMgr = generateAddress("TokenMgr", false, 10 ether);

        user1 = generateAddress("User1", false, 10 ether);
        contract1 = generateAddress("Contract1", true, 10 ether);
        contract2 = generateAddress("Contract2", true, 10 ether);

        // set all function selectors
        // Diamond Cutselectors
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

        // Manager selectrs
        selectorsOfManagerFacet.push(
            managerFacet.setCreditTokenAddress.selector
        );
        selectorsOfManagerFacet.push(managerFacet.setCreditNftAddress.selector);
        selectorsOfManagerFacet.push(
            managerFacet.setGovernanceTokenAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacet.setSushiSwapPoolAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacet.setCreditCalculatorAddress.selector
        );
        selectorsOfManagerFacet.push(
            managerFacet.setCreditNftCalculatorAddress.selector
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
        selectorsOfManagerFacet.push(managerFacet.creditNFTAddress.selector);
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

        // Ubiquity Dollar Token
        // -- ERC20
        selectorsOfUbiquityDollarTokenFacet.push(
            dollarTokenFacet.name.selector
        );
        selectorsOfUbiquityDollarTokenFacet.push(
            dollarTokenFacet.symbol.selector
        );
        selectorsOfUbiquityDollarTokenFacet.push(
            dollarTokenFacet.decimals.selector
        );
        selectorsOfUbiquityDollarTokenFacet.push(
            dollarTokenFacet.totalSupply.selector
        );
        selectorsOfUbiquityDollarTokenFacet.push(
            dollarTokenFacet.balanceOf.selector
        );
        selectorsOfUbiquityDollarTokenFacet.push(
            dollarTokenFacet.transfer.selector
        );
        selectorsOfUbiquityDollarTokenFacet.push(
            dollarTokenFacet.allowance.selector
        );
        selectorsOfUbiquityDollarTokenFacet.push(
            dollarTokenFacet.approve.selector
        );
        selectorsOfUbiquityDollarTokenFacet.push(
            dollarTokenFacet.transferFrom.selector
        );
        // -- ERC20 Ubiquity
        selectorsOfUbiquityDollarTokenFacet.push(
            dollarTokenFacet.burn.selector
        );
        selectorsOfUbiquityDollarTokenFacet.push(
            dollarTokenFacet.permit.selector
        );
        selectorsOfUbiquityDollarTokenFacet.push(
            dollarTokenFacet.burnFrom.selector
        );
        selectorsOfUbiquityDollarTokenFacet.push(
            dollarTokenFacet.mint.selector
        );
        selectorsOfUbiquityDollarTokenFacet.push(
            dollarTokenFacet.setSymbol.selector
        );
        selectorsOfUbiquityDollarTokenFacet.push(
            dollarTokenFacet.setName.selector
        );
        selectorsOfUbiquityDollarTokenFacet.push(
            dollarTokenFacet.nonces.selector
        );
        selectorsOfUbiquityDollarTokenFacet.push(
            dollarTokenFacet.DOMAIN_SEPARATOR.selector
        );
        // -- Specific to dollar
        selectorsOfUbiquityDollarTokenFacet.push(
            dollarTokenFacet.setIncentiveContract.selector
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
        selectorsOfUbiquityChefFacet.push(
            ubiquityChefFacet.setGovernancePerBlock.selector
        );
        selectorsOfUbiquityChefFacet.push(
            ubiquityChefFacet.governancePerBlock.selector
        );
        selectorsOfUbiquityChefFacet.push(
            ubiquityChefFacet.governanceDivider.selector
        );
        selectorsOfUbiquityChefFacet.push(
            ubiquityChefFacet.minPriceDiffToUpdateMultiplier.selector
        );
        selectorsOfUbiquityChefFacet.push(
            ubiquityChefFacet.setGovernanceShareForTreasury.selector
        );
        selectorsOfUbiquityChefFacet.push(
            ubiquityChefFacet.setMinPriceDiffToUpdateMultiplier.selector
        );
        selectorsOfUbiquityChefFacet.push(
            ubiquityChefFacet.getRewards.selector
        );
        selectorsOfUbiquityChefFacet.push(
            ubiquityChefFacet.pendingGovernance.selector
        );
        selectorsOfUbiquityChefFacet.push(
            ubiquityChefFacet.getStakingShareInfo.selector
        );
        selectorsOfUbiquityChefFacet.push(
            ubiquityChefFacet.totalShares.selector
        );
        selectorsOfUbiquityChefFacet.push(ubiquityChefFacet.pool.selector);

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

        //deploy facets
        dCutFacet = new DiamondCutFacet();
        dLoupeFacet = new DiamondLoupeFacet();
        ownerFacet = new OwnershipFacet();
        managerFacet = new ManagerFacet();
        accessControlFacet = new AccessControlFacet();
        twapOracleDollar3PoolFacet = new TWAPOracleDollar3poolFacet();
        dollarTokenFacet = new UbiquityDollarTokenFacet();
        collectableDustFacet = new CollectableDustFacet();
        ubiquityChefFacet = new UbiquityChefFacet();
        stakingFacet = new StakingFacet();
        stakingFormulasFacet = new StakingFormulasFacet();
        dInit = new DiamondInit();

        facetNames = [
            "DiamondCutFacet",
            "DiamondLoupeFacet",
            "OwnershipFacet",
            "ManagerFacet",
            "AccessControlFacet",
            "TWAPOracleDollar3poolFacet",
            "UbiquityDollarTokenFacet",
            "CollectableDustFacet",
            "UbiquityChefFacet",
            "StakingFacet",
            "StakingFormulasFacet"
        ];

        DiamondInit.Args memory initArgs = DiamondInit.Args({
            admin: admin,
            dollarName: "Ubiquity Algorithmic Dollar",
            dollarSymbol: "uAD",
            dollarDecimals: 18,
            tos: new address[](0),
            amounts: new uint256[](0),
            stakingShareIDs: new uint256[](0),
            governancePerBlock: 10e18
        });
        // diamod arguments
        DiamondArgs memory _args = DiamondArgs({
            owner: owner,
            init: address(dInit),
            initCalldata: abi.encodeWithSelector(
                DiamondInit.init.selector,
                initArgs
            )
        });

        FacetCut[] memory cuts = new FacetCut[](11);

        cuts[0] = (
            FacetCut({
                facetAddress: address(dCutFacet),
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
                facetAddress: address(dollarTokenFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfUbiquityDollarTokenFacet
            })
        );
        cuts[7] = (
            FacetCut({
                facetAddress: address(collectableDustFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfCollectableDustFacet
            })
        );
        cuts[8] = (
            FacetCut({
                facetAddress: address(ubiquityChefFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfUbiquityChefFacet
            })
        );
        cuts[9] = (
            FacetCut({
                facetAddress: address(stakingFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfStakingFacet
            })
        );
        cuts[10] = (
            FacetCut({
                facetAddress: address(stakingFormulasFacet),
                action: FacetCutAction.Add,
                functionSelectors: selectorsOfStakingFormulasFacet
            })
        );

        // deploy diamond
        vm.startPrank(owner);
        console.log("!!!!!diamond owner:%s", _args.owner);
        diamond = new Diamond(_args, cuts);
        vm.stopPrank();

        // initialize interfaces
        ILoupe = IDiamondLoupe(address(diamond));
        ICut = IDiamondCut(address(diamond));
        IManager = ManagerFacet(address(diamond));
        IManager = ManagerFacet(address(diamond));
        IAccessCtrl = AccessControlFacet(address(diamond));
        ITWAPOracleDollar3pool = TWAPOracleDollar3poolFacet(address(diamond));
        IDollarFacet = UbiquityDollarTokenFacet(address(diamond));
        ICollectableDustFacet = CollectableDustFacet(address(diamond));
        IUbiquityChefFacet = UbiquityChefFacet(address(diamond));
        IStakingFacet = StakingFacet(address(diamond));
        IStakingFormulasFacet = StakingFormulasFacet(address(diamond));
        IOwnershipFacet = OwnershipFacet(address(diamond));

        assertEq(IDollarFacet.decimals(), 18);
        // get all addresses
        facetAddressList = ILoupe.facetAddresses();
    }
}
