// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IERC1155Ubiquity.sol";
import "./interfaces/IMetaPool.sol";
import "./interfaces/IUbiquityFormulas.sol";
import "./core/UbiquityDollarToken.sol";
import "./StakingFormulas.sol";
import "./StakingShare.sol";
import "./core/UbiquityDollarManager.sol";
import "./interfaces/ISablier.sol";
import "./interfaces/IUbiquityChef.sol";
import "./interfaces/ITWAPOracleDollar3pool.sol";
import "./interfaces/IERC1155Ubiquity.sol";
import "./interfaces/IStaking.sol";
import "./utils/CollectableDust.sol";

contract Staking is IStaking, CollectableDust, Pausable {
    using SafeERC20 for IERC20;

    UbiquityDollarManager public manager;
    uint256 public constant ONE = uint256(1 ether); // 3Crv has 18 decimals
    uint256 public stakingDiscountMultiplier = uint256(1e15); // 0.001
    uint256 public blockCountInAWeek = 45361;
    uint256 public accLpRewardPerShare = 0;

    uint256 public lpRewards;
    uint256 public totalLpToMigrate;
    address public stakingFormulasAddress;

    address public migrator; // temporary address to handle migration
    address[] private _toMigrateOriginals;
    uint256[] private _toMigrateLpBalances;
    uint256[] private _toMigrateLockupPeriods;

    // toMigrateId[address] > 0 when address is to migrate, or 0 in all other cases
    mapping(address => uint256) public toMigrateId;
    bool public migrating = false;

    event PriceReset(
        address tokenWithdrawn,
        uint256 amountWithdrawn,
        uint256 amountTransferred
    );

    event Deposit(
        address indexed user,
        uint256 indexed id,
        uint256 lpAmount,
        uint256 stakingShareAmount,
        uint256 lockupPeriod,
        uint256 endBlock
    );
    event RemoveLiquidityFromStake(
        address indexed user,
        uint256 indexed id,
        uint256 lpAmount,
        uint256 lpAmountTransferred,
        uint256 lpRewards,
        uint256 stakingShareAmount
    );

    event AddLiquidityFromStake(
        address indexed user,
        uint256 indexed id,
        uint256 lpAmount,
        uint256 stakingShareAmount
    );

    event StakingDiscountMultiplierUpdated(uint256 stakingDiscountMultiplier);
    event BlockCountInAWeekUpdated(uint256 blockCountInAWeek);

    event Migrated(
        address indexed user,
        uint256 indexed id,
        uint256 lpsAmount,
        uint256 sharesAmount,
        uint256 lockupPeriod
    );

    modifier onlyStakingManager() {
        require(
            manager.hasRole(manager.STAKING_MANAGER_ROLE(), msg.sender),
            "not manager"
        );
        _;
    }

    modifier onlyPauser() {
        require(
            manager.hasRole(manager.PAUSER_ROLE(), msg.sender), "not pauser"
        );
        _;
    }

    modifier onlyMigrator() {
        require(msg.sender == migrator, "not migrator");
        _;
    }

    modifier whenMigrating() {
        require(migrating, "not in migration");
        _;
    }

    constructor(
        UbiquityDollarManager manager_,
        address stakingFormulasAddress_,
        address[] memory _originals,
        uint256[] memory _lpBalances,
        uint256[] memory _lockupPeriods
    ) CollectableDust() Pausable() {
        manager = manager_;
        stakingFormulasAddress = stakingFormulasAddress_;
        migrator = msg.sender;

        uint256 lgt = _originals.length;
        require(lgt > 0, "address array empty");
        require(lgt == _lpBalances.length, "balances array not same length");
        require(lgt == _lockupPeriods.length, "weeks array not same length");

        _toMigrateOriginals = _originals;
        _toMigrateLpBalances = _lpBalances;
        _toMigrateLockupPeriods = _lockupPeriods;
        uint256 migratingBalances;
        for (uint256 i = 0; i < lgt; ++i) {
            toMigrateId[_originals[i]] = i + 1;
            migratingBalances += _lpBalances[i];
        }
        totalLpToMigrate += migratingBalances;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /// @dev addUserToMigrate add a user to migrate from V1.
    ///      IMPORTANT execute that function BEFORE sending the corresponding LP token
    ///      otherwise they will have extra LP rewards
    /// @param _original address of v1 user
    /// @param _lpBalance LP Balance of v1 user
    /// @param lockupPeriod weeks lockup of v1 user
    /// @notice user will then be able to migrate.
    function addUserToMigrate(
        address _original,
        uint256 _lpBalance,
        uint256 lockupPeriod
    ) external onlyMigrator {
        _toMigrateOriginals.push(_original);
        _toMigrateLpBalances.push(_lpBalance);
        totalLpToMigrate += _lpBalance;
        _toMigrateLockupPeriods.push(lockupPeriod);
        toMigrateId[_original] = _toMigrateOriginals.length;
    }

    function setMigrator(address _migrator) external onlyMigrator {
        migrator = _migrator;
    }

    function setMigrating(bool _migrating) external onlyMigrator {
        migrating = _migrating;
    }

    /// @dev uADPriceReset remove uAD unilaterally from the curve LP share sitting inside
    ///      the staking contract and send the uAD received to the treasury.
    ///      This will have the immediate effect of pushing the uAD price HIGHER
    /// @param amount of LP token to be removed for uAD
    /// @notice it will remove one coin only from the curve LP share sitting in the staking contract
    function dollarPriceReset(uint256 amount) external onlyStakingManager {
        IMetaPool metaPool = IMetaPool(manager.stableSwapMetaPoolAddress());
        // remove one coin
        uint256 coinWithdrawn = metaPool.remove_liquidity_one_coin(amount, 0, 0);
        ITWAPOracleDollar3pool(manager.twapOracleAddress()).update();
        uint256 toTransfer =
            IERC20(manager.dollarTokenAddress()).balanceOf(address(this));
        IERC20(manager.dollarTokenAddress()).safeTransfer(
            manager.treasuryAddress(), toTransfer
        );
        emit PriceReset(manager.dollarTokenAddress(), coinWithdrawn, toTransfer);
    }

    /// @dev crvPriceReset remove 3CRV unilaterally from the curve LP share sitting inside
    ///      the staking contract and send the 3CRV received to the treasury
    ///      This will have the immediate effect of pushing the uAD price LOWER
    /// @param amount of LP token to be removed for 3CRV tokens
    /// @notice it will remove one coin only from the curve LP share sitting in the staking contract
    function crvPriceReset(uint256 amount) external onlyStakingManager {
        IMetaPool metaPool = IMetaPool(manager.stableSwapMetaPoolAddress());
        // remove one coin
        uint256 coinWithdrawn = metaPool.remove_liquidity_one_coin(amount, 1, 0);
        // update twap
        ITWAPOracleDollar3pool(manager.twapOracleAddress()).update();
        uint256 toTransfer =
            IERC20(manager.curve3PoolTokenAddress()).balanceOf(address(this));
        IERC20(manager.curve3PoolTokenAddress()).safeTransfer(
            manager.treasuryAddress(), toTransfer
        );
        emit PriceReset(
            manager.curve3PoolTokenAddress(), coinWithdrawn, toTransfer
            );
    }

    function setStakingFormulasAddress(address stakingFormulasAddress_)
        external
        onlyStakingManager
    {
        stakingFormulasAddress = stakingFormulasAddress_;
    }

    /// Collectable Dust
    function addProtocolToken(address _token)
        external
        override
        onlyStakingManager
    {
        _addProtocolToken(_token);
    }

    function removeProtocolToken(address _token)
        external
        override
        onlyStakingManager
    {
        _removeProtocolToken(_token);
    }

    function sendDust(address _to, address _token, uint256 _amount)
        external
        override
        onlyStakingManager
    {
        _sendDust(_to, _token, _amount);
    }

    function setStakingDiscountMultiplier(uint256 _stakingDiscountMultiplier)
        external
        onlyStakingManager
    {
        stakingDiscountMultiplier = _stakingDiscountMultiplier;
        emit StakingDiscountMultiplierUpdated(_stakingDiscountMultiplier);
    }

    function setBlockCountInAWeek(uint256 _blockCountInAWeek)
        external
        onlyStakingManager
    {
        blockCountInAWeek = _blockCountInAWeek;
        emit BlockCountInAWeekUpdated(_blockCountInAWeek);
    }

    /// @dev deposit uAD-3CRV LP tokens for a duration to receive staking shares
    /// @param _lpsAmount of LP token to send
    /// @param lockupPeriod during lp token will be held
    /// @notice weeks act as a multiplier for the amount of staking shares to be received
    function deposit(uint256 _lpsAmount, uint256 lockupPeriod)
        external
        whenNotPaused
        returns (uint256 _id)
    {
        require(
            1 <= lockupPeriod && lockupPeriod <= 208,
            "Staking: duration must be between 1 and 208 weeks"
        );
        ITWAPOracleDollar3pool(manager.twapOracleAddress()).update();

        // update the accumulated lp rewards per shares
        _updateLpPerShare();
       

        // calculate the amount of share based on the amount of lp deposited and the duration
        uint256 _sharesAmount = IUbiquityFormulas(manager.formulasAddress())
            .durationMultiply(_lpsAmount, lockupPeriod, stakingDiscountMultiplier);
        // calculate end locking period block number
        uint256 _endBlock = block.number + lockupPeriod * blockCountInAWeek;
        _id = _mint(msg.sender, _lpsAmount, _sharesAmount, _endBlock);

        // set ubiquitychef for uGOV rewards
        IUbiquityChef(manager.masterChefAddress()).deposit(
            msg.sender, _sharesAmount, _id
        );

        // transfer lp token to the staking contract
        IERC20(manager.stableSwapMetaPoolAddress()).safeTransferFrom(
            msg.sender, address(this), _lpsAmount
        );

        emit Deposit(
            msg.sender, _id, _lpsAmount, _sharesAmount, lockupPeriod, _endBlock
            );
    }
    

    /// @dev Add an amount of uAD-3CRV LP tokens
    /// @param amount of LP token to deposit
    /// @param id staking shares id
    /// @param lockupPeriod during lp token will be held
    /// @notice staking shares are ERC1155 (aka NFT) because they have an expiration date
    function addLiquidity(uint256 amount, uint256 id, uint256 lockupPeriod)
        external
        whenNotPaused
    {
        (uint256[2] memory stakeInfo, StakingShare.Stake memory stake) =
            _checkForLiquidity(id);

        // calculate pending LP rewards
        uint256 sharesToRemove = stakeInfo[0];
        _updateLpPerShare();
        uint256 pendingLpReward =
            lpRewardForShares(sharesToRemove, stake.lpRewardDebt);
        // Following step would just return the same pendingLpReward as input so commenting out
        /*
        // add an extra step to be able to decrease rewards if locking end is near
        pendingLpReward = StakingFormulas(this.stakingFormulasAddress())
            .lpRewardsAddLiquidityNormalization(share, stakeInfo, pendingLpReward);
        */
        // add these LP Rewards to the deposited amount of LP token
        stake.lpAmount += pendingLpReward;
        lpRewards -= pendingLpReward;
        stake.lpAmount += amount;
        // calculate end locking period block number
        // 1 week = 45361 blocks = 2371753*7/366
        // n = (block + duration * 45361)
        stake.endBlock = block.number + lockupPeriod * blockCountInAWeek;

        // calculate the amount of share based on the new amount of lp deposited and the duration
        uint256 sharesAmount = 
            IUbiquityFormulas(manager.formulasAddress()).durationMultiply(amount, lockupPeriod, stakingDiscountMultiplier);
        
        _updateLpPerShare();
        stake.lpRewardDebt = (
            IUbiquityChef(manager.masterChefAddress()).getStakingShareInfo(id)[0]
                * accLpRewardPerShare) / 1e12;

        StakingShare(manager.stakingShareAddress()).updateStake(
            id, stake.lpAmount, stake.lpRewardDebt, stake.endBlock
        );
        
        IERC20(manager.stableSwapMetaPoolAddress()).safeTransferFrom(
            msg.sender, address(this), amount
        );

        // deposit new shares
        IUbiquityChef(manager.masterChefAddress()).deposit(
            msg.sender, sharesAmount, id
        );

        emit AddLiquidityFromStake(msg.sender, id, stake.lpAmount, sharesAmount);
    }

    /// @dev Remove an amount of uAD-3CRV LP tokens
    /// @param _amount of LP token deposited when _id was created to be withdrawn
    /// @param _id staking shares id
    /// @notice staking shares are ERC1155 (aka NFT) because they have an expiration date
    function removeLiquidity(uint256 _amount, uint256 _id)
        external
        whenNotPaused
    {
        (uint256[2] memory stakeInfo, StakingShare.Stake memory stake) =
            _checkForLiquidity(_id);
        require(stake.lpAmount >= _amount, "Staking: amount too big");
        // we should decrease the UBQ rewards proportionally to the LP removed
        // sharesToRemove = (staking shares * _amount )  / stake.lpAmount ;
        uint256 sharesToRemove = StakingFormulas(this.stakingFormulasAddress())
            .sharesForLP(stake, stakeInfo, _amount);

        //get all its pending LP Rewards
        _updateLpPerShare();
        uint256 pendingLpReward = lpRewardForShares(stakeInfo[0], stake.lpRewardDebt);
        lpRewards -= pendingLpReward;
        // update staking shares
        //stake.shares = stake.shares - sharesToRemove;
        // get ubiquitychef for uGOV rewards To ensure correct computation
        // it needs to be done BEFORE updating the staking share
        IUbiquityChef(manager.masterChefAddress()).withdraw(
            msg.sender, sharesToRemove, _id
        );

        // redeem of the extra LP
        // staking lp balance - StakingShare.totalLP
        IERC20 metapool = IERC20(manager.stableSwapMetaPoolAddress());

        // add an extra step to be able to decrease rewards if locking end is near
        //pendingLpReward = StakingFormulas(this.stakingFormulasAddress())
            //.lpRewardsRemoveLiquidityNormalization(share, stakeInfo, pendingLpReward);

        
        stake.lpAmount -= _amount;

        uint256 correctedAmount = StakingFormulas(this.stakingFormulasAddress())
            .correctedAmountToWithdraw(
            StakingShare(manager.stakingShareAddress()).totalLP(),
            metapool.balanceOf(address(this)) - lpRewards,
            _amount
        );

        

        // stake.lpRewardDebt = (staking shares * accLpRewardPerShare) /  1e18;
        // user.amount.mul(pool.accSushiPerShare).div(1e12);
        // should be done after ubiquitychef withdraw
        stake.lpRewardDebt = (
            IUbiquityChef(manager.masterChefAddress()).getStakingShareInfo(_id)[0]
                * accLpRewardPerShare
        ) / 1e12;

        StakingShare(manager.stakingShareAddress()).updateStake(
            _id, stake.lpAmount, stake.lpRewardDebt, stake.endBlock
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
    function pendingLpRewards(uint256 _id) external view returns (uint256) {
        StakingShare stakingShare = StakingShare(manager.stakingShareAddress());
        StakingShare.Stake memory stake = stakingShare.getStake(_id);
        uint256[2] memory stakeInfo =
            IUbiquityChef(manager.masterChefAddress()).getStakingShareInfo(_id);

        uint256 lpBalance =
            IERC20(manager.stableSwapMetaPoolAddress()).balanceOf(address(this));
        // the excess LP is the current balance minus the total deposited LP
        if (lpBalance >= (stakingShare.totalLP() + totalLpToMigrate)) {
            uint256 currentLpRewards =
                lpBalance - (stakingShare.totalLP() + totalLpToMigrate);
            uint256 curAccLpRewardPerShare = accLpRewardPerShare;
            // if new rewards we should calculate the new curAccLpRewardPerShare
            if (currentLpRewards > lpRewards) {
                uint256 newLpRewards = currentLpRewards - lpRewards;
                curAccLpRewardPerShare = accLpRewardPerShare
                    + (
                        (newLpRewards * 1e12)
                            / IUbiquityChef(manager.masterChefAddress()).totalShares()
                    );
            }
            // we multiply the shares amount by the accumulated lpRewards per share
            // and remove the lp Reward Debt
            return (stakeInfo[0] * (curAccLpRewardPerShare)) / (1e12)
                - (stake.lpRewardDebt);
        }
        return 0;
    }

    function pause() public virtual onlyPauser {
        _pause();
    }

    function unpause() public virtual onlyPauser {
        _unpause();
    }

    /// @dev migrate let a user migrate from V1
    /// @notice user will then be able to migrate
    function migrate() public whenMigrating returns (uint256 _id) {
        _id = toMigrateId[msg.sender];
        require(_id > 0, "not v1 address");

        _migrate(
            _toMigrateOriginals[_id - 1],
            _toMigrateLpBalances[_id - 1],
            _toMigrateLockupPeriods[_id - 1]
        );
    }

    /// @dev return the amount of Lp token rewards an amount of shares entitled
    /// @param amount of staking shares
    /// @param lpRewardDebt lp rewards that has already been distributed
    function lpRewardForShares(uint256 amount, uint256 lpRewardDebt)
        public
        view
        returns (uint256 pendingLpReward)
    {
        if (accLpRewardPerShare > 0) {
            pendingLpReward =
                (amount * accLpRewardPerShare) / 1e12 - (lpRewardDebt);
        }
    }

    function currentShareValue() public view returns (uint256 priceShare) {
        uint256 totalShares =
            IUbiquityChef(manager.masterChefAddress()).totalShares();
        // priceShare = totalLP / totalShares
        priceShare = IUbiquityFormulas(manager.formulasAddress()).sharePrice(
            StakingShare(manager.stakingShareAddress()).totalLP(),
            totalShares,
            ONE
        );
    }

    /// @dev migrate let a user migrate from V1
    /// @notice user will then be able to migrate
    function _migrate(address user, uint256 _lpsAmount, uint256 lockupPeriod)
        internal
        returns (uint256 _id)
    {
        require(toMigrateId[user] > 0, "not v1 address");
        require(_lpsAmount > 0, "LP amount is zero");
        require(
            1 <= lockupPeriod && lockupPeriod <= 208,
            "Duration must be between 1 and 208 weeks"
        );

        // unregister address
        toMigrateId[user] = 0;

        // calculate the amount of share based on the amount of lp deposited and the duration
        uint256 _sharesAmount = IUbiquityFormulas(manager.formulasAddress())
            .durationMultiply(_lpsAmount, lockupPeriod, stakingDiscountMultiplier);

        // update the accumulated lp rewards per shares
        _updateLpPerShare();
        // reduce the total LP to migrate after the minting
        // to keep the _updateLpPerShare calculation consistent
        totalLpToMigrate -= _lpsAmount;
        // calculate end locking period block number
        uint256 endBlock = block.number + lockupPeriod * blockCountInAWeek;
        _id = _mint(user, _lpsAmount, _sharesAmount, endBlock);
        
        // set ubiquitychef for uGOV rewards
        IUbiquityChef(manager.masterChefAddress()).deposit(
            user, _sharesAmount, _id
        );

        emit Migrated(user, _id, _lpsAmount, _sharesAmount, lockupPeriod);
    }

    /// @dev update the accumulated excess LP per share
    function _updateLpPerShare() internal {
        StakingShare stakingShare = StakingShare(manager.stakingShareAddress());
        uint256 lpBalance =
            IERC20(manager.stableSwapMetaPoolAddress()).balanceOf(address(this));
        // the excess LP is the current balance
        // minus the total deposited LP + LP that needs to be migrated
        uint256 totalShares =
            IUbiquityChef(manager.masterChefAddress()).totalShares();
        if (lpBalance >= (stakingShare.totalLP() + totalLpToMigrate) && totalShares > 0)
        {
            uint256 currentLpRewards =
                lpBalance - (stakingShare.totalLP() + totalLpToMigrate);

            // is there new LP rewards to be distributed ?
            if (currentLpRewards > lpRewards) {
                // we calculate the new accumulated LP rewards per share
                accLpRewardPerShare = accLpRewardPerShare
                    + (((currentLpRewards - lpRewards) * 1e12) / totalShares);

                // update the staking contract lpRewards
                lpRewards = currentLpRewards;
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
            _currentShareValue != 0, "Staking: share value should not be null"
        );
        // set the lp rewards debts so that this staking share only get lp rewards from this day
        uint256 lpRewardDebt = (shares * accLpRewardPerShare) / 1e12;
        return StakingShare(manager.stakingShareAddress()).mint(
            to, lpAmount, lpRewardDebt, endBlock
        );
    }

    function _checkForLiquidity(uint256 _id)
        internal view
        returns (uint256[2] memory stakeInfo, StakingShare.Stake memory stake)
    {   
        StakingShare stakingShare = StakingShare(manager.stakingShareAddress());
        require(
            stakingShare.balanceOf(
                msg.sender, _id
            ) == 1,
            "Staking: caller is not owner"
        );
        
        stake = stakingShare.getStake(_id);
        require(
            block.number > stake.endBlock,
            "Staking: Redeem not allowed before staking time"
        );

        stakeInfo = IUbiquityChef(manager.masterChefAddress()).getStakingShareInfo(_id);
    }
}
