// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../DiamondTestSetup.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DollarMintCalculatorFacetTest is DiamondTestSetup {
    address dollarManagerAddress;
    address dollarAddress;
    address twapOracleAddress;
    address dollarMintCalculatorAddress;

    function setUp() public virtual override {
        super.setUp();
        dollarManagerAddress = address(diamond);
        twapOracleAddress = address(diamond);
        dollarMintCalculatorAddress = address(diamond);
        dollarAddress = address(dollarToken);
    }

    function mockTwapFuncs(uint256 _twapPrice) public {
        uint256 TWAP_ORACLE_STORAGE_POSITION = uint256(
            keccak256("diamond.standard.twap.oracle.storage")
        ) - 1;
        uint256 dollarPricePosition = TWAP_ORACLE_STORAGE_POSITION + 2;
        vm.store(
            address(diamond),
            bytes32(dollarPricePosition),
            bytes32(_twapPrice)
        );
    }

    function test_getDollarsToMintRevertsIfPriceLowerThan1USD() public {
        mockTwapFuncs(5e17);
        vm.expectRevert("DollarMintCalculator: not > 1");
        dollarMintCalculatorFacet.getDollarsToMint();
    }

    function test_getDollarsToMintWorks() public {
        mockTwapFuncs(2e18);
        uint256 totalSupply = IERC20(dollarAddress).totalSupply();
        uint256 amountToMint = dollarMintCalculatorFacet.getDollarsToMint();
        assertEq(amountToMint, totalSupply);
    }
}
