// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ILiquityStabilityPool} from "../interfaces/ILiquityStabilityPool.sol";

/**
 * @notice Library for managing LUSD deposits into the Liquity V1 Stability Pool
 * @notice Follows the diamond storage pattern used across the Ubiquity protocol.
 *         Handles deposit, withdrawal, and gain harvesting operations.
 */
library LibStabilityPool {
    using SafeERC20 for IERC20;

    /// @notice Storage slot used to store data for this library
    bytes32 constant STABILITY_POOL_STORAGE_POSITION =
        bytes32(
            uint256(
                keccak256("ubiquity.contracts.stability.pool.storage")
            ) - 1
        ) & ~bytes32(uint256(0xff));

    /// @notice Struct used as a storage for this library
    struct StabilityPoolStorage {
        /// @notice Address of the Liquity V1 Stability Pool contract
        address stabilityPool;
        /// @notice Address of the LUSD token
        address lusdToken;
        /// @notice Address of the LQTY token
        address lqtyToken;
        /// @notice Protocol treasury that receives harvested ETH/LQTY gains
        address protocolTreasury;
        /// @notice Frontend tag address for Liquity frontend kickback rate
        address frontEndTag;
        /// @notice Total LUSD principal deposited (before any liquidation losses)
        uint256 totalPrincipalInPool;
    }

    /// @notice Emitted when LUSD is deposited to the Liquity Stability Pool
    event DepositedToStabilityPool(uint256 amount);

    /// @notice Emitted when LUSD is withdrawn from the Liquity Stability Pool
    event WithdrawnFromStabilityPool(uint256 amount);

    /// @notice Emitted when ETH/LQTY gains are harvested
    event GainsHarvested(
        uint256 ethGain,
        uint256 lqtyGain,
        address treasury
    );

    /// @notice Emitted when the Stability Pool address is configured
    event StabilityPoolAddressSet(address stabilityPool);

    /// @notice Emitted when the LUSD token address is configured
    event LusdTokenAddressSet(address lusdToken);

    /// @notice Emitted when the LQTY token address is configured
    event LqtyTokenAddressSet(address lqtyToken);

    /// @notice Emitted when the protocol treasury address is configured
    event ProtocolTreasurySet(address treasury);

    /// @notice Emitted when the frontend tag is updated
    event FrontEndTagSet(address frontEndTag);

    /**
     * @notice Returns struct used as a storage for this library
     * @return ss Struct used as a storage
     */
    function stabilityPoolStorage()
        internal
        pure
        returns (StabilityPoolStorage storage ss)
    {
        bytes32 position = STABILITY_POOL_STORAGE_POSITION;
        assembly {
            ss.slot := position
        }
    }

    /**
     * @notice Deposits LUSD into the Liquity Stability Pool
     * @dev LUSD must already be held by this contract (the diamond proxy).
     *      The caller is responsible for transferring LUSD to the diamond before calling.
     * @param amount Amount of LUSD to deposit
     */
    function depositToPool(uint256 amount) internal {
        StabilityPoolStorage storage ss = stabilityPoolStorage();

        require(amount > 0, "StabilityPool: zero deposit");
        require(
            ss.stabilityPool != address(0),
            "StabilityPool: pool not set"
        );
        require(ss.lusdToken != address(0), "StabilityPool: LUSD not set");

        IERC20 lusd = IERC20(ss.lusdToken);

        // Verify the diamond holds sufficient LUSD
        uint256 balance = lusd.balanceOf(address(this));
        require(balance >= amount, "StabilityPool: insufficient LUSD");

        // Approve the Stability Pool to pull LUSD
        lusd.safeApprove(ss.stabilityPool, 0);
        lusd.safeApprove(ss.stabilityPool, amount);

        // Deposit to Liquity Stability Pool
        ILiquityStabilityPool(ss.stabilityPool).provideToSP(
            amount,
            ss.frontEndTag
        );

        // Track principal
        ss.totalPrincipalInPool += amount;

        emit DepositedToStabilityPool(amount);
    }

    /**
     * @notice Withdraws LUSD from the Liquity Stability Pool
     * @dev Also triggers collection of any pending ETH/LQTY gains.
     *      The withdrawn LUSD is sent back to the diamond.
     * @param amount Amount of LUSD to withdraw
     */
    function withdrawFromPool(uint256 amount) internal {
        StabilityPoolStorage storage ss = stabilityPoolStorage();

        require(amount > 0, "StabilityPool: zero withdrawal");
        require(
            ss.stabilityPool != address(0),
            "StabilityPool: pool not set"
        );

        // Get current compounded deposit to validate withdrawal amount
        uint256 compoundedDeposit = ILiquityStabilityPool(ss.stabilityPool)
            .getCompoundedLUSDDeposit(address(this));
        require(
            amount <= compoundedDeposit,
            "StabilityPool: amount exceeds deposit"
        );

        // Capture pre-withdrawal balances for gain calculation
        uint256 ethBefore = address(this).balance;
        uint256 lqtyBefore = ss.lqtyToken != address(0)
            ? IERC20(ss.lqtyToken).balanceOf(address(this))
            : 0;

        // Withdraw from Liquity Stability Pool (also collects gains)
        ILiquityStabilityPool(ss.stabilityPool).withdrawFromSP(amount);

        // Update principal tracking (cap at actual withdrawal to handle liquidation losses)
        if (amount >= ss.totalPrincipalInPool) {
            ss.totalPrincipalInPool = 0;
        } else {
            ss.totalPrincipalInPool -= amount;
        }

        // Forward harvested gains to treasury
        _forwardGains(ss, ethBefore, lqtyBefore);

        emit WithdrawnFromStabilityPool(amount);
    }

    /**
     * @notice Harvests ETH and LQTY gains without changing the LUSD deposit
     * @dev Calls withdrawFromSP(0) to trigger gain collection without reducing deposit.
     *      Gains are forwarded to the protocol treasury.
     */
    function harvestGains() internal {
        StabilityPoolStorage storage ss = stabilityPoolStorage();

        require(
            ss.stabilityPool != address(0),
            "StabilityPool: pool not set"
        );
        require(
            ss.protocolTreasury != address(0),
            "StabilityPool: treasury not set"
        );

        // Capture pre-harvest balances
        uint256 ethBefore = address(this).balance;
        uint256 lqtyBefore = ss.lqtyToken != address(0)
            ? IERC20(ss.lqtyToken).balanceOf(address(this))
            : 0;

        // Withdraw 0 to trigger gain collection only
        ILiquityStabilityPool(ss.stabilityPool).withdrawFromSP(0);

        // Forward gains to treasury
        _forwardGains(ss, ethBefore, lqtyBefore);
    }

    /**
     * @notice Returns the current compounded LUSD deposit in the Stability Pool
     * @return Compounded LUSD balance (principal minus liquidation losses)
     */
    function getPoolBalance() internal view returns (uint256) {
        StabilityPoolStorage storage ss = stabilityPoolStorage();

        if (ss.stabilityPool == address(0)) {
            return 0;
        }

        return
            ILiquityStabilityPool(ss.stabilityPool)
                .getCompoundedLUSDDeposit(address(this));
    }

    /**
     * @notice Returns the total LUSD principal deposited
     * @return Total principal in pool
     */
    function getTotalPrincipal() internal view returns (uint256) {
        StabilityPoolStorage storage ss = stabilityPoolStorage();
        return ss.totalPrincipalInPool;
    }

    /**
     * @notice Returns the pending ETH gain from liquidations
     * @return ETH gain accrued
     */
    function getETHGain() internal view returns (uint256) {
        StabilityPoolStorage storage ss = stabilityPoolStorage();

        if (ss.stabilityPool == address(0)) {
            return 0;
        }

        return
            ILiquityStabilityPool(ss.stabilityPool).getDepositorETHGain(
                address(this)
            );
    }

    /**
     * @notice Returns the pending LQTY reward gain
     * @return LQTY gain accrued
     */
    function getLQTYGain() internal view returns (uint256) {
        StabilityPoolStorage storage ss = stabilityPoolStorage();

        if (ss.stabilityPool == address(0)) {
            return 0;
        }

        return
            ILiquityStabilityPool(ss.stabilityPool).getDepositorLQTYGain(
                address(this)
            );
    }

    /**
     * @notice Sets the Liquity Stability Pool contract address
     * @param _stabilityPool Address of the Liquity Stability Pool
     */
    function setStabilityPoolAddress(address _stabilityPool) internal {
        require(
            _stabilityPool != address(0),
            "StabilityPool: zero address"
        );
        StabilityPoolStorage storage ss = stabilityPoolStorage();
        ss.stabilityPool = _stabilityPool;
        emit StabilityPoolAddressSet(_stabilityPool);
    }

    /**
     * @notice Sets the LUSD token address
     * @param _lusdToken Address of the LUSD ERC20 token
     */
    function setLusdTokenAddress(address _lusdToken) internal {
        require(_lusdToken != address(0), "StabilityPool: zero address");
        StabilityPoolStorage storage ss = stabilityPoolStorage();
        ss.lusdToken = _lusdToken;
        emit LusdTokenAddressSet(_lusdToken);
    }

    /**
     * @notice Sets the LQTY token address
     * @param _lqtyToken Address of the LQTY ERC20 token
     */
    function setLqtyTokenAddress(address _lqtyToken) internal {
        require(_lqtyToken != address(0), "StabilityPool: zero address");
        StabilityPoolStorage storage ss = stabilityPoolStorage();
        ss.lqtyToken = _lqtyToken;
        emit LqtyTokenAddressSet(_lqtyToken);
    }

    /**
     * @notice Sets the protocol treasury address
     * @param _treasury Address of the protocol treasury
     */
    function setProtocolTreasury(address _treasury) internal {
        require(_treasury != address(0), "StabilityPool: zero address");
        StabilityPoolStorage storage ss = stabilityPoolStorage();
        ss.protocolTreasury = _treasury;
        emit ProtocolTreasurySet(_treasury);
    }

    /**
     * @notice Sets the frontend tag for Liquity frontend kickback rewards
     * @param _frontEndTag Address of the frontend operator
     */
    function setFrontEndTag(address _frontEndTag) internal {
        StabilityPoolStorage storage ss = stabilityPoolStorage();
        ss.frontEndTag = _frontEndTag;
        emit FrontEndTagSet(_frontEndTag);
    }

    /**
     * @notice Forwards ETH and LQTY gains to the protocol treasury
     * @param ss Storage reference
     * @param ethBefore ETH balance before the operation
     * @param lqtyBefore LQTY balance before the operation
     */
    function _forwardGains(
        StabilityPoolStorage storage ss,
        uint256 ethBefore,
        uint256 lqtyBefore
    ) private {
        uint256 ethGain = address(this).balance - ethBefore;
        uint256 lqtyGain = 0;

        if (ss.lqtyToken != address(0)) {
            lqtyGain =
                IERC20(ss.lqtyToken).balanceOf(address(this)) -
                lqtyBefore;
        }

        address treasury = ss.protocolTreasury;

        // Forward ETH gains
        if (ethGain > 0 && treasury != address(0)) {
            (bool success, ) = treasury.call{value: ethGain}("");
            require(success, "StabilityPool: ETH transfer failed");
        }

        // Forward LQTY gains
        if (lqtyGain > 0 && treasury != address(0)) {
            IERC20(ss.lqtyToken).safeTransfer(treasury, lqtyGain);
        }

        if (ethGain > 0 || lqtyGain > 0) {
            emit GainsHarvested(ethGain, lqtyGain, treasury);
        }
    }
}
