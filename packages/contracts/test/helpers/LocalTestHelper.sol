// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {MockTWAPOracleDollar3pool} from "../../src/dollar/mocks/MockTWAPOracleDollar3pool.sol";
import {DiamondSetup} from "../diamond/DiamondTestSetup.sol";
import {ManagerFacet} from "../../src/dollar/facets/ManagerFacet.sol";
import {TWAPOracleDollar3poolFacet} from "../../src/dollar/facets/TWAPOracleDollar3poolFacet.sol";
import {CreditRedemptionCalculatorFacet} from "../../src/dollar/facets/CreditRedemptionCalculatorFacet.sol";
import {CreditNftRedemptionCalculatorFacet} from "../../src/dollar/facets/CreditNftRedemptionCalculatorFacet.sol";
import {DollarMintCalculatorFacet} from "../../src/dollar/facets/DollarMintCalculatorFacet.sol";
import {CreditNftManagerFacet} from "../../src/dollar/facets/CreditNftManagerFacet.sol";
import {DollarMintExcessFacet} from "../../src/dollar/facets/DollarMintExcessFacet.sol";
import {UbiquityDollarToken} from "../../src/dollar/core/UbiquityDollarToken.sol";
import {UbiquityCreditToken} from "../../src/dollar/core/UbiquityCreditToken.sol";
import {MockMetaPool} from "../../src/dollar/mocks/MockMetaPool.sol";

abstract contract LocalTestHelper is DiamondSetup {
    address public constant NATIVE_ASSET = address(0);
    address curve3CRVTokenAddress = address(0x101);
    address public treasuryAddress = address(0x111222333);

    TWAPOracleDollar3poolFacet twapOracle;

    CreditNftRedemptionCalculatorFacet creditNftRedemptionCalculator;
    UbiquityCreditToken creditToken;
    CreditRedemptionCalculatorFacet creditRedemptionCalculator;
    DollarMintCalculatorFacet dollarMintCalculator;
    CreditNftManagerFacet creditNftManager;
    DollarMintExcessFacet dollarMintExcess;
    address metaPoolAddress;

    function setUp() public virtual override {
        super.setUp();

        twapOracle = ITWAPOracleDollar3pool;
        creditNftRedemptionCalculator = ICreditNftRedemptionCalculationFacet;
        creditRedemptionCalculator = ICreditRedemptionCalculationFacet;
        dollarMintCalculator = IDollarMintCalcFacet;
        creditNftManager = ICreditNftManagerFacet;
        dollarMintExcess = IDollarMintExcessFacet;

        vm.startPrank(admin);

        //mint some dollar token
        IDollar.mint(address(0x1045256), 10000e18);
        require(
            IDollar.balanceOf(address(0x1045256)) == 10000e18,
            "dollar balance is not 10000e18"
        );

        // twapPrice oracle
        metaPoolAddress = address(
            new MockMetaPool(address(IDollar), curve3CRVTokenAddress)
        );
        // set the mock data for meta pool
        uint256[2] memory _price_cumulative_last = [
            uint256(100e18),
            uint256(100e18)
        ];
        uint256 _last_block_timestamp = 20000;
        uint256[2] memory _twap_balances = [uint256(100e18), uint256(100e18)];
        uint256[2] memory _dy_values = [uint256(100e18), uint256(100e18)];
        MockMetaPool(metaPoolAddress).updateMockParams(
            _price_cumulative_last,
            _last_block_timestamp,
            _twap_balances,
            _dy_values
        );

        // deploy credit token
        creditToken = new UbiquityCreditToken(address(diamond));
        IManager.setCreditTokenAddress(address(creditToken));

        // set treasury address
        IManager.setTreasuryAddress(treasuryAddress);

        vm.stopPrank();
        vm.prank(owner);
        ITWAPOracleDollar3pool.setPool(metaPoolAddress, curve3CRVTokenAddress);
        ITWAPOracleDollar3pool.update();
    }
}
