// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Modifiers} from "../libraries/LibAppStorage.sol";
import {LibDirectGovernanceFarmer} from "../libraries/LibDirectGovernanceFarmer.sol";
import {IUbiquityDollarManager} from "../interfaces/IUbiquityDollarManager.sol";

/**
 * @notice Simpler Staking Facet
 * @notice How it works:
 * 1. User sends stablecoins (DAI / USDC / USDT / Dollar)
 * 2. Deposited stablecoins are added to Dollar-3CRV Curve MetaPool
 * 3. User gets Dollar-3CRV LP tokens
 * 4. Dollar-3CRV LP tokens are transferred to the staking contract
 * 5. User gets a staking share id
 */
contract DirectGovernanceFarmerFacet is Modifiers {
    //====================
    // Restricted functions
    //====================

    /**
    @notice it works as a constructor to set contract values at storage
    @param _manager Ubiquity Manager
    @param base3Pool Base3Pool Address
    @param ubiquity3PoolLP Ubiquity3PoolLP Address
    @param _ubiquityDollar Ubiquity Dollar Address
    @param zapPool ZapPool Address
    */
    function initialize(
        address _manager,
        address base3Pool,
        address ubiquity3PoolLP,
        address _ubiquityDollar,
        address zapPool
    ) public onlyAdmin {
        LibDirectGovernanceFarmer.init(
            _manager,
            base3Pool,
            ubiquity3PoolLP,
            _ubiquityDollar,
            zapPool
        );
    }

    //====================
    // Public/User functions
    //====================

    /**
     * @notice Deposits a single token to staking
     * @notice Stable coin (DAI / USDC / USDT / Ubiquity Dollar) => Dollar-3CRV LP => Ubiquity Staking
     * @notice How it works:
     * 1. User sends stablecoins (DAI / USDC / USDT / Dollar)
     * 2. Deposited stablecoins are added to Dollar-3CRV Curve MetaPool
     * 3. User gets Dollar-3CRV LP tokens
     * 4. Dollar-3CRV LP tokens are transferred to the staking contract
     * 5. User gets a staking share id
     * @param token Token deposited : DAI, USDC, USDT or Ubiquity Dollar
     * @param amount Amount of tokens to deposit (For max: `uint256(-1)`)
     * @param durationWeeks Duration in weeks tokens will be locked (1-208)
     */
    function depositSingle(
        address token,
        uint256 amount,
        uint256 durationWeeks
    ) external nonReentrant returns (uint256 stakingShareId) {
        return
            LibDirectGovernanceFarmer.depositSingle(
                token,
                amount,
                durationWeeks
            );
    }

    /**
     * @notice Deposits into Ubiquity protocol
     * @notice Stable coins (DAI / USDC / USDT / Ubiquity Dollar) => uAD3CRV-f => Ubiquity StakingShare
     * @notice STEP 1 : Change (DAI / USDC / USDT / Ubiquity dollar) to 3CRV at uAD3CRV MetaPool
     * @notice STEP 2 : uAD3CRV-f => Ubiquity StakingShare
     * @param tokenAmounts Amount of tokens to deposit (For max: `uint256(-1)`) it MUST follow this order [Ubiquity Dollar, DAI, USDC, USDT]
     * @param durationWeeks Duration in weeks tokens will be locked (1-208)
     * @return stakingShareId Staking share id
     */
    function depositMulti(
        uint256[4] calldata tokenAmounts,
        uint256 durationWeeks
    ) external nonReentrant returns (uint256 stakingShareId) {
        return
            LibDirectGovernanceFarmer.depositMulti(tokenAmounts, durationWeeks);
    }

    /**
     * @notice Withdraws from Ubiquity protocol
     * @notice Ubiquity StakingShare => uAD3CRV-f  => stable coin (DAI / USDC / USDT / Ubiquity Dollar)
     * @notice STEP 1 : Ubiquity StakingShare  => uAD3CRV-f
     * @notice STEP 2 : uAD3CRV-f => stable coin (DAI / USDC / USDT / Ubiquity Dollar)
     * @param stakingShareId Staking Share Id to withdraw
     * @return tokenAmounts Array of token amounts [Ubiquity Dollar, DAI, USDC, USDT]
     */
    function withdrawId(
        uint256 stakingShareId
    ) external nonReentrant returns (uint256[4] memory tokenAmounts) {
        return LibDirectGovernanceFarmer.withdrawWithId(stakingShareId);
    }

    /**
     * @notice Withdraws from Ubiquity protocol
     * @notice Ubiquity StakingShare => uAD3CRV-f  => stable coin (DAI / USDC / USDT / Ubiquity Dollar)
     * @notice STEP 1 : Ubiquity StakingShare  => uAD3CRV-f
     * @notice STEP 2 : uAD3CRV-f => stable coin (DAI / USDC / USDT / Ubiquity Dollar)
     * @param stakingShareId Staking Share Id to withdraw
     * @param token Token to withdraw to : DAI, USDC, USDT, 3CRV or Ubiquity Dollar
     * @return tokenAmount Amount of token withdrawn
     */
    function withdraw(
        uint256 stakingShareId,
        address token
    ) external nonReentrant returns (uint256 tokenAmount) {
        return LibDirectGovernanceFarmer.withdraw(stakingShareId, token);
    }

    //=====================
    // Helper Views
    //=====================

    /**
     * @notice Checks whether `id` exists in `idList[]`
     * @param idList Array to search in
     * @param id Value to search in `idList`
     * @return Whether `id` exists in `idList[]`
     */
    function isIdIncluded(
        uint256[] memory idList,
        uint256 id
    ) external pure returns (bool) {
        return LibDirectGovernanceFarmer.isIdIncluded(idList, id);
    }

    /**
     * @notice Helper function that checks that `token` is one of the underlying MetaPool tokens or stablecoin from MetaPool
     * @param token Token address to check
     * @return Whether `token` is one of the underlying MetaPool tokens or stablecoin from MetaPool
     */
    function isMetaPoolCoin(address token) external pure returns (bool) {
        return LibDirectGovernanceFarmer.isMetaPoolCoin(token);
    }
}
