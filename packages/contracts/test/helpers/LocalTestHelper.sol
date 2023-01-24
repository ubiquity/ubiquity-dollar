// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {UbiquityDollarManager} from "../../src/dollar/core/UbiquityDollarManager.sol";
import {UbiquityGovernanceToken} from "../../src/dollar/core/UbiquityGovernanceToken.sol";
import {CreditRedemptionCalculator} from "../../src/dollar/core/CreditRedemptionCalculator.sol";
import {CreditNftRedemptionCalculator} from "../../src/dollar/core/CreditNftRedemptionCalculator.sol";
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

    function helpers_deployUbiquityDollarManager() public returns (address) {
        UbiquityDollarManager _manager = new UbiquityDollarManager(admin);

        vm.startPrank(admin);
        // deploy credit NFT token
        MockCreditNft _creditNft = new MockCreditNft(100);
        _manager.setCreditNftAddress(address(_creditNft));

        // deploy dollar token
        MockDollarToken _dollarToken = new MockDollarToken(10000e18);
        _manager.setDollarTokenAddress(address(_dollarToken));

        // deploy twapPrice oracle
        MockTWAPOracleDollar3pool _twapOracle = new MockTWAPOracleDollar3pool(
            address(0x100),
            address(_dollarToken),
            address(0x101),
            100,
            100
        );
        _manager.setTwapOracleAddress(address(_twapOracle));

        // deploy governance token
        UbiquityGovernanceToken _governanceToken = new UbiquityGovernanceToken(
            address(_manager)
        );
        _manager.setGovernanceTokenAddress(address(_governanceToken));

        // deploy CreditNftRedemptionCalculator
        MockCreditNftRedemptionCalculator _creditNftRedemptionCalculator = new MockCreditNftRedemptionCalculator();
        _manager.setCreditNftCalculatorAddress(
            address(_creditNftRedemptionCalculator)
        );

        // deploy credit token
        MockCreditToken _creditToken = new MockCreditToken(0);
        _manager.setCreditTokenAddress(address(_creditToken));

        // deploy CreditRedemptionCalculator
        CreditRedemptionCalculator _creditRedemptionCalculator = new CreditRedemptionCalculator(
                address(_manager)
            );
        _manager.setCreditCalculatorAddress(
            address(_creditRedemptionCalculator)
        );

        // deploy DollarMintCalculator
        DollarMintCalculator _dollarMintCalculator = new DollarMintCalculator(
            address(_manager)
        );
        _manager.setDollarMintCalculatorAddress(address(_dollarMintCalculator));

        // set treasury address
        _manager.setTreasuryAddress(treasuryAddress);

        vm.stopPrank();

        return address(_manager);
    }
}
