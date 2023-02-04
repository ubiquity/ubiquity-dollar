// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {UbiquityDollarManager} from "../../src/dollar/core/UbiquityDollarManager.sol";
import {UbiquityGovernanceToken} from "../../src/dollar/core/UbiquityGovernanceToken.sol";
import {CreditRedemptionCalculator} from "../../src/dollar/core/CreditRedemptionCalculator.sol";
import {CreditNftRedemptionCalculator} from "../../src/dollar/core/CreditNftRedemptionCalculator.sol";
import {CreditNftManager} from "../../src/dollar/core/CreditNftManager.sol";
import {DollarMintCalculator} from "../../src/dollar/core/DollarMintCalculator.sol";
import {DollarMintExcess} from "../../src/dollar/core/DollarMintExcess.sol";
import {MockCreditNft} from "../../src/dollar/mocks/MockCreditNft.sol";
import {MockDollarToken} from "../../src/dollar/mocks/MockDollarToken.sol";
import {MockTWAPOracleDollar3pool} from "../../src/dollar/mocks/MockTWAPOracleDollar3pool.sol";
import {MockCreditToken} from "../../src/dollar/mocks/MockCreditToken.sol";

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract MockCreditNftRedemptionCalculator {
    constructor() {}

    function getCreditNftAmount(
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
    MockCreditNft creditNft;
    MockDollarToken dollarToken;
    MockTWAPOracleDollar3pool twapOracle;
    UbiquityGovernanceToken governanceToken;
    MockCreditNftRedemptionCalculator creditNftRedemptionCalculator;
    MockCreditToken creditToken;
    CreditRedemptionCalculator creditRedemptionCalculator;
    DollarMintCalculator dollarMintCalculator;
    CreditNftManager creditNftManager;
    DollarMintExcess dollarMintExcess;

    function setUp() public virtual {
        manager = new UbiquityDollarManager(admin);

        vm.startPrank(admin);
        // deploy credit NFT token
        creditNft = new MockCreditNft(100);
        manager.setCreditNftAddress(address(creditNft));

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

        // deploy CreditNftRedemptionCalculator
        creditNftRedemptionCalculator = new MockCreditNftRedemptionCalculator();
        manager.setCreditNftCalculatorAddress(
            address(creditNftRedemptionCalculator)
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

        // deploy CreditNftManager
        creditNftManager = new CreditNftManager(manager, 100);

        dollarMintExcess = new DollarMintExcess(manager);
        manager.setExcessDollarsDistributor(
            address(creditNftManager),
            address(dollarMintExcess)
        );

        // set treasury address
        manager.setTreasuryAddress(treasuryAddress);

        vm.stopPrank();
    }
}
