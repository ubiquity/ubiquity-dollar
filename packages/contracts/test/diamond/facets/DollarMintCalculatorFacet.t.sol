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
        MockCurveStableSwapMetaNG(managerFacet.stableSwapMetaPoolAddress())
            .updateMockParams(_twapPrice);
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
