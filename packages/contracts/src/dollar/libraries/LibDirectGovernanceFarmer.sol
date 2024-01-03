// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUbiquityDollarManager} from "../interfaces/IUbiquityDollarManager.sol";
import {IUbiquityDollarToken} from "../interfaces/IUbiquityDollarToken.sol";
import {IERC20Ubiquity} from "../interfaces/IERC20Ubiquity.sol";
import "../libraries/LibAppStorage.sol";
import "../interfaces/IDepositZap.sol";
import "../interfaces/IStaking.sol";
import "../interfaces/IStakingShare.sol";
import "../interfaces/IStableSwap3Pool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

library LibDirectGovernanceFarmer {
    using SafeERC20 for IERC20;

    /// @notice Emitted when user deposits a single token
    event DepositSingle(
        address indexed sender,
        address token,
        uint256 amount,
        uint256 durationWeeks,
        uint256 stakingShareId
    );

    /// @notice Emitted when user deposits multiple tokens
    event DepositMulti(
        address indexed sender,
        uint256[4] amounts,
        uint256 durationWeeks,
        uint256 stakingShareId
    );

    /// @notice Emitted when user withdraws a single token
    event Withdraw(
        address indexed sender,
        uint256 stakingShareId,
        address token,
        uint256 amount
    );

    /// @notice Emitted when user withdraws multiple tokens
    event WithdrawAll(
        address indexed sender,
        uint256 stakingShareId,
        uint256[4] amounts
    );

    /// @notice Storage slot used to store data for this library
    bytes32 constant DIRECT_GOVERNANCE_STORAGE_POSITION =
        bytes32(
            uint256(keccak256("ubiquity.contracts.direct.governance.storage")) -
                1
        );

    /// @notice Struct used as a storage for the current library
    struct DirectGovernanceData {
        address token0; // DAI
        address token1; // USDC
        address token2; // USDT
        address ubiquity3PoolLP;
        IERC20Ubiquity ubiquityDollar;
        address depositZapUbiquityDollar;
        IUbiquityDollarManager manager;
    }

    /**
     * @notice Returns struct used as a storage for this library
     * @return data Struct used as a storage
     */
    function directGovernanceStorage()
        internal
        pure
        returns (DirectGovernanceData storage data)
    {
        bytes32 position = DIRECT_GOVERNANCE_STORAGE_POSITION;
        assembly {
            data.slot := position
        }
    }

    /// @notice Used to initialize this facet with corresponding values
    function init(
        address _manager,
        address base3Pool,
        address ubiquity3PoolLP,
        address _ubiquityDollar,
        address depositZap
    ) internal {
        DirectGovernanceData storage data = directGovernanceStorage();
        /// Standard Interface Provided by Curve ///
        data.token0 = IStableSwap3Pool(base3Pool).coins(0); // DAI
        data.token1 = IStableSwap3Pool(base3Pool).coins(1); // USDC
        data.token2 = IStableSwap3Pool(base3Pool).coins(2); // USDT
        ////////////////////////////////////////////
        data.ubiquity3PoolLP = address(ubiquity3PoolLP); // Set stable swap pool
        data.ubiquityDollar = IERC20Ubiquity(address(_ubiquityDollar)); // Set Dollar
        data.depositZapUbiquityDollar = address(depositZap); // Set DepositZap
        data.manager = IUbiquityDollarManager(address(_manager)); // Set Manager
    }

    /**
     * @notice Deposits a single token to staking
     * @notice Stable coin (DAI / USDC / USDT / Ubiquity Dollar) => Dollar-3CRV LP => Ubiquity Staking
     * @notice How it works:
     * 1. User deposit stablecoins (DAI / USDC / USDT / Dollar)
     * 2. Deposited stablecoins are added to Dollar-3CRV Curve MetaPool
     * 3. User gets Dollar-3CRV LP tokens
     * 4. Dollar-3CRV LP tokens are transferred to the staking contract
     * 5. User gets a staking share id
     * @param token Token deposited : DAI, USDC, USDT or Ubiquity Dollar
     * @param amount Amount of tokens to deposit (For max: `uint256(-1)`)
     * @param durationWeeks Duration in weeks tokens will be locked (1-208)
     * @return stakingShareId Staking share id
     */
    function depositSingle(
        address token,
        uint256 amount,
        uint256 durationWeeks
    ) internal returns (uint256 stakingShareId) {
        DirectGovernanceData storage data = directGovernanceStorage();
        // DAI / USDC / USDT / Ubiquity Dollar
        require(
            isMetaPoolCoin(token),
            "Invalid token: must be DAI, USD Coin, Tether, or Ubiquity Dollar"
        );
        require(amount > 0, "amount must be positive value");
        require(
            durationWeeks >= 1 && durationWeeks <= 208,
            "duration weeks must be between 1 and 208"
        );

        //Note, due to USDT implementation, normal transferFrom does not work and have an error of "function returned an unexpected amount of data"
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        address staking = address(data.manager.stakingContractAddress());
        address stakingShare = address(data.manager.stakingShareAddress());

        //[Ubiquity Dollar, DAI, USDC, USDT]
        uint256[4] memory tokenAmounts = [
            token == address(data.ubiquityDollar) ? amount : 0,
            token == data.token0 ? amount : 0,
            token == data.token1 ? amount : 0,
            token == data.token2 ? amount : 0
        ];

        //STEP1: add DAI, USDC, USDT or Ubiquity Dollar into metapool liquidity and get UAD3CRVf
        IERC20(token).safeIncreaseAllowance(
            data.depositZapUbiquityDollar,
            amount
        );
        uint256 lpAmount = IDepositZap(data.depositZapUbiquityDollar)
            .add_liquidity(data.ubiquity3PoolLP, tokenAmounts, 0);

        //STEP2: stake UAD3CRVf to Staking

        //TODO approve token to be transferred to Staking contract
        IERC20(token).approve(data.ubiquity3PoolLP, amount);
        IERC20(data.ubiquity3PoolLP).safeIncreaseAllowance(staking, lpAmount);
        stakingShareId = IStaking(staking).deposit(lpAmount, durationWeeks);

        IStakingShare(stakingShare).safeTransferFrom(
            address(this),
            msg.sender,
            stakingShareId,
            1,
            bytes("")
        );

        emit DepositSingle(
            msg.sender,
            token,
            amount,
            durationWeeks,
            stakingShareId
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
    ) internal returns (uint256 stakingShareId) {
        DirectGovernanceData storage data = directGovernanceStorage();
        // at least one should be non zero Ubiquity Dollar / DAI / USDC / USDT
        require(
            tokenAmounts[0] > 0 ||
                tokenAmounts[1] > 0 ||
                tokenAmounts[2] > 0 ||
                tokenAmounts[3] > 0,
            "amounts==0"
        );
        require(
            durationWeeks >= 1 && durationWeeks <= 208,
            "duration weeks must be between 1 and 208"
        );
        // Dollar Token
        if (tokenAmounts[0] > 0) {
            IERC20(data.ubiquityDollar).safeTransferFrom(
                msg.sender,
                address(this),
                tokenAmounts[0]
            );
            IERC20(data.token0).safeIncreaseAllowance(
                data.depositZapUbiquityDollar,
                tokenAmounts[0]
            );
        }
        // DAI
        if (tokenAmounts[1] > 0) {
            IERC20(data.token0).safeTransferFrom(
                msg.sender,
                address(this),
                tokenAmounts[1]
            );
            IERC20(data.token0).safeIncreaseAllowance(
                data.depositZapUbiquityDollar,
                tokenAmounts[1]
            );
        }
        // USDC
        //Note, due to USDT implementat1ion, normal transferFrom does not work and have an error of "function returned an unexpected amount of data"
        //require(IERC20(token).transferFrom(msg.sender, address(this), amount), "sender cannot transfer specified fund");
        if (tokenAmounts[2] > 0) {
            IERC20(data.token1).safeTransferFrom(
                msg.sender,
                address(this),
                tokenAmounts[2]
            );
            IERC20(data.token1).safeIncreaseAllowance(
                data.depositZapUbiquityDollar,
                tokenAmounts[2]
            );
        }
        // USDT
        if (tokenAmounts[3] > 0) {
            IERC20(data.token2).safeTransferFrom(
                msg.sender,
                address(this),
                tokenAmounts[3]
            );
            IERC20(data.token2).safeIncreaseAllowance(
                data.depositZapUbiquityDollar,
                tokenAmounts[3]
            );
        }
        address staking = data.manager.stakingContractAddress();
        address stakingShare = data.manager.stakingShareAddress();

        // STEP1: add DAI, USDC, USDT or Ubiquity Dollar into metapool liquidity and get UAD3CRVf
        // UAD3CRVf
        uint256 lpAmount = IDepositZap(data.depositZapUbiquityDollar)
            .add_liquidity(data.ubiquity3PoolLP, tokenAmounts, 0);

        //STEP2: stake UAD3CRVf to Staking
        //TODO approve token to be transferred to Staking contract

        IERC20(data.ubiquity3PoolLP).safeIncreaseAllowance(staking, lpAmount);
        stakingShareId = IStaking(staking).deposit(lpAmount, durationWeeks);

        IStakingShare(stakingShare).safeTransferFrom(
            address(this),
            msg.sender,
            stakingShareId,
            1,
            bytes("")
        );

        emit DepositMulti(
            msg.sender,
            tokenAmounts,
            durationWeeks,
            stakingShareId
        );
    }

    /**
     * @notice Withdraws from Ubiquity protocol
     * @notice Ubiquity StakingShare => uAD3CRV-f  => stable coin (DAI / USDC / USDT / Ubiquity Dollar)
     * @notice STEP 1 : Ubiquity StakingShare  => uAD3CRV-f
     * @notice STEP 2 : uAD3CRV-f => stable coin (DAI / USDC / USDT / Ubiquity Dollar)
     * @param stakingShareId Staking Share Id to withdraw
     * @return tokenAmounts Array of token amounts [Ubiquity Dollar, DAI, USDC, USDT]
     */
    function withdrawWithId(
        uint256 stakingShareId
    ) internal returns (uint256[4] memory tokenAmounts) {
        DirectGovernanceData storage data = directGovernanceStorage();
        address staking = data.manager.stakingContractAddress();
        address stakingShare = data.manager.stakingShareAddress();

        uint256[] memory stakingShareIds = IStakingShare(stakingShare)
            .holderTokens(msg.sender);
        // Need to verify msg.sender by holderToken history.
        // stake.minter is this contract address so that cannot use it for verification.
        require(isIdIncluded(stakingShareIds, stakingShareId), "!bond owner");

        //transfer stakingShare NFT token from msg.sender to this address
        IStakingShare(stakingShare).safeTransferFrom(
            msg.sender,
            address(this),
            stakingShareId,
            1,
            "0x"
        );

        // Get Stake
        IStakingShare.Stake memory stake = IStakingShare(stakingShare).getStake(
            stakingShareId
        );

        // STEP 1: Withdraw Ubiquity Staking Shares to get back uAD3CRV-f LPs
        // address staking = ubiquityManager.stakingContractAddress();
        IStakingShare(stakingShare).setApprovalForAll(staking, true);
        IStaking(staking).removeLiquidity(stake.lpAmount, stakingShareId);
        IStakingShare(stakingShare).setApprovalForAll(staking, false);

        uint256 lpTokenAmount = IERC20(data.ubiquity3PoolLP).balanceOf(
            address(this)
        );
        uint256 governanceTokenAmount = IERC20(
            data.manager.governanceTokenAddress()
        ).balanceOf(address(this));

        // STEP2: Withdraw  3Crv LPs from meta pool to get back Ubiquity Dollar, DAI, USDC or USDT

        IERC20(data.ubiquity3PoolLP).approve(
            data.depositZapUbiquityDollar,
            lpTokenAmount
        );
        tokenAmounts = IDepositZap(data.depositZapUbiquityDollar)
            .remove_liquidity(
                data.ubiquity3PoolLP,
                lpTokenAmount,
                [uint256(0), uint256(0), uint256(0), uint256(0)]
            ); //[Ubiquity Dollar, DAI, USDC, USDT]

        IERC20(data.ubiquityDollar).safeTransfer(msg.sender, tokenAmounts[0]);
        IERC20(data.token0).safeTransfer(msg.sender, tokenAmounts[1]);
        IERC20(data.token1).safeTransfer(msg.sender, tokenAmounts[2]);
        IERC20(data.token2).safeTransfer(msg.sender, tokenAmounts[3]);
        IERC20(data.manager.governanceTokenAddress()).safeTransfer(
            msg.sender,
            governanceTokenAmount
        );

        emit WithdrawAll(msg.sender, stakingShareId, tokenAmounts);
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
    ) internal returns (uint256 tokenAmount) {
        DirectGovernanceData storage data = directGovernanceStorage();
        // DAI / USDC / USDT / Ubiquity Dollar
        require(
            isMetaPoolCoin(token),
            "Invalid token: must be DAI, USD Coin, Tether, or Ubiquity Dollar"
        );
        address staking = data.manager.stakingContractAddress();
        address stakingShare = data.manager.stakingShareAddress();

        uint256[] memory stakingShareIds = IStakingShare(stakingShare)
            .holderTokens(msg.sender);
        //Need to verify msg.sender by holderToken history.
        //stake.minter is this contract address so that cannot use it for verification.
        require(
            isIdIncluded(stakingShareIds, stakingShareId),
            "sender is not true bond owner"
        );

        //transfer stakingShare NFT token from msg.sender to this address
        IStakingShare(stakingShare).safeTransferFrom(
            msg.sender,
            address(this),
            stakingShareId,
            1,
            "0x"
        );

        // Get Stake
        IStakingShare.Stake memory stake = IStakingShare(stakingShare).getStake(
            stakingShareId
        );

        // STEP 1 : Withdraw Ubiquity Staking Shares to get back uAD3CRV-f LPs
        //address staking = ubiquityManager.stakingContractAddress();
        IStakingShare(stakingShare).setApprovalForAll(staking, true);
        IStaking(staking).removeLiquidity(stake.lpAmount, stakingShareId);
        IStakingShare(stakingShare).setApprovalForAll(staking, false);

        uint256 lpTokenAmount = IERC20(data.ubiquity3PoolLP).balanceOf(
            address(this)
        );
        uint256 governanceTokenAmount = IERC20(
            data.manager.governanceTokenAddress()
        ).balanceOf(address(this));

        // STEP2: Withdraw  3Crv LPs from meta pool to get back Ubiquity Dollar, DAI, USDC or USDT
        uint128 tokenIndex = token == address(data.ubiquityDollar)
            ? 0
            : (token == data.token0 ? 1 : (token == data.token1 ? 2 : 3));
        require(
            IERC20(data.ubiquity3PoolLP).approve(
                data.depositZapUbiquityDollar,
                lpTokenAmount
            )
        );
        tokenAmount = IDepositZap(data.depositZapUbiquityDollar)
            .remove_liquidity_one_coin(
                data.ubiquity3PoolLP,
                lpTokenAmount,
                int128(tokenIndex),
                0
            ); //[UAD, DAI, USDC, USDT]

        IERC20(token).safeTransfer(msg.sender, tokenAmount);
        IERC20(data.manager.governanceTokenAddress()).safeTransfer(
            msg.sender,
            governanceTokenAmount
        );

        emit Withdraw(msg.sender, stakingShareId, token, tokenAmount);
    }

    ///////////////////////////////////////////// HELPERS /////////////////////////////////////////////

    /**
     * @notice Checks whether `id` exists in `idList[]`
     * @param idList Array to search in
     * @param id Value to search in `idList`
     * @return Whether `id` exists in `idList[]`
     */
    function isIdIncluded(
        uint256[] memory idList,
        uint256 id
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < idList.length; i++) {
            if (idList[i] == id) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Checks that `token` is one of the underlying MetaPool tokens or stablecoin from MetaPool
     * @param token Token address to check
     * @return Whether `token` is one of the underlying MetaPool tokens or stablecoin from MetaPool
     */
    function isMetaPoolCoin(address token) internal pure returns (bool) {
        DirectGovernanceData memory data = directGovernanceStorage();
        return (token == data.token2 ||
            token == data.token1 ||
            token == data.token0 ||
            token == address(data.ubiquityDollar));
    }
}
