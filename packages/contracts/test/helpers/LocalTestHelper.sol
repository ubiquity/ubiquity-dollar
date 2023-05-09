// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


import {DiamondSetup} from "../diamond/DiamondTestSetup.sol";
import {ManagerFacet} from "../../src/dollar/facets/ManagerFacet.sol";
import {TWAPOracleDollar3poolFacet} from "../../src/dollar/facets/TWAPOracleDollar3poolFacet.sol";
import {CreditRedemptionCalculatorFacet} from "../../src/dollar/facets/CreditRedemptionCalculatorFacet.sol";
import {CreditNftRedemptionCalculatorFacet} from "../../src/dollar/facets/CreditNftRedemptionCalculatorFacet.sol";
import {DollarMintCalculatorFacet} from "../../src/dollar/facets/DollarMintCalculatorFacet.sol";
import {CreditNftManagerFacet} from "../../src/dollar/facets/CreditNftManagerFacet.sol";
import {DollarMintExcessFacet} from "../../src/dollar/facets/DollarMintExcessFacet.sol";
import {UbiquityDollarToken} from "../../src/dollar/core/UbiquityDollarToken.sol";



abstract contract LocalTestHelper is DiamondSetup {
    address public constant NATIVE_ASSET = address(0);
    address curve3CRVTokenAddress = address(0x101);
    address public treasuryAddress = address(0x111222333);

    TWAPOracleDollar3poolFacet twapOracle;

    CreditNftRedemptionCalculatorFacet creditNftRedemptionCalculator;
    
    CreditRedemptionCalculatorFacet creditRedemptionCalculator;
    DollarMintCalculatorFacet dollarMintCalculator;
    CreditNftManagerFacet creditNftManager;
    DollarMintExcessFacet dollarMintExcess;
    address metaPoolAddress;

    function setUp() public virtual override {
        super.setUp();

        twapOracle = ITWAPOracleDollar3pool;
        creditNftRedemptionCalculator = ICreditNFTRedCalcFacet;
        creditRedemptionCalculator = ICreditRedCalcFacet;
        dollarMintCalculator = IDollarMintCalcFacet;
        creditNftManager = ICreditNFTMgrFacet;
        dollarMintExcess = IDollarMintExcessFacet;

        vm.startPrank(admin);

        //mint some dollar token
        IDollar.mint(address(0x1045256), 10000e18);
        require(
            IDollar.balanceOf(address(0x1045256)) == 10000e18,
            "dollar balance is not 10000e18"
        );
        
        // deploy credit token

        // set treasury address
        IManager.setTreasuryAddress(treasuryAddress);

        vm.stopPrank();
        vm.prank(owner);
        ITWAPOracleDollar3pool.setPool(metaPoolAddress, curve3CRVTokenAddress);
        ITWAPOracleDollar3pool.update();
    }
}
