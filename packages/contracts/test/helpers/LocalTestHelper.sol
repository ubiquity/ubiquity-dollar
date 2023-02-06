// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {UbiquityDollarManager} from "../../src/dollar/core/UbiquityDollarManager.sol";
import {UbiquityGovernanceToken} from "../../src/dollar/core/UbiquityGovernanceToken.sol";
import {CreditRedemptionCalculator} from "../../src/dollar/core/CreditRedemptionCalculator.sol";
import {CreditNFTRedemptionCalculator} from "../../src/dollar/core/CreditNFTRedemptionCalculator.sol";
import {CreditNFTManager} from "../../src/dollar/core/CreditNFTManager.sol";
import {DollarMintCalculator} from "../../src/dollar/core/DollarMintCalculator.sol";
import {DollarMintExcess} from "../../src/dollar/core/DollarMintExcess.sol";
import {MockCreditNFT} from "../../src/dollar/mocks/MockCreditNFT.sol";
import {MockDollarToken} from "../../src/dollar/mocks/MockDollarToken.sol";
import {MockTWAPOracleDollar3pool} from "../../src/dollar/mocks/MockTWAPOracleDollar3pool.sol";
import {MockCreditToken} from "../../src/dollar/mocks/MockCreditToken.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract MockCreditNFTRedemptionCalculator {
    constructor() {}

    function getCreditNFTAmount(
        uint256 dollarsToBurn
    ) external pure returns (uint256) {
        return dollarsToBurn;
    }
}

abstract contract LocalTestHelper is Test {
    address public constant NATIVE_ASSET = address(0);

    address public admin = address(0x123abc);
    address public treasuryAddress = address(0x111222333);

    UbiquityDollarManager manager;
    MockCreditNFT creditNFT;
    MockDollarToken dollarToken;
    MockTWAPOracleDollar3pool twapOracle;
    UbiquityGovernanceToken governanceToken;
    MockCreditNFTRedemptionCalculator creditNFTRedemptionCalculator;
    MockCreditToken creditToken;
    CreditRedemptionCalculator creditRedemptionCalculator;
    DollarMintCalculator dollarMintCalculator;
    CreditNFTManager creditNFTManager;
    DollarMintExcess dollarMintExcess;

    function setUp() public virtual {
        manager = new UbiquityDollarManager(admin);

        vm.startPrank(admin);
        // deploy credit NFT token
        creditNFT = new MockCreditNFT(100);
        manager.setCreditNFTAddress(address(creditNFT));

        // deploy dollar token
        dollarToken = new MockDollarToken(10000e18);
        manager.setDollarTokenAddress(address(dollarToken));

        // deploy twapPrice oracle
        twapOracle = new MockTWAPOracleDollar3pool(
            address(0x100),
            address(dollarToken),
            address(0x101),
            100,
            100
        );
        manager.setTwapOracleAddress(address(twapOracle));

        // deploy governance token
        governanceToken = new UbiquityGovernanceToken(manager);
        manager.setGovernanceTokenAddress(address(governanceToken));

        // deploy CreditNFTRedemptionCalculator
        creditNFTRedemptionCalculator = new MockCreditNFTRedemptionCalculator();
        manager.setCreditNFTCalculatorAddress(
            address(creditNFTRedemptionCalculator)
        );

        // deploy credit token
        creditToken = new MockCreditToken(0);
        manager.setCreditTokenAddress(address(creditToken));

        // deploy CreditRedemptionCalculator
        creditRedemptionCalculator = new CreditRedemptionCalculator(manager);
        manager.setCreditCalculatorAddress(address(creditRedemptionCalculator));

        // deploy DollarMintCalculator
        dollarMintCalculator = new DollarMintCalculator(manager);
        manager.setDollarMintCalculatorAddress(address(dollarMintCalculator));

        // deploy CreditNFTManager
        creditNFTManager = new CreditNFTManager(manager, 100);

        dollarMintExcess = new DollarMintExcess(manager);
        manager.setExcessDollarsDistributor(
            address(creditNFTManager),
            address(dollarMintExcess)
        );

        // set treasury address
        manager.setTreasuryAddress(treasuryAddress);

        vm.stopPrank();
    }
}
