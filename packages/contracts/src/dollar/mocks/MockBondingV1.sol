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

contract Bonding is CollectableDust {
    using SafeERC20 for IERC20;

    bytes public data = "";
    UbiquityDollarManager public manager;

    uint256 public constant ONE = uint256(1 ether); // 3Crv has 18 decimals
    ISablier public sablier;
    uint256 public bondingDiscountMultiplier = uint256(1000000 gwei); // 0.001
    uint256 public redeemStreamTime = 86400; // 1 day in seconds
    uint256 public blockCountInAWeek = 45361;
    uint256 public blockBonding = 100;
    uint256 public uGOVPerBlock = 1;

    event MaxBondingPriceUpdated(uint256 _maxBondingPrice);
    event SablierUpdated(address _sablier);
    event BondingDiscountMultiplierUpdated(uint256 _bondingDiscountMultiplier);
    event RedeemStreamTimeUpdated(uint256 _redeemStreamTime);
    event BlockBondingUpdated(uint256 _blockBonding);
    event BlockCountInAWeekUpdated(uint256 _blockCountInAWeek);
    event UGOVPerBlockUpdated(uint256 _uGOVPerBlock);

    modifier onlyBondingManager() {
        require(
            manager.hasRole(manager.STAKING_MANAGER_ROLE(), msg.sender),
            "Caller is not a bonding manager"
        );
        _;
    }

    constructor(address _manager, address _sablier) CollectableDust() {
        manager = UbiquityDollarManager(_manager);
        sablier = ISablier(_sablier);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /// @dev uADPriceReset remove uAD unilaterally from the curve LP share sitting inside
    ///      the bonding contract and send the uAD received to the treasury.
    ///      This will have the immediate effect of pushing the uAD price HIGHER
    /// @param amount of LP token to be removed for uAD
    /// @notice it will remove one coin only from the curve LP share sitting in the bonding contract
    function uADPriceReset(uint256 amount) external onlyBondingManager {
        IMetaPool metaPool = IMetaPool(manager.stableSwapMetaPoolAddress());
        // safe approve
        IERC20(manager.stableSwapMetaPoolAddress()).safeApprove(
            address(this), amount
        );
        // remove one coin
        uint256 expected =
            (metaPool.calc_withdraw_one_coin(amount, 0) * 99) / 100;
        // update twap
        metaPool.remove_liquidity_one_coin(amount, 0, expected);
        ITWAPOracleDollar3pool(manager.twapOracleAddress()).update();
        IERC20(manager.dollarTokenAddress()).safeTransfer(
            manager.treasuryAddress(),
            IERC20(manager.dollarTokenAddress()).balanceOf(address(this))
        );
    }

    /// @dev crvPriceReset remove 3CRV unilaterally from the curve LP share sitting inside
    ///      the bonding contract and send the 3CRV received to the treasury
    ///      This will have the immediate effect of pushing the uAD price LOWER
    /// @param amount of LP token to be removed for 3CRV tokens
    /// @notice it will remove one coin only from the curve LP share sitting in the bonding contract
    function crvPriceReset(uint256 amount) external onlyBondingManager {
        IMetaPool metaPool = IMetaPool(manager.stableSwapMetaPoolAddress());
        // safe approve
        IERC20(manager.stableSwapMetaPoolAddress()).safeApprove(
            address(this), amount
        );
        // remove one coin
        uint256 expected =
            (metaPool.calc_withdraw_one_coin(amount, 1) * 99) / 100;
        // update twap
        metaPool.remove_liquidity_one_coin(amount, 1, expected);
        ITWAPOracleDollar3pool(manager.twapOracleAddress()).update();
        IERC20(manager.curve3PoolTokenAddress()).safeTransfer(
            manager.treasuryAddress(),
            IERC20(manager.curve3PoolTokenAddress()).balanceOf(address(this))
        );
    }

    /// Collectable Dust
    function addProtocolToken(address _token)
        external
        override
        onlyBondingManager
    {
        _addProtocolToken(_token);
    }

    function removeProtocolToken(address _token)
        external
        override
        onlyBondingManager
    {
        _removeProtocolToken(_token);
    }

    function sendDust(address _to, address _token, uint256 _amount)
        external
        override
        onlyBondingManager
    {
        _sendDust(_to, _token, _amount);
    }

    function setSablier(address _sablier) external onlyBondingManager {
        sablier = ISablier(_sablier);
        emit SablierUpdated(_sablier);
    }

    function setBondingDiscountMultiplier(uint256 _bondingDiscountMultiplier)
        external
        onlyBondingManager
    {
        bondingDiscountMultiplier = _bondingDiscountMultiplier;
        emit BondingDiscountMultiplierUpdated(_bondingDiscountMultiplier);
    }

    function setRedeemStreamTime(uint256 _redeemStreamTime)
        external
        onlyBondingManager
    {
        redeemStreamTime = _redeemStreamTime;
        emit RedeemStreamTimeUpdated(_redeemStreamTime);
    }

    function setBlockBonding(uint256 _blockBonding)
        external
        onlyBondingManager
    {
        blockBonding = _blockBonding;
        emit BlockBondingUpdated(_blockBonding);
    }

    function setBlockCountInAWeek(uint256 _blockCountInAWeek)
        external
        onlyBondingManager
    {
        blockCountInAWeek = _blockCountInAWeek;
        emit BlockCountInAWeekUpdated(_blockCountInAWeek);
    }

    function setUGOVPerBlock(uint256 _uGOVPerBlock)
        external
        onlyBondingManager
    {
        uGOVPerBlock = _uGOVPerBlock;
        emit UGOVPerBlockUpdated(_uGOVPerBlock);
    }

    /// @dev deposit uAD-3CRV LP tokens for a duration to receive bonding shares
    /// @param _lpsAmount of LP token to send
    /// @param _weeks during lp token will be held
    /// @notice weeks act as a multiplier for the amount of bonding shares to be received
    function deposit(uint256 _lpsAmount, uint256 _weeks)
        public
        returns (uint256 _id)
    {
        require(
            1 <= _weeks && _weeks <= 208,
            "Bonding: duration must be between 1 and 208 weeks"
        );
        _updateOracle();

        IERC20(manager.stableSwapMetaPoolAddress()).safeTransferFrom(
            msg.sender, address(this), _lpsAmount
        );

        uint256 _sharesAmount = IUbiquityFormulas(manager.formulasAddress())
            .durationMultiply(_lpsAmount, _weeks, bondingDiscountMultiplier);

        // 1 week = 45361 blocks = 2371753*7/366
        // n = (block + duration * 45361)
        // id = n - n % blockBonding
        // blockBonding = 100 => 2 ending zeros
        uint256 n = block.number + _weeks * blockCountInAWeek;
        _id = n - (n % blockBonding);
        _mint(_sharesAmount, _id);
        // set masterchef for uGOV rewards
        IUbiquityChef(manager.masterChefAddress()).deposit(
            msg.sender, _sharesAmount, _id
        );
    }

    /// @dev withdraw an amount of uAD-3CRV LP tokens
    /// @param _sharesAmount of bonding shares of type _id to be withdrawn
    /// @param _id bonding shares id
    /// @notice bonding shares are ERC1155 (aka NFT) because they have an expiration date
    function withdraw(uint256 _sharesAmount, uint256 _id) public {
        require(
            block.number > _id,
            "Bonding: Redeem not allowed before bonding time"
        );

        require(
            IERC1155Ubiquity(manager.stakingShareAddress()).balanceOf(
                msg.sender, _id
            ) >= _sharesAmount,
            "Bonding: caller does not have enough shares"
        );

        _updateOracle();
        // get masterchef for uGOV rewards To ensure correct computation
        // it needs to be done BEFORE burning the shares
        IUbiquityChef(manager.masterChefAddress()).withdraw(
            msg.sender, _sharesAmount, _id
        );

        uint256 _currentShareValue = currentShareValue();

        IERC1155Ubiquity(manager.stakingShareAddress()).burn(
            msg.sender, _id, _sharesAmount
        );

        // if (redeemStreamTime == 0) {
        IERC20(manager.stableSwapMetaPoolAddress()).safeTransfer(
            msg.sender,
            IUbiquityFormulas(manager.formulasAddress()).redeemBonds(
                _sharesAmount, _currentShareValue, ONE
            )
        );
    }

    function currentShareValue() public view returns (uint256 priceShare) {
        uint256 totalLP =
            IERC20(manager.stableSwapMetaPoolAddress()).balanceOf(address(this));

        uint256 totalShares =
            IERC1155Ubiquity(manager.stakingShareAddress()).totalSupply();

        priceShare = IUbiquityFormulas(manager.formulasAddress()).bondPrice(
            totalLP, totalShares, ONE
        );
    }

    function currentTokenPrice() public view returns (uint256) {
        return ITWAPOracleDollar3pool(manager.twapOracleAddress()).consult(
            manager.dollarTokenAddress()
        );
    }

    function _mint(uint256 _sharesAmount, uint256 _id) internal {
        uint256 _currentShareValue = currentShareValue();
        require(
            _currentShareValue != 0, "Bonding: share value should not be null"
        );

        IERC1155Ubiquity(manager.stakingShareAddress()).mint(
            msg.sender, _id, _sharesAmount, data
        );
    }

    function _updateOracle() internal {
        ITWAPOracleDollar3pool(manager.twapOracleAddress()).update();
    }
}