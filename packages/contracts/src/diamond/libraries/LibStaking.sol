// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./LibTWAPOracle.sol";
import "../../dollar/StakingShare.sol";
import "./LibUbiquityChef.sol";
import "./LibStakingFormulas.sol";
import "./LibUbiquityDollar.sol";

library LibStaking {
    using SafeERC20 for IERC20;

    bytes32 constant STAKING_CONTROL_STORAGE_SLOT =
        keccak256("ubiquity.contracts.staking.storage");

    event PriceReset(
        address _tokenWithdrawn,
        uint256 _amountWithdrawn,
        uint256 _amountTransferred
    );

    event Deposit(
        address indexed _user,
        uint256 indexed _id,
        uint256 _lpAmount,
        uint256 _stakingShareAmount,
        uint256 _weeks,
        uint256 _endBlock
    );
    event RemoveLiquidityFromStake(
        address indexed _user,
        uint256 indexed _id,
        uint256 _lpAmount,
        uint256 _lpAmountTransferred,
        uint256 _lpRewards,
        uint256 _stakingShareAmount
    );

    event AddLiquidityFromStake(
        address indexed _user,
        uint256 indexed _id,
        uint256 _lpAmount,
        uint256 _stakingShareAmount
    );

    event StakingDiscountMultiplierUpdated(uint256 _stakingDiscountMultiplier);
    event BlockCountInAWeekUpdated(uint256 _blockCountInAWeek);

    struct StakingData {
        uint256 stakingDiscountMultiplier;
        uint256 blockCountInAWeek;
        uint256 accLpRewardPerShare;
        uint256 lpRewards;
        uint256 totalLpToMigrate;
    }

    function stakingStorage() internal pure returns (StakingData storage l) {
        bytes32 slot = STAKING_CONTROL_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /// @dev dollarPriceReset remove Ubiquity Dollar unilaterally from the curve LP share sitting inside
    ///      the staking contract and send the Ubiquity Dollar received to the treasury.
    ///      This will have the immediate effect of pushing the Ubiquity Dollar price HIGHER
    /// @param amount of LP token to be removed for Ubiquity Dollar
    /// @notice it will remove one coin only from the curve LP share sitting in the staking contract
    function dollarPriceReset(uint256 amount) internal {
        IMetaPool metaPool = IMetaPool(LibTWAPOracle.twapOracleStorage().pool);
        // remove one coin
        uint256 coinWithdrawn = metaPool.remove_liquidity_one_coin(
            amount,
            0,
            0
        );
        LibTWAPOracle.update();
        uint256 toTransfer = LibUbiquityDollar.ubiquityDollarStorage().balances[
            address(this)
        ];
        LibUbiquityDollar.transfer(
            msg.sender,
            LibAppStorage.appStorage().treasuryAddress,
            toTransfer
        );
        emit PriceReset(address(this), coinWithdrawn, toTransfer);
    }

    /// @dev crvPriceReset remove 3CRV unilaterally from the curve LP share sitting inside
    ///      the staking contract and send the 3CRV received to the treasury
    ///      This will have the immediate effect of pushing the Ubiquity Dollar price LOWER
    /// @param amount of LP token to be removed for 3CRV tokens
    /// @notice it will remove one coin only from the curve LP share sitting in the staking contract
    function crvPriceReset(uint256 amount) internal {
        LibTWAPOracle.TWAPOracleStorage memory ts = LibTWAPOracle
            .twapOracleStorage();
        IMetaPool metaPool = IMetaPool(ts.pool);
        // remove one coin
        uint256 coinWithdrawn = metaPool.remove_liquidity_one_coin(
            amount,
            1,
            0
        );
        // update twap
        LibTWAPOracle.update();
        uint256 toTransfer = IERC20(ts.token1).balanceOf(address(this));

        IERC20(ts.token1).transfer(
            LibAppStorage.appStorage().treasuryAddress,
            toTransfer
        );
        emit PriceReset(ts.token1, coinWithdrawn, toTransfer);
    }

    function setStakingDiscountMultiplier(uint256 _stakingDiscountMultiplier)
        internal
    {
        stakingStorage().stakingDiscountMultiplier = _stakingDiscountMultiplier;
        emit StakingDiscountMultiplierUpdated(_stakingDiscountMultiplier);
    }

    function setBlockCountInAWeek(uint256 _blockCountInAWeek) internal {
        stakingStorage().blockCountInAWeek = _blockCountInAWeek;
        emit BlockCountInAWeekUpdated(_blockCountInAWeek);
    }

    /// @dev deposit UbiquityDollar-3CRV LP tokens for a duration to receive staking shares
    /// @param _lpsAmount of LP token to send
    /// @param _weeks during lp token will be held
    /// @notice weeks act as a multiplier for the amount of staking shares to be received
    function deposit(uint256 _lpsAmount, uint256 _weeks)
        internal
        returns (uint256 _id)
    {
        require(
            1 <= _weeks && _weeks <= 208,
            "Staking: duration must be between 1 and 208 weeks"
        );
        LibTWAPOracle.update();

        // update the accumulated lp rewards per shares
        _updateLpPerShare();
        // transfer lp token to the staking contract
        IERC20(LibTWAPOracle.twapOracleStorage().pool).safeTransferFrom(
            msg.sender,
            address(this),
            _lpsAmount
        );
        StakingData storage ss = stakingStorage();
        // calculate the amount of share based on the amount of lp deposited and the duration
        uint256 _sharesAmount = LibStakingFormulas.durationMultiply(
            _lpsAmount,
            _weeks,
            ss.stakingDiscountMultiplier
        );
        // calculate end locking period block number
        uint256 _endBlock = block.number + _weeks * ss.blockCountInAWeek;
        _id = _mint(msg.sender, _lpsAmount, _sharesAmount, _endBlock);

        // set masterchef for Governance rewards
        LibUbiquityChef.deposit(msg.sender, _sharesAmount, _id);

        emit Deposit(
            msg.sender,
            _id,
            _lpsAmount,
            _sharesAmount,
            _weeks,
            _endBlock
        );
    }

    /// @dev Add an amount of UbiquityDollar-3CRV LP tokens
    /// @param _amount of LP token to deposit
    /// @param _id staking shares id
    /// @param _weeks during lp token will be held
    /// @notice staking shares are ERC1155 (aka NFT) because they have an expiration date
    function addLiquidity(
        uint256 _amount,
        uint256 _id,
        uint256 _weeks
    ) internal {
        (
            uint256[2] memory bs,
            StakingShare.Stake memory stake
        ) = _checkForLiquidity(_id);

        // calculate pending LP rewards
        uint256 sharesToRemove = bs[0];
        _updateLpPerShare();
        uint256 pendingLpReward = lpRewardForShares(
            sharesToRemove,
            stake.lpRewardDebt
        );

        // add an extra step to be able to decrease rewards if locking end is near
        pendingLpReward = LibStakingFormulas.lpRewardsAddLiquidityNormalization(
                stake,
                bs,
                pendingLpReward
            );
        // add these LP Rewards to the deposited amount of LP token
        stake.lpAmount += pendingLpReward;
        StakingData storage ss = stakingStorage();
        ss.lpRewards -= pendingLpReward;
        IERC20(LibTWAPOracle.twapOracleStorage().pool).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        stake.lpAmount += _amount;

        // redeem all shares
        LibUbiquityChef.withdraw(msg.sender, sharesToRemove, _id);

        // calculate the amount of share based on the new amount of lp deposited and the duration
        uint256 _sharesAmount = LibStakingFormulas.durationMultiply(
            stake.lpAmount,
            _weeks,
            ss.stakingDiscountMultiplier
        );

        // deposit new shares
        LibUbiquityChef.deposit(msg.sender, _sharesAmount, _id);
        // calculate end locking period block number
        // 1 week = 45361 blocks = 2371753*7/366
        // n = (block + duration * 45361)
        stake.endBlock = block.number + _weeks * ss.blockCountInAWeek;

        // should be done after masterchef withdraw
        _updateLpPerShare();
        stake.lpRewardDebt =
            (LibUbiquityChef.getStakingShareInfo(_id)[0] *
                ss.accLpRewardPerShare) /
            1e12;
        StakingShare(LibAppStorage.appStorage().stakingShareAddress)
            .updateStake(
                _id,
                stake.lpAmount,
                stake.lpRewardDebt,
                stake.endBlock
            );
        emit AddLiquidityFromStake(
            msg.sender,
            _id,
            stake.lpAmount,
            _sharesAmount
        );
    }

    /// @dev Remove an amount of UbiquityDollar-3CRV LP tokens
    /// @param _amount of LP token deposited when _id was created to be withdrawn
    /// @param _id staking shares id
    /// @notice staking shares are ERC1155 (aka NFT) because they have an expiration date
    function removeLiquidity(uint256 _amount, uint256 _id) internal {
        (
            uint256[2] memory bs,
            StakingShare.Stake memory stake
        ) = _checkForLiquidity(_id);
        require(stake.lpAmount >= _amount, "Staking: amount too big");
        // we should decrease the Governance token rewards proportionally to the LP removed
        // sharesToRemove = (staking shares * _amount )  / stake.lpAmount ;
        uint256 sharesToRemove = LibStakingFormulas.sharesForLP(
            stake,
            bs,
            _amount
        );

        //get all its pending LP Rewards
        _updateLpPerShare();
        uint256 pendingLpReward = lpRewardForShares(bs[0], stake.lpRewardDebt);
        // update staking shares
        // stake.shares = stake.shares - sharesToRemove;
        // get masterchef for Governance token rewards To ensure correct computation
        // it needs to be done BEFORE updating the bonding share
        LibUbiquityChef.withdraw(msg.sender, sharesToRemove, _id);

        // redeem of the extra LP
        // staking lp balance - StakingShare.totalLP
        IERC20 metapool = IERC20(LibTWAPOracle.twapOracleStorage().pool);

        // add an extra step to be able to decrease rewards if locking end is near
        pendingLpReward = LibStakingFormulas
            .lpRewardsRemoveLiquidityNormalization(stake, bs, pendingLpReward);
        StakingData storage ss = stakingStorage();
        address stakingShareAddress = LibAppStorage
            .appStorage()
            .stakingShareAddress;
        uint256 correctedAmount = LibStakingFormulas.correctedAmountToWithdraw(
            StakingShare(stakingShareAddress).totalLP(),
            metapool.balanceOf(address(this)) - ss.lpRewards,
            _amount
        );

        ss.lpRewards -= pendingLpReward;
        stake.lpAmount -= _amount;

        // stake.lpRewardDebt = (staking shares * accLpRewardPerShare) /  1e18;
        // user.amount.mul(pool.accSushiPerShare).div(1e12);
        // should be done after masterchef withdraw
        stake.lpRewardDebt =
            (LibUbiquityChef.getStakingShareInfo(_id)[0] *
                ss.accLpRewardPerShare) /
            1e12;

        StakingShare(stakingShareAddress).updateStake(
            _id,
            stake.lpAmount,
            stake.lpRewardDebt,
            stake.endBlock
        );

        // lastly redeem lp tokens
        metapool.safeTransfer(msg.sender, correctedAmount + pendingLpReward);
        emit RemoveLiquidityFromStake(
            msg.sender,
            _id,
            _amount,
            correctedAmount,
            pendingLpReward,
            sharesToRemove
        );
    }

    // View function to see pending lpRewards on frontend.
    function pendingLpRewards(uint256 _id) internal view returns (uint256) {
        StakingData storage ss = stakingStorage();
        address stakingShareAddress = LibAppStorage
            .appStorage()
            .stakingShareAddress;
        StakingShare staking = StakingShare(stakingShareAddress);
        StakingShare.Stake memory stake = staking.getStake(_id);
        uint256[2] memory bs = LibUbiquityChef.getStakingShareInfo(_id);

        uint256 lpBalance = IERC20(LibTWAPOracle.twapOracleStorage().pool)
            .balanceOf(address(this));
        // the excess LP is the current balance minus the total deposited LP
        if (lpBalance >= (staking.totalLP() + ss.totalLpToMigrate)) {
            uint256 currentLpRewards = lpBalance -
                (staking.totalLP() + ss.totalLpToMigrate);
            uint256 curAccLpRewardPerShare = ss.accLpRewardPerShare;
            // if new rewards we should calculate the new curAccLpRewardPerShare
            if (currentLpRewards > ss.lpRewards) {
                uint256 newLpRewards = currentLpRewards - ss.lpRewards;
                curAccLpRewardPerShare =
                    ss.accLpRewardPerShare +
                    ((newLpRewards * 1e12) / LibUbiquityChef.totalShares());
            }
            // we multiply the shares amount by the accumulated lpRewards per share
            // and remove the lp Reward Debt
            return
                (bs[0] * (curAccLpRewardPerShare)) /
                (1e12) -
                (stake.lpRewardDebt);
        }
        return 0;
    }

    /// @dev return the amount of Lp token rewards an amount of shares entitled
    /// @param amount of staking shares
    /// @param lpRewardDebt lp rewards that has already been distributed
    function lpRewardForShares(uint256 amount, uint256 lpRewardDebt)
        internal
        view
        returns (uint256 pendingLpReward)
    {
        StakingData storage ss = stakingStorage();
        if (ss.accLpRewardPerShare > 0) {
            pendingLpReward =
                (amount * ss.accLpRewardPerShare) /
                1e12 -
                (lpRewardDebt);
        }
    }

    function currentShareValue() internal view returns (uint256 priceShare) {
        uint256 totalShares = LibUbiquityChef.totalShares();
        address stakingShareAddress = LibAppStorage
            .appStorage()
            .stakingShareAddress;
        // priceShare = totalLP / totalShares
        priceShare = LibStakingFormulas.bondPrice(
            StakingShare(stakingShareAddress).totalLP(),
            totalShares,
            ONE
        );
    }

    /// @dev update the accumulated excess LP per share
    function _updateLpPerShare() internal {
        address stakingShareAddress = LibAppStorage
            .appStorage()
            .stakingShareAddress;
        StakingData storage ss = stakingStorage();
        StakingShare stake = StakingShare(stakingShareAddress);
        uint256 lpBalance = IERC20(LibTWAPOracle.twapOracleStorage().pool)
            .balanceOf(address(this));
        // the excess LP is the current balance
        // minus the total deposited LP + LP that needs to be migrated
        uint256 totalShares = LibUbiquityChef.totalShares();
        if (
            lpBalance >= (stake.totalLP() + ss.totalLpToMigrate) &&
            totalShares > 0
        ) {
            uint256 currentLpRewards = lpBalance -
                (stake.totalLP() + ss.totalLpToMigrate);

            // is there new LP rewards to be distributed ?
            if (currentLpRewards > ss.lpRewards) {
                // we calculate the new accumulated LP rewards per share
                ss.accLpRewardPerShare =
                    ss.accLpRewardPerShare +
                    (((currentLpRewards - ss.lpRewards) * 1e12) / totalShares);

                // update the bonding contract lpRewards
                ss.lpRewards = currentLpRewards;
            }
        }
    }

    function _mint(
        address to,
        uint256 lpAmount,
        uint256 shares,
        uint256 endBlock
    ) internal returns (uint256) {
        uint256 _currentShareValue = currentShareValue();
        require(
            _currentShareValue != 0,
            "Staking: share value should not be null"
        );
        // set the lp rewards debts so that this staking share only get lp rewards from this day
        uint256 lpRewardDebt = (shares * stakingStorage().accLpRewardPerShare) /
            1e12;
        return
            StakingShare(LibAppStorage.appStorage().stakingShareAddress).mint(
                to,
                lpAmount,
                lpRewardDebt,
                endBlock
            );
    }

    function _checkForLiquidity(uint256 _id)
        internal
        returns (uint256[2] memory bs, StakingShare.Stake memory stake)
    {
        address stakingAddress = LibAppStorage.appStorage().stakingShareAddress;
        require(
            IERC1155Ubiquity(stakingAddress).balanceOf(msg.sender, _id) == 1,
            "Staking: caller is not owner"
        );
        StakingShare staking = StakingShare(stakingAddress);
        stake = staking.getStake(_id);
        require(
            block.number > stake.endBlock,
            "Staking: Redeem not allowed before staking time"
        );

        LibTWAPOracle.update();
        bs = LibUbiquityChef.getStakingShareInfo(_id);
    }
}
