// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {MockTWAPOracleDollar3pool} from "../../src/dollar/mocks/MockTWAPOracleDollar3pool.sol";
import {DiamondTestSetup} from "../diamond/DiamondTestSetup.sol";
import {TWAPOracleDollar3poolFacet} from "../../src/dollar/facets/TWAPOracleDollar3poolFacet.sol";
import {CreditRedemptionCalculatorFacet} from "../../src/dollar/facets/CreditRedemptionCalculatorFacet.sol";
import {CreditNftRedemptionCalculatorFacet} from "../../src/dollar/facets/CreditNftRedemptionCalculatorFacet.sol";
import {DollarMintCalculatorFacet} from "../../src/dollar/facets/DollarMintCalculatorFacet.sol";
import {CreditNftManagerFacet} from "../../src/dollar/facets/CreditNftManagerFacet.sol";
import {DollarMintExcessFacet} from "../../src/dollar/facets/DollarMintExcessFacet.sol";
import {MockCurveStableSwapMetaNG} from "../../src/dollar/mocks/MockCurveStableSwapMetaNG.sol";

abstract contract LocalTestHelper is DiamondTestSetup {
    address public constant NATIVE_ASSET = address(0);
    address curve3CRVTokenAddress = address(0x101);
    address public treasuryAddress = address(0x111222333);

    CreditNftRedemptionCalculatorFacet creditNftRedemptionCalculator;
    CreditRedemptionCalculatorFacet creditRedemptionCalculator;
    DollarMintCalculatorFacet dollarMintCalculator;
    CreditNftManagerFacet creditNftManager;
    DollarMintExcessFacet dollarMintExcess;
    address metaPoolAddress;

    function setUp() public virtual override {
        super.setUp();

        creditNftRedemptionCalculator = creditNftRedemptionCalculationFacet;
        creditRedemptionCalculator = creditRedemptionCalculationFacet;
        dollarMintCalculator = dollarMintCalculatorFacet;
        creditNftManager = creditNftManagerFacet;
        dollarMintExcess = dollarMintExcessFacet;

        vm.startPrank(admin);

        //mint some dollar token
        dollarToken.mint(address(0x1045256), 10000e18);
        require(
            dollarToken.balanceOf(address(0x1045256)) == 10000e18,
            "dollar balance is not 10000e18"
        );

        // twapPrice oracle
        metaPoolAddress = address(
            new MockCurveStableSwapMetaNG(
                address(dollarToken),
                curve3CRVTokenAddress
            )
        );

        // set treasury address
        managerFacet.setTreasuryAddress(treasuryAddress);

        // set metapool in manager facet
        managerFacet.setStableSwapMetaPoolAddress(metaPoolAddress);

        vm.stopPrank();
    }
}
