// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {MockCreditNft} from "../../src/dollar/mocks/MockCreditNft.sol";
import {MockTWAPOracleDollar3pool} from "../../src/dollar/mocks/MockTWAPOracleDollar3pool.sol";
import {MockCreditToken} from "../../src/dollar/mocks/MockCreditToken.sol";
import {DiamondSetup} from "../diamond/DiamondTestSetup.sol";
import {ManagerFacet} from "../../src/diamond/facets/ManagerFacet.sol";
import {TWAPOracleDollar3poolFacet} from "../../src/diamond/facets/TWAPOracleDollar3poolFacet.sol";
import {CreditRedemptionCalculatorFacet} from "../../src/diamond/facets/CreditRedemptionCalculatorFacet.sol";
import {CreditNftRedemptionCalculatorFacet} from "../../src/diamond/facets/CreditNftRedemptionCalculatorFacet.sol";
import {DollarMintCalculatorFacet} from "../../src/diamond/facets/DollarMintCalculatorFacet.sol";
import {CreditNftManagerFacet} from "../../src/diamond/facets/CreditNftManagerFacet.sol";
import {DollarMintExcessFacet} from "../../src/diamond/facets/DollarMintExcessFacet.sol";
import {UbiquityDollarTokenForDiamond} from "../../src/diamond/token/UbiquityDollarTokenForDiamond.sol";
import {MockMetaPool} from "../../src/dollar/mocks/MockMetaPool.sol";
import {UbiquityDollarManager} from "../../src/dollar/old/UbiquityDollarManager.sol";
import "forge-std/Test.sol";

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

    UbiquityDollarManager manager;

    MockCreditNft creditNft;

    TWAPOracleDollar3poolFacet twapOracle;

    CreditNftRedemptionCalculatorFacet creditNftRedemptionCalculator;
    MockCreditToken creditToken;
    CreditRedemptionCalculatorFacet creditRedemptionCalculator;
    DollarMintCalculatorFacet dollarMintCalculator;
    CreditNftManagerFacet creditNftManager;
    DollarMintExcessFacet dollarMintExcess;
    address metaPoolAddress;

    function setUp() public virtual override {
        super.setUp();
        manager = UbiquityDollarManager(address(diamond));
        twapOracle = ITWAPOracleDollar3pool;
        creditNftRedemptionCalculator = ICreditNFTRedCalcFacet;
        creditRedemptionCalculator = ICreditRedCalcFacet;
        dollarMintCalculator = IDollarMintCalcFacet;
        creditNftManager = ICreditNFTMgrFacet;
        dollarMintExcess = IDollarMintExcessFacet;

        vm.startPrank(admin);
        // deploy Credit NFT token
        creditNft = new MockCreditNft(100);
        console.log("0");
        manager.setCreditNftAddress(address(creditNft));
        console.log("1");

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
        console.log("2");

        console.log("2.1");
        // set the mock data for meta pool
        uint256[2] memory _price_cumulative_last = [
            uint256(100e18),
            uint256(100e18)
        ];
        uint256 _last_block_timestamp = 20000;
        uint256[2] memory _twap_balances = [uint256(100e18), uint256(100e18)];
        uint256[2] memory _dy_values = [uint256(100e18), uint256(100e18)];
        console.log("2.2");
        MockMetaPool(metaPoolAddress).updateMockParams(
            _price_cumulative_last,
            _last_block_timestamp,
            _twap_balances,
            _dy_values
        );

        console.log("3");

        // deploy credit token
        creditToken = new MockCreditToken(0);
        manager.setCreditTokenAddress(address(creditToken));
        console.log("2.4");

        // set treasury address
        manager.setTreasuryAddress(treasuryAddress);
        console.log("2.5");

        vm.stopPrank();
        vm.prank(owner);
        ITWAPOracleDollar3pool.setPool(metaPoolAddress, curve3CRVTokenAddress);
        ITWAPOracleDollar3pool.update();
    }
}
