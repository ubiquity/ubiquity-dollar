// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../core/UbiquityDollarToken.sol";
import "../core/UbiquityDollarManager.sol";
import "../interfaces/IERC1155Ubiquity.sol";
import "../interfaces/IMetaPool.sol";
import "../interfaces/IUbiquityFormulas.sol";
import "../interfaces/ISablier.sol";
import "../interfaces/IUbiquityChef.sol";
import "../interfaces/ITWAPOracleDollar3pool.sol";
import "../interfaces/IERC1155Ubiquity.sol";
import "../utils/CollectableDust.sol";

contract MockStaking is CollectableDust {
    using SafeERC20 for IERC20;

    bytes public data = "";
    UbiquityDollarManager public manager;

    uint256 public constant ONE = uint256(1 ether); // 3Crv has 18 decimals
    ISablier public sablier;
    uint256 public stakingDiscountMultiplier = uint256(1000000 gwei); // 0.001
    uint256 public redeemStreamTime = 86400; // 1 day in seconds
    uint256 public blockCountInAWeek = 45361;
    uint256 public blockStaking = 100;
    uint256 public rewardsPerBlock = 1;

    event MaxStakingPriceUpdated(uint256 _maxStakingPrice);
    event SablierUpdated(address _sablier);
    event StakingDiscountMultiplierUpdated(uint256 _stakingDiscountMultiplier);
    event RedeemStreamTimeUpdated(uint256 _redeemStreamTime);
    event BlockStakingUpdated(uint256 _blockStaking);
    event BlockCountInAWeekUpdated(uint256 _blockCountInAWeek);
    event RewardsPerBlockUpdated(uint256 _rewardsPerBlock);

    modifier onlyStakingManager() {
        require(
            manager.hasRole(manager.STAKING_MANAGER_ROLE(), msg.sender),
            "Caller is not a staking manager"
        );
        _;
    }

    constructor(address _manager, address _sablier) CollectableDust() {
        manager = UbiquityDollarManager(_manager);
        sablier = ISablier(_sablier);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /// @dev dollarPriceReset remove uAD unilaterally from the curve LP token sitting inside
    ///      the staking contract and send the uAD received to the treasury.
    ///      This will have the immediate effect of pushing the uAD price HIGHER
    /// @param amount of LP token to be removed for uAD
    /// @notice it will remove one coin only from the curve LP token sitting in the staking contract
    function dollarPriceReset(uint256 amount) external onlyStakingManager {
        IMetaPool metaPool = IMetaPool(manager.stableSwapMetaPoolAddress());
        // safe approve
        IERC20(manager.stableSwapMetaPoolAddress()).safeApprove(
            address(this),
            amount
        );
        // remove one coin
        uint256 expected = (metaPool.calc_withdraw_one_coin(amount, 0) * 99) /
            100;
        // update twap
        metaPool.remove_liquidity_one_coin(amount, 0, expected);
        ITWAPOracleDollar3pool(manager.twapOracleAddress()).update();
        IERC20(manager.dollarTokenAddress()).safeTransfer(
            manager.treasuryAddress(),
            IERC20(manager.dollarTokenAddress()).balanceOf(address(this))
        );
    }

    /// @dev crvPriceReset remove 3CRV unilaterally from the curve LP token sitting inside
    ///      the staking contract and send the 3CRV received to the treasury
    ///      This will have the immediate effect of pushing the uAD price LOWER
    /// @param amount of LP token to be removed for 3CRV tokens
    /// @notice it will remove one coin only from the curve LP token sitting in the staking contract
    function crvPriceReset(uint256 amount) external onlyStakingManager {
        IMetaPool metaPool = IMetaPool(manager.stableSwapMetaPoolAddress());
        // safe approve
        IERC20(manager.stableSwapMetaPoolAddress()).safeApprove(
            address(this),
            amount
        );
        // remove one coin
        uint256 expected = (metaPool.calc_withdraw_one_coin(amount, 1) * 99) /
            100;
        // update twap
        metaPool.remove_liquidity_one_coin(amount, 1, expected);
        ITWAPOracleDollar3pool(manager.twapOracleAddress()).update();
        IERC20(manager.curve3PoolTokenAddress()).safeTransfer(
            manager.treasuryAddress(),
            IERC20(manager.curve3PoolTokenAddress()).balanceOf(address(this))
        );
    }

    /// Collectable Dust
    function addProtocolToken(
        address _token
    ) external override onlyStakingManager {
        _addProtocolToken(_token);
    }

    function removeProtocolToken(
        address _token
    ) external override onlyStakingManager {
        _removeProtocolToken(_token);
    }

    function sendDust(
        address _to,
        address _token,
        uint256 _amount
    ) external override onlyStakingManager {
        _sendDust(_to, _token, _amount);
    }

    function setSablier(address _sablier) external onlyStakingManager {
        sablier = ISablier(_sablier);
        emit SablierUpdated(_sablier);
    }

    function setStakingDiscountMultiplier(
        uint256 _stakingDiscountMultiplier
    ) external onlyStakingManager {
        stakingDiscountMultiplier = _stakingDiscountMultiplier;
        emit StakingDiscountMultiplierUpdated(_stakingDiscountMultiplier);
    }

    function setRedeemStreamTime(
        uint256 _redeemStreamTime
    ) external onlyStakingManager {
        redeemStreamTime = _redeemStreamTime;
        emit RedeemStreamTimeUpdated(_redeemStreamTime);
    }

    function setBlockStaking(
        uint256 _blockStaking
    ) external onlyStakingManager {
        blockStaking = _blockStaking;
        emit BlockStakingUpdated(_blockStaking);
    }

    function setBlockCountInAWeek(
        uint256 _blockCountInAWeek
    ) external onlyStakingManager {
        blockCountInAWeek = _blockCountInAWeek;
        emit BlockCountInAWeekUpdated(_blockCountInAWeek);
    }

    function setRewardsPerBlock(
        uint256 _rewardsPerBlock
    ) external onlyStakingManager {
        rewardsPerBlock = _rewardsPerBlock;
        emit RewardsPerBlockUpdated(_rewardsPerBlock);
    }

    /// @dev deposit uAD-3CRV LP tokens for a duration to receive staking tokens
    /// @param _lpsAmount of LP token to send
    /// @param _weeks during lp token will be held
    /// @notice weeks act as a multiplier for the amount of staking tokens to be received
    function deposit(
        uint256 _lpsAmount,
        uint256 _weeks
    ) public returns (uint256 _id) {
        require(
            1 <= _weeks && _weeks <= 208,
            "Staking: duration must be between 1 and 208 weeks"
        );
        _updateOracle();

        IERC20(manager.stableSwapMetaPoolAddress()).safeTransferFrom(
            msg.sender,
            address(this),
            _lpsAmount
        );

        uint256 _tokensAmount = IUbiquityFormulas(manager.formulasAddress())
            .durationMultiply(_lpsAmount, _weeks, stakingDiscountMultiplier);

        // 1 week = 45361 blocks = 2371753*7/366
        // n = (block + duration * 45361)
        // id = n - n % blockStaking
        // blockStaking = 100 => 2 ending zeros
        uint256 n = block.number + _weeks * blockCountInAWeek;
        _id = n - (n % blockStaking);
        _mint(_tokensAmount, _id);
        // set masterchef for rewards rewards
        IUbiquityChef(manager.masterChefAddress()).deposit(
            msg.sender,
            _tokensAmount,
            _id
        );
    }

    /// @dev withdraw an amount of uAD-3CRV LP tokens
    /// @param _tokensAmount of staking tokens of type _id to be withdrawn
    /// @param _id staking tokens id
    /// @notice staking tokens are ERC1155 (aka NFT) because they have an expiration date
    function withdraw(uint256 _tokensAmount, uint256 _id) public {
        require(
            block.number > _id,
            "Staking: Redeem not allowed before staking time"
        );

        require(
            IERC1155Ubiquity(manager.stakingTokenAddress()).balanceOf(
                msg.sender,
                _id
            ) >= _tokensAmount,
            "Staking: caller does not have enough tokens"
        );

        _updateOracle();
        // get masterchef for rewards rewards To ensure correct computation
        // it needs to be done BEFORE burning the tokens
        IUbiquityChef(manager.masterChefAddress()).withdraw(
            msg.sender,
            _tokensAmount,
            _id
        );

        uint256 _currentTokenValue = currentTokenValue();

        IERC1155Ubiquity(manager.stakingTokenAddress()).burn(
            msg.sender,
            _id,
            _tokensAmount
        );

        // if (redeemStreamTime == 0) {
        IERC20(manager.stableSwapMetaPoolAddress()).safeTransfer(
            msg.sender,
            IUbiquityFormulas(manager.formulasAddress()).redeemShares(
                _tokensAmount,
                _currentTokenValue,
                ONE
            )
        );
    }

    function currentTokenValue() public view returns (uint256 priceToken) {
        uint256 totalLP = IERC20(manager.stableSwapMetaPoolAddress()).balanceOf(
            address(this)
        );

        uint256 totalTokens = IERC1155Ubiquity(manager.stakingTokenAddress())
            .totalSupply();

        priceToken = IUbiquityFormulas(manager.formulasAddress()).sharePrice(
            totalLP,
            totalTokens,
            ONE
        );
    }

    function currentTokenPrice() public view returns (uint256) {
        return
            ITWAPOracleDollar3pool(manager.twapOracleAddress()).consult(
                manager.dollarTokenAddress()
            );
    }

    function _mint(uint256 _tokensAmount, uint256 _id) internal {
        uint256 _currentTokenValue = currentTokenValue();
        require(
            _currentTokenValue != 0,
            "Staking: token value should not be null"
        );

        IERC1155Ubiquity(manager.stakingTokenAddress()).mint(
            msg.sender,
            _id,
            _tokensAmount,
            data
        );
    }

    function _updateOracle() internal {
        ITWAPOracleDollar3pool(manager.twapOracleAddress()).update();
    }
}
