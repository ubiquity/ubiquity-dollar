// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./UbiquityDollarManager.sol";
import "../interfaces/IDollarMintCalculator.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TWAPOracleDollar3pool.sol";
import "abdk-libraries-solidity/ABDKMathQuad.sol";

/// @title A mock coupon calculator that always returns a constant
contract DollarMintCalculator is IDollarMintCalculator {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    bytes16 private immutable _one = (uint256(1 ether)).fromUInt();
    UbiquityDollarManager public manager;

    /// @param _manager the address of the manager contract so we can fetch variables
    constructor(address _manager) {
        manager = UbiquityDollarManager(_manager);
    }

    /// @notice returns (TWAP_PRICE  -1) * UAD_Total_Supply
    function getDollarsToMint() external view override returns (uint256) {
        TWAPOracleDollar3pool oracle = TWAPOracleDollar3pool(manager.twapOracleAddress());
        uint256 twapPrice = oracle.consult(manager.dollarTokenAddress());
        require(twapPrice > 1 ether, "DollarMintingCalculator: not > 1");
        bytes16 totalSupplyOfDollarToken = IERC20(manager.dollarTokenAddress()).totalSupply().fromUInt();
        return twapPrice.fromUInt().sub(_one).mul(totalSupplyOfDollarToken).div(_one).toUInt();
    }
}
