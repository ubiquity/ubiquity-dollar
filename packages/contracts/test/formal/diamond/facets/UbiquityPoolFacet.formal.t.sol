// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

// solhint-disable foundry-test-functions

/**
 * @notice SMTChecker harness for `LibUbiquityPool` mint and redeem accounting.
 * @dev The public `prove...` functions mirror the library's fee, collateral
 * ratio, and collateral conversion math while keeping the verification target
 * free of deployment and external oracle dependencies.
 */
contract UbiquityPoolFacetFormalTest {
    /// @dev Mirrors `UBIQUITY_POOL_PRICE_PRECISION` used by `LibUbiquityPool`.
    uint256 private constant PRICE_PRECISION = 1e6;

    function proveMintValueCannotExceedExactCollateralValue(
        uint128 dollarAmount,
        uint24 mintingFee,
        uint64 collateralPrice,
        uint8 missingDecimals
    ) public pure {
        require(dollarAmount > 0, "Invalid dollar amount");
        require(mintingFee <= PRICE_PRECISION, "Invalid mint fee");
        require(collateralPrice > 0, "Invalid collateral price");
        require(
            _isSupportedMissingDecimals(missingDecimals),
            "Invalid decimals"
        );

        uint256 decimalMultiplier = _decimalMultiplier(missingDecimals);
        uint256 scaledDollarAmount = uint256(dollarAmount) * PRICE_PRECISION;
        require(
            scaledDollarAmount % decimalMultiplier == 0,
            "Inexact decimal scaling"
        );

        uint256 collateralPriceAdjustedAmount = scaledDollarAmount /
            decimalMultiplier;
        require(
            collateralPriceAdjustedAmount % uint256(collateralPrice) == 0,
            "Inexact price scaling"
        );

        uint256 collateralNeeded = collateralPriceAdjustedAmount /
            uint256(collateralPrice);
        uint256 collateralUsdValue = (collateralNeeded *
            decimalMultiplier *
            uint256(collateralPrice)) / PRICE_PRECISION;
        uint256 totalDollarMint = _applyFee(dollarAmount, mintingFee);

        assert(totalDollarMint <= collateralUsdValue);
    }

    function proveFractionalMintValueCannotExceedInputValue(
        uint128 dollarAmount,
        uint24 collateralRatio,
        uint24 mintingFee
    ) public pure {
        require(collateralRatio <= PRICE_PRECISION, "Invalid ratio");
        require(mintingFee <= PRICE_PRECISION, "Invalid mint fee");

        (
            uint256 collateralUsdValue,
            uint256 governanceUsdValue
        ) = _mintValueSplit(dollarAmount, collateralRatio, false);
        uint256 totalDollarMint = _applyFee(dollarAmount, mintingFee);

        assert(totalDollarMint <= collateralUsdValue + governanceUsdValue);
    }

    function proveForcedOneToOneMintValueCannotExceedInputValue(
        uint128 dollarAmount,
        uint24 collateralRatio,
        uint24 mintingFee
    ) public pure {
        require(collateralRatio <= PRICE_PRECISION, "Invalid ratio");
        require(mintingFee <= PRICE_PRECISION, "Invalid mint fee");

        (
            uint256 collateralUsdValue,
            uint256 governanceUsdValue
        ) = _mintValueSplit(dollarAmount, collateralRatio, true);
        uint256 totalDollarMint = _applyFee(dollarAmount, mintingFee);

        assert(totalDollarMint <= collateralUsdValue + governanceUsdValue);
    }

    function proveRedeemValueCannotExceedBurnedDollarValue(
        uint128 dollarAmount,
        uint24 collateralRatio,
        uint24 redemptionFee
    ) public pure {
        require(collateralRatio <= PRICE_PRECISION, "Invalid ratio");
        require(redemptionFee <= PRICE_PRECISION, "Invalid redemption fee");

        uint256 dollarAfterFee = _applyFee(dollarAmount, redemptionFee);
        (
            uint256 collateralUsdValue,
            uint256 governanceUsdValue
        ) = _redeemValueSplit(dollarAfterFee, collateralRatio);

        assert(collateralUsdValue + governanceUsdValue <= dollarAmount);
    }

    function proveRedeemCollateralConversionCannotOverpay(
        uint128 dollarAfterFee,
        uint64 collateralPrice,
        uint8 missingDecimals
    ) public pure {
        require(collateralPrice > 0, "Invalid collateral price");
        require(
            _isSupportedMissingDecimals(missingDecimals),
            "Invalid decimals"
        );

        uint256 decimalMultiplier = _decimalMultiplier(missingDecimals);
        uint256 collateralOut = ((uint256(dollarAfterFee) * PRICE_PRECISION) /
            decimalMultiplier) / uint256(collateralPrice);
        uint256 collateralUsdValue = (collateralOut *
            decimalMultiplier *
            uint256(collateralPrice)) / PRICE_PRECISION;

        assert(collateralUsdValue <= dollarAfterFee);
    }

    function _mintValueSplit(
        uint256 dollarAmount,
        uint256 collateralRatio,
        bool isOneToOne
    )
        private
        pure
        returns (uint256 collateralUsdValue, uint256 governanceUsdValue)
    {
        if (isOneToOne || collateralRatio >= PRICE_PRECISION) {
            collateralUsdValue = dollarAmount;
            governanceUsdValue = 0;
        } else if (collateralRatio == 0) {
            collateralUsdValue = 0;
            governanceUsdValue = dollarAmount;
        } else {
            collateralUsdValue = (dollarAmount * collateralRatio) /
                PRICE_PRECISION;
            governanceUsdValue = dollarAmount - collateralUsdValue;
        }
    }

    function _redeemValueSplit(
        uint256 dollarAfterFee,
        uint256 collateralRatio
    )
        private
        pure
        returns (uint256 collateralUsdValue, uint256 governanceUsdValue)
    {
        if (collateralRatio >= PRICE_PRECISION) {
            collateralUsdValue = dollarAfterFee;
            governanceUsdValue = 0;
        } else if (collateralRatio == 0) {
            collateralUsdValue = 0;
            governanceUsdValue = dollarAfterFee;
        } else {
            collateralUsdValue = (dollarAfterFee * collateralRatio) /
                PRICE_PRECISION;
            governanceUsdValue =
                (dollarAfterFee * (PRICE_PRECISION - collateralRatio)) /
                PRICE_PRECISION;
        }
    }

    function _applyFee(
        uint256 dollarAmount,
        uint256 fee
    ) private pure returns (uint256) {
        return (dollarAmount * (PRICE_PRECISION - fee)) / PRICE_PRECISION;
    }

    function _decimalMultiplier(
        uint8 missingDecimals
    ) private pure returns (uint256) {
        if (missingDecimals == 0) return 1;
        if (missingDecimals == 12) return 1e12;
        if (missingDecimals == 18) return 1e18;

        revert("Unsupported missing decimals");
    }

    function _isSupportedMissingDecimals(
        uint8 missingDecimals
    ) private pure returns (bool) {
        return
            missingDecimals == 0 ||
            missingDecimals == 12 ||
            missingDecimals == 18;
    }
}
