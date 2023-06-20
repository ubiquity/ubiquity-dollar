// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {MockCreditNft} from "../../src/dollar/mocks/mock-credit-nft.sol";
import {MockTWAPOracleDollar3pool} from "../../src/dollar/mocks/mock-twap-oracle-dollar-3-pool.sol";
import {MockCreditToken} from "../../src/dollar/mocks/mock-credit-token.sol";
import {DiamondSetup} from "../diamond/diamond-test-setup.sol";
import {ManagerFacet} from "../../src/dollar/facets/manager-facet.sol";
import {TWAPOracleDollar3poolFacet} from "../../src/dollar/facets/twap-oracle-dollar-3-pool-facet.sol";
import {CreditRedemptionCalculatorFacet} from "../../src/dollar/facets/credit-redemption-calculator-facet.sol";
import {CreditNftRedemptionCalculatorFacet} from "../../src/dollar/facets/credit-nft-redemption-calculator-facet.sol";
import {DollarMintCalculatorFacet} from "../../src/dollar/facets/dollar-mint-calculator-facet.sol";
import {CreditNftManagerFacet} from "../../src/dollar/facets/credit-nft-manager-facet.sol";
import {DollarMintExcessFacet} from "../../src/dollar/facets/dollar-mint-excess-facet.sol";
import {UbiquityDollarToken} from "../../src/dollar/core/ubiquity-dollar-token.sol";
import {MockMetaPool} from "../../src/dollar/mocks/mock-meta-pool.sol";
import {MockUbiquistick} from "../../src/dollar/mocks/mock-ubiquistick.sol";

contract MockCreditNftRedemptionCalculator {
    constructor() {}

    function getCreditNftAmount(
        uint256 dollarsToBurn
    ) external pure returns (uint256) {
        return dollarsToBurn;
    }
}

abstract contract LocalTestHelper is DiamondSetup {
    address public constant NATIVE_ASSET = address(0);
    address curve3CRVTokenAddress = address(0x101);
    address public treasuryAddress = address(0x111222333);

    TWAPOracleDollar3poolFacet twapOracle;

    CreditNftRedemptionCalculatorFacet creditNftRedemptionCalculator;
    MockCreditToken creditToken;
    CreditRedemptionCalculatorFacet creditRedemptionCalculator;
    DollarMintCalculatorFacet dollarMintCalculator;
    CreditNftManagerFacet creditNftManager;
    DollarMintExcessFacet dollarMintExcess;
    address metaPoolAddress;
    MockUbiquistick ubiquiStick;

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

        // deploy ubiquistick
        // ubiquiStick = new MockUbiquistick();
        // IManager.setUbiquiStickAddress(address(ubiquiStick));

        // deploy credit token
        creditToken = new MockCreditToken(0);
        IManager.setCreditTokenAddress(address(creditToken));

        // set treasury address
        IManager.setTreasuryAddress(treasuryAddress);

        vm.stopPrank();
        vm.prank(owner);
        ITWAPOracleDollar3pool.setPool(metaPoolAddress, curve3CRVTokenAddress);
        ITWAPOracleDollar3pool.update();
    }
}
