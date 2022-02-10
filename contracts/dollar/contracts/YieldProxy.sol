// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;
import "./utils/CollectableDust.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./UbiquityAlgorithmicDollarManager.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IJar.sol";
import "./interfaces/IERC20Ubiquity.sol";

contract YieldProxy is ReentrancyGuard, CollectableDust, Pausable {
    using SafeERC20 for ERC20;
    using SafeERC20 for IERC20Ubiquity;
    struct UserInfo {
        uint256 amount; // token amount deposited by the user with same decimals as underlying token
        uint256 shares; // pickle jar shares
        uint256 uadAmount; // amount of uAD staked
        uint256 ubqAmount; // amount of UBQ staked
        uint256 fee; // deposit fee with same decimals as underlying token
        uint256 ratio; // used to calculate yield
        uint256 bonusYield; // used to calculate bonusYield on yield in uAR
    }

    ERC20 public token;
    IJar public jar;
    uint256 public constant BONUS_YIELD_MAX = 10000; // 1000 = 10% 100 = 1% 10 = 0.1% 1 = 0.01%
    uint256 public bonusYield; //  5000 = 50% 100 = 1% 10 = 0.1% 1 = 0.01%
    uint256 public constant FEES_MAX = 100000; // 1000 = 1% 100 = 0.1% 10 = 0.01% 1 = 0.001%
    uint256 public constant UBQ_RATE_MAX = 10000e18; // 100000e18 Amount of UBQ to be stake to reduce the deposit fees by 100%

    uint256 public fees; // 10000  = 10%, 1000 = 1% 100 = 0.1% 10= 0.01% 1=0.001%
    // 100e18, if the ubqRate is 100 and UBQ_RATE_MAX=10000  then 100/10000  = 0.01
    // 1UBQ gives you 0.01% of fee reduction so 10000 UBQ gives you 100%
    uint256 public ubqRate;

    uint256 public ubqMaxAmount; // UBQ amount to stake to have 100%

    // struct to store deposit details

    mapping(address => UserInfo) private _balances;
    UbiquityAlgorithmicDollarManager public manager;

    event Deposit(
        address indexed _user,
        uint256 _amount,
        uint256 _shares,
        uint256 _fee,
        uint256 _ratio,
        uint256 _uadAmount,
        uint256 _ubqAmount,
        uint256 _bonusYield
    );

    event WithdrawAll(
        address indexed _user,
        uint256 _amount,
        uint256 _shares,
        uint256 _fee,
        uint256 _ratio,
        uint256 _uadAmount,
        uint256 _ubqAmount,
        uint256 _bonusYield,
        uint256 _uARYield
    );

    modifier onlyAdmin() {
        require(
            manager.hasRole(manager.DEFAULT_ADMIN_ROLE(), msg.sender),
            "YieldProxy::!admin"
        );
        _;
    }

    constructor(
        address _manager,
        address _jar,
        uint256 _fees,
        uint256 _ubqRate,
        uint256 _bonusYield
    ) CollectableDust() Pausable() {
        manager = UbiquityAlgorithmicDollarManager(_manager);
        fees = _fees; //  10000  = 10%
        jar = IJar(_jar);
        token = ERC20(jar.token());
        // dont accept weird token
        assert(token.decimals() < 19);
        ubqRate = _ubqRate;
        bonusYield = _bonusYield;
        ubqMaxAmount = (100e18 * UBQ_RATE_MAX) / ubqRate;
    }

    /// @dev deposit tokens needed by the pickle jar to receive an extra yield in form of ubiquity debts
    /// @param _amount of token required by the pickle jar
    /// @param _ubqAmount amount of UBQ token that will be stake to decrease your deposit fee
    /// @param _uadAmount amount of uAD token that will be stake to increase your bonusYield
    /// @notice weeks act as a multiplier for the amount of bonding shares to be received
    function deposit(
        uint256 _amount,
        uint256 _uadAmount,
        uint256 _ubqAmount
    ) external nonReentrant returns (bool) {
        require(_amount > 0, "YieldProxy::amount==0");
        UserInfo storage dep = _balances[msg.sender];
        require(dep.amount == 0, "YieldProxy::DepoExist");
        uint256 curFee = 0;
        // we have to take into account the number of decimals of the udnerlying token
        uint256 upatedAmount = _amount;
        if (token.decimals() < 18) {
            upatedAmount = _amount * 10**(18 - token.decimals());
        }
        if (
            _ubqAmount < ubqMaxAmount
        ) // calculate fee based on ubqAmount if it is not the max
        {
            // calculate discount
            uint256 discountPercentage = (ubqRate * _ubqAmount) / UBQ_RATE_MAX; // we need to divide by 100e18 to get the percentage
            // calculate regular fee
            curFee = ((_amount * fees) / FEES_MAX);

            // calculate the discount for this fee
            uint256 discount = (curFee * discountPercentage) / 100e18;
            // remaining fee
            curFee = curFee - discount;
        }
        // if we don't provide enough UAD the bonusYield will be lowered
        uint256 calculatedBonusYield = BONUS_YIELD_MAX;

        uint256 maxUadAmount = upatedAmount / 2;
        if (_uadAmount < maxUadAmount) {
            // calculate the percentage of extra yield you are entitled to
            uint256 percentage = ((_uadAmount + maxUadAmount) * 100e18) /
                maxUadAmount; // 133e18
            // increase the bonus yield with that percentage
            calculatedBonusYield = (bonusYield * percentage) / 100e18;
            // should not be possible to have a higher yield than the max yield
            assert(calculatedBonusYield <= BONUS_YIELD_MAX);
        }

        dep.fee = curFee; // with 18 decimals
        dep.amount = _amount;
        dep.ratio = jar.getRatio();
        dep.uadAmount = _uadAmount;
        dep.ubqAmount = _ubqAmount;
        dep.bonusYield = calculatedBonusYield;

        // transfer all the tokens from the user
        token.safeTransferFrom(msg.sender, address(this), _amount);
        // invest in the pickle jar
        uint256 curBalance = jar.balanceOf(address(this));
        // allowing token to be deposited into the jar
        token.safeIncreaseAllowance(address(jar), _amount);
        /*    uint256 allthis = ERC20(jar.token()).allowance(
            address(this),
            address(jar)
        );
        uint256 allsender = ERC20(jar.token()).allowance(
            msg.sender,
            address(jar)
        ); */

        jar.deposit(_amount);
        dep.shares = jar.balanceOf(address(this)) - curBalance;
        /*   allthis = ERC20(manager.dollarTokenAddress()).allowance(
            msg.sender,
            address(this)
        ); */
        if (_uadAmount > 0) {
            ERC20(manager.dollarTokenAddress()).safeTransferFrom(
                msg.sender,
                address(this),
                _uadAmount
            );
        }
        if (_ubqAmount > 0) {
            ERC20(manager.governanceTokenAddress()).safeTransferFrom(
                msg.sender,
                address(this),
                _ubqAmount
            );
        }
        emit Deposit(
            msg.sender,
            dep.amount,
            dep.shares,
            dep.fee,
            dep.ratio,
            dep.uadAmount,
            dep.ubqAmount,
            dep.bonusYield
        );
        return true;
        // emit event
    }

    /*    function depositWithPermit(
        uint256 _amount,
        uint256 _deadline,
        bool _approveMax,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external returns (bool) {
        require(_amount > 0, "YieldProxy::amount==0");
        UserInfo storage dep = _balances[msg.sender];
        if (dep.amount > 0) {
            //calculer le yield et l'ajouter au nouveau fee
        }
        dep.fee = _amount / fees;
        dep.amount = _amount - dep.fee;
        dep.ratio = jar.getRatio();
        uint256 value = _approveMax ? uint256(-1) : _amount;
        token.permit(msg.sender, address(this), value, _deadline, _v, _r, _s);
        token.safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposit(msg.sender, dep.amount, dep.fee, dep.ratio);
        return true;
    } */

    function withdrawAll() external nonReentrant returns (bool) {
        UserInfo storage dep = _balances[msg.sender];
        require(dep.amount > 0, "YieldProxy::amount==0");
        uint256 upatedAmount = dep.amount;
        uint256 upatedFee = dep.fee;
        if (token.decimals() < 18) {
            upatedAmount = dep.amount * 10**(18 - token.decimals());
            upatedFee = dep.fee * 10**(18 - token.decimals());
        }

        // calculate the yield in uAR
        uint256 amountWithYield = (upatedAmount * jar.getRatio()) / dep.ratio;
        // calculate the yield in uAR by multiplying by the calculated bonus yield and adding the fee
        uint256 extraYieldBonus = 0;
        uint256 uARYield = 0;
        // we need to have a positive yield
        if (amountWithYield > upatedAmount) {
            extraYieldBonus = (((amountWithYield - upatedAmount) *
                dep.bonusYield) / BONUS_YIELD_MAX);
            uARYield =
                extraYieldBonus +
                (amountWithYield - upatedAmount) +
                upatedFee;
        }
        delete dep.bonusYield;
        // we only give back the amount deposited minus the deposit fee
        // indeed the deposit fee will be converted to uAR yield
        uint256 amountToTransferBack = dep.amount - dep.fee;
        delete dep.fee;
        delete dep.amount;

        delete dep.ratio;

        // retrieve the amount from the jar
        jar.withdraw(dep.shares);
        delete dep.shares;
        // we send back the deposited UAD
        if (dep.uadAmount > 0) {
            ERC20(manager.dollarTokenAddress()).transfer(
                msg.sender,
                dep.uadAmount
            );
        }
        delete dep.uadAmount;
        // we send back the deposited UBQ
        if (dep.ubqAmount > 0) {
            ERC20(manager.governanceTokenAddress()).transfer(
                msg.sender,
                dep.ubqAmount
            );
        }
        delete dep.ubqAmount;
        // we send back the deposited amount - deposit fee
        token.transfer(msg.sender, amountToTransferBack);

        // send the rest to the treasury
        token.transfer(
            manager.treasuryAddress(),
            token.balanceOf(address(this))
        );

        // we send the yield as UAR
        IERC20Ubiquity autoRedeemToken = IERC20Ubiquity(
            manager.autoRedeemTokenAddress()
        );
        autoRedeemToken.mint(address(this), uARYield);
        autoRedeemToken.transfer(msg.sender, uARYield);

        // emit event
        emit WithdrawAll(
            msg.sender,
            dep.amount,
            dep.shares,
            dep.fee,
            dep.ratio,
            dep.uadAmount,
            dep.ubqAmount,
            dep.bonusYield,
            uARYield
        );
        return true;
    }

    /// Collectable Dust
    function addProtocolToken(address _token) external override onlyAdmin {
        _addProtocolToken(_token);
    }

    function removeProtocolToken(address _token) external override onlyAdmin {
        _removeProtocolToken(_token);
    }

    function sendDust(
        address _to,
        address _token,
        uint256 _amount
    ) external override onlyAdmin {
        _sendDust(_to, _token, _amount);
    }

    function setDepositFees(uint256 _fees) external onlyAdmin {
        require(_fees != fees, "YieldProxy::===fees");
        fees = _fees;
    }

    function setUBQRate(uint256 _ubqRate) external onlyAdmin {
        require(_ubqRate != ubqRate, "YieldProxy::===ubqRate");
        require(_ubqRate <= UBQ_RATE_MAX, "YieldProxy::>ubqRateMAX");
        ubqRate = _ubqRate;
        ubqMaxAmount = 100 * (UBQ_RATE_MAX / ubqRate) * 1e18; // equivalent to 100 / (ubqRate/ UBQ_RATE_MAX)
    }

    /*     function setMaxUAD(uint256 _maxUADPercent) external onlyAdmin {
        require(_maxUADPercent != UADPercent, "YieldProxy::===maxUAD");
        require(_maxUADPercent <= UADPercentMax, "YieldProxy::>UADPercentMax");
        UADPercent = _maxUADPercent;
    } */

    function setJar(address _jar) external onlyAdmin {
        require(_jar != address(0), "YieldProxy::!Jar");
        jar = IJar(_jar);
        token = ERC20(jar.token());
    }

    function getInfo(address _address)
        external
        view
        returns (uint256[7] memory)
    {
        UserInfo memory dep = _balances[_address];
        return [
            dep.amount,
            dep.shares,
            dep.uadAmount,
            dep.ubqAmount,
            dep.fee,
            dep.ratio,
            dep.bonusYield
        ];
    }
}
