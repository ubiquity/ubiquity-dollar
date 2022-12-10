// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

/**
 * @title Ubiquity.
 * @dev Ubiquity Dollar.
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IDepositZap.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IStakingShare.sol";
import "./interfaces/IStableSwap3Pool.sol";
import "./interfaces/IUbiquityDollarManager.sol";

contract DirectGovernanceFarmer is ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public token2; //USDT decimal 6
    address public token1; //USDC decimal 6
    address public token0; //DAI
    address public ubiquity3PoolLP;
    address public ubiquityDollar;
    address public depositZapUbiquityDollar;

    IUbiquityDollarManager public manager;

    event Deposit(
        address indexed sender,
        address token,
        uint256 amount,
        uint256 durationWeeks,
        uint256 stakingShareId
    );
    event DepositMultiple(
        address indexed sender,
        uint256[4] amounts,
        uint256 durationWeeks,
        uint256 stakingShareId
    );

    event Withdraw(
        address indexed sender,
        uint256 stakingShareId,
        address token,
        uint256 amount
    );
    event WithdrawAll(
        address indexed sender,
        uint256 stakingShareId,
        uint256[4] amounts
    );

    constructor(
        address _manager,
        address base3Pool,
        address depositZap
    ) {
        manager = IUbiquityDollarManager(_manager); // 0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98
        ubiquity3PoolLP = manager.stableSwapMetaPoolAddress(); // 0x20955CB69Ae1515962177D164dfC9522feef567E
        ubiquityDollar = manager.dollarTokenAddress(); // 0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6
        depositZapUbiquityDollar = depositZap; // 0xA79828DF1850E8a3A3064576f380D90aECDD3359;
        //Ideally, DepositZap contract in CurveFi should have interface to fetch 3 base token, but they do not.
        //Hence fetching 3 token from 3basePool contract, which is 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7
        token0 = IStableSwap3Pool(base3Pool).coins(0); //DAI: 0x6B175474E89094C44Da98b954EedeAC495271d0F
        token1 = IStableSwap3Pool(base3Pool).coins(1); //USDC: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
        token2 = IStableSwap3Pool(base3Pool).coins(2); //USDT: 0xdAC17F958D2ee523a2206206994597C13D831ec7
    }

    //TODO create updateConfig method

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) public virtual returns (bytes4) {
        // Called when receiving ERC1155 token at staking.
        // operator: Staking contract
        // from: address(0x)
        // id: staking share ID
        // value: 1
        // data: 0x
        // msg.sender: Staking contract
        return this.onERC1155Received.selector;
    }

    /**
     * @dev Deposit into Ubiquity protocol
     * @notice Stable coin (DAI / USDC / USDT / Ubiquity Dollar) => uAD3CRV-f => Ubiquity StakingShare
     * @notice STEP 1 : Change (DAI / USDC / USDT / Ubiquity dollar) to 3CRV at uAD3CRV MetaPool
     * @notice STEP 2 : uAD3CRV-f => Ubiquity StakingShare
     * @param token Token deposited : DAI, USDC, USDT or Ubiquity Dollar
     * @param amount Amount of tokens to deposit (For max: `uint256(-1)`)
     * @param durationWeeks Duration in weeks tokens will be locked (1-208)
     */
    function deposit(
        address token,
        uint256 amount,
        uint256 durationWeeks
    ) external nonReentrant returns (uint256 stakingShareId) {
        // DAI / USDC / USDT / Ubiquity Dollar
        require(
            isMetaPoolCoin(token),
            "Invalid token: must be DAI, USD Coin, Tether, or Ubiquity Dollar"
        );
        require(amount > 0, "amount must be positive vale");
        require(
            durationWeeks >= 1 && durationWeeks <= 208,
            "duration weeks must be between 1 and 208"
        );

        //Note, due to USDT implementation, normal transferFrom does not work and have an error of "function returned an unexpected amount of data"
        //require(IERC20(token).transferFrom(msg.sender, address(this), amount), "sender cannot transfer specified fund");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        address staking = manager.stakingContractAddress();
        address stakingShare = manager.stakingShareAddress();

        uint256 lpAmount; //UAD3CRVf
        //[Ubiquity Dollar, DAI, USDC, USDT]
        uint256[4] memory tokenAmounts = [
            token == ubiquityDollar ? amount : 0,
            token == token0 ? amount : 0,
            token == token1 ? amount : 0,
            token == token2 ? amount : 0
        ];

        //STEP1: add DAI, USDC, USDT or Ubiquity Dollar into metapool liquidity and get UAD3CRVf
        IERC20(token).safeIncreaseAllowance(depositZapUbiquityDollar, amount);
        lpAmount = IDepositZap(depositZapUbiquityDollar).add_liquidity(
            ubiquity3PoolLP,
            tokenAmounts,
            0
        );

        //STEP2: stake UAD3CRVf to Staking
        //TODO approve token to be transferred to Staking contract
        IERC20(ubiquity3PoolLP).safeIncreaseAllowance(staking, lpAmount);
        stakingShareId = IStaking(staking).deposit(lpAmount, durationWeeks);

        IStakingShare(stakingShare).safeTransferFrom(
            address(this),
            msg.sender,
            stakingShareId,
            1,
            bytes("")
        );
        emit Deposit(msg.sender, token, amount, durationWeeks, stakingShareId);
    }

    /**
     * @dev Deposit into Ubiquity protocol
     * @notice Stable coins (DAI / USDC / USDT / Ubiquity Dollar) => uAD3CRV-f => Ubiquity StakingShare
     * @notice STEP 1 : Change (DAI / USDC / USDT / Ubiquity dollar) to 3CRV at uAD3CRV MetaPool
     * @notice STEP 2 : uAD3CRV-f => Ubiquity StakingShare
     * @param tokenAmounts Amount of tokens to deposit (For max: `uint256(-1)`) it MUST follow this order [Ubiquity Dollar, DAI, USDC, USDT]
     * @param durationWeeks Duration in weeks tokens will be locked (1-208)
     */
    function deposit(uint256[4] calldata tokenAmounts, uint256 durationWeeks)
        external
        nonReentrant
        returns (uint256 stakingShareId)
    {
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
        if (tokenAmounts[0] > 0) {
            IERC20(ubiquityDollar).safeTransferFrom(
                msg.sender,
                address(this),
                tokenAmounts[0]
            );
            IERC20(ubiquityDollar).safeIncreaseAllowance(
                depositZapUbiquityDollar,
                tokenAmounts[0]
            );
        }
        if (tokenAmounts[1] > 0) {
            IERC20(token0).safeTransferFrom(
                msg.sender,
                address(this),
                tokenAmounts[1]
            );
            IERC20(token0).safeIncreaseAllowance(
                depositZapUbiquityDollar,
                tokenAmounts[1]
            );
        }
        //Note, due to USDT implementation, normal transferFrom does not work and have an error of "function returned an unexpected amount of data"
        //require(IERC20(token).transferFrom(msg.sender, address(this), amount), "sender cannot transfer specified fund");
        if (tokenAmounts[2] > 0) {
            IERC20(token1).safeTransferFrom(
                msg.sender,
                address(this),
                tokenAmounts[2]
            );
            IERC20(token1).safeIncreaseAllowance(
                depositZapUbiquityDollar,
                tokenAmounts[2]
            );
        }
        if (tokenAmounts[3] > 0) {
            IERC20(token2).safeTransferFrom(
                msg.sender,
                address(this),
                tokenAmounts[3]
            );
            IERC20(token2).safeIncreaseAllowance(
                depositZapUbiquityDollar,
                tokenAmounts[3]
            );
        }
        address staking = manager.stakingContractAddress();
        address stakingShare = manager.stakingShareAddress();

        uint256 lpAmount; //UAD3CRVf

        //STEP1: add DAI, USDC, USDT or Ubiquity Dollar into metapool liquidity and get UAD3CRVf

        lpAmount = IDepositZap(depositZapUbiquityDollar).add_liquidity(
            ubiquity3PoolLP,
            tokenAmounts,
            0
        );

        //STEP2: stake UAD3CRVf to Staking
        //TODO approve token to be transferred to Staking contract
        IERC20(ubiquity3PoolLP).safeIncreaseAllowance(staking, lpAmount);
        stakingShareId = IStaking(staking).deposit(lpAmount, durationWeeks);

        IStakingShare(stakingShare).safeTransferFrom(
            address(this),
            msg.sender,
            stakingShareId,
            1,
            bytes("")
        );
        emit DepositMultiple(
            msg.sender,
            tokenAmounts,
            durationWeeks,
            stakingShareId
        );
    }

    /**
     * @dev Withdraw from Ubiquity protocol
     * @notice Ubiquity StakingShare => uAD3CRV-f  => stable coin (DAI / USDC / USDT / Ubiquity Dollar)
     * @notice STEP 1 : Ubiquity StakingShare  => uAD3CRV-f
     * @notice STEP 2 : uAD3CRV-f => stable coin (DAI / USDC / USDT / Ubiquity Dollar)
     * @param stakingShareId Staking Share Id to withdraw
     */

    function withdraw(uint256 stakingShareId)
        external
        nonReentrant
        returns (uint256[4] memory tokenAmounts)
    {
        address staking = manager.stakingContractAddress();
        address stakingShare = manager.stakingShareAddress();

        uint256[] memory stakingShareIds = IStakingShare(stakingShare)
            .holderTokens(msg.sender);
        //Need to verify msg.sender by holderToken history.
        //stake.minter is this contract address so that cannot use it for verification.
        require(isIdIncluded(stakingShareIds, stakingShareId), "!bond owner");

        //transfer bondingShare NFT token from msg.sender to this address
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

        uint256 lpTokenAmount = IERC20(ubiquity3PoolLP).balanceOf(
            address(this)
        );
        uint256 governanceTokenAmount = IERC20(manager.governanceTokenAddress())
            .balanceOf(address(this));

        // STEP2 : Withdraw  3Crv LPs from meta pool to get back Ubiquity Dollar, DAI, USDC or USDT

        IERC20(ubiquity3PoolLP).approve(
            depositZapUbiquityDollar,
            lpTokenAmount
        );
        tokenAmounts = IDepositZap(depositZapUbiquityDollar).remove_liquidity(
            ubiquity3PoolLP,
            lpTokenAmount,
            [uint256(0), uint256(0), uint256(0), uint256(0)]
        ); //[Ubiquity Dollar, DAI, USDC, USDT]
        IERC20(ubiquityDollar).safeTransfer(msg.sender, tokenAmounts[0]);
        IERC20(token0).safeTransfer(msg.sender, tokenAmounts[1]);
        IERC20(token1).safeTransfer(msg.sender, tokenAmounts[2]);
        IERC20(token2).safeTransfer(msg.sender, tokenAmounts[3]);
        IERC20(manager.governanceTokenAddress()).safeTransfer(
            msg.sender,
            governanceTokenAmount
        );

        emit WithdrawAll(msg.sender, stakingShareId, tokenAmounts);
    }

    /**
     * @dev Withdraw from Ubiquity protocol
     * @notice Ubiquity StakingShare => uAD3CRV-f  => stable coin (DAI / USDC / USDT / Ubiquity Dollar)
     * @notice STEP 1 : Ubiquity StakingShare  => uAD3CRV-f
     * @notice STEP 2 : uAD3CRV-f => stable coin (DAI / USDC / USDT / Ubiquity Dollar)
     * @param stakingShareId Staking Share Id to withdraw
     * @param token Token to withdraw to : DAI, USDC, USDT, 3CRV or Ubiquity Dollar
     */
    function withdraw(uint256 stakingShareId, address token)
        external
        nonReentrant
        returns (uint256 tokenAmount)
    {
        // DAI / USDC / USDT / Ubiquity Dollar
        require(
            isMetaPoolCoin(token),
            "Invalid token: must be DAI, USD Coin, Tether, or Ubiquity Dollar"
        );
        address staking = manager.stakingContractAddress();
        address stakingShare = manager.stakingShareAddress();

        uint256[] memory stakingShareIds = IStakingShare(stakingShare)
            .holderTokens(msg.sender);
        //Need to verify msg.sender by holderToken history.
        //stake.minter is this contract address so that cannot use it for verification.
        require(
            isIdIncluded(stakingShareIds, stakingShareId),
            "sender is not true bond owner"
        );

        //transfer bondingShare NFT token from msg.sender to this address
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

        uint256 lpTokenAmount = IERC20(ubiquity3PoolLP).balanceOf(
            address(this)
        );
        uint256 governanceTokenAmount = IERC20(manager.governanceTokenAddress())
            .balanceOf(address(this));

        // STEP2 : Withdraw  3Crv LPs from meta pool to get back Ubiquity Dollar, DAI, USDC or USDT
        uint128 tokenIndex = token == ubiquityDollar
            ? 0
            : (token == token0 ? 1 : (token == token1 ? 2 : 3));
        IERC20(ubiquity3PoolLP).approve(
            depositZapUbiquityDollar,
            lpTokenAmount
        );
        tokenAmount = IDepositZap(depositZapUbiquityDollar)
            .remove_liquidity_one_coin(
                ubiquity3PoolLP,
                lpTokenAmount,
                int128(tokenIndex),
                0
            ); //[Ubiquity Dollar, DAI, USDC, USDT]

        IERC20(token).safeTransfer(msg.sender, tokenAmount);
        IERC20(manager.governanceTokenAddress()).safeTransfer(
            msg.sender,
            governanceTokenAmount
        );

        emit Withdraw(msg.sender, stakingShareId, token, tokenAmount);
    }

    function isIdIncluded(uint256[] memory idList, uint256 id)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < idList.length; i++) {
            if (idList[i] == id) {
                return true;
            }
        }
        return false;
    }

    function isMetaPoolCoin(address token) public view returns (bool) {
        return (token == token2 ||
            token == token1 ||
            token == token0 ||
            token == ubiquityDollar);
    }
}
