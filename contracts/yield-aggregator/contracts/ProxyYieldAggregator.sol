// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;
import "./utils/CollectableDust.sol";
import "openzeppelin-contracts/contracts/security/Pausable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IUbiquityAlgorithmicDollarManager.sol";
import "./interfaces/IERC20Ubiquity.sol";
import "forge-std/Test.sol";

contract ProxyYieldAggregator is Pausable, ERC4626 {
    // @dev event emitted when redeem split is called
    // @param redeemed amount of strategy token redeemed
    // @param premium amount of uCR minted equal to the amount of strategy asset we can redeem with split's strategy share
    // @param shares proxy shares burnt
    // @param split proxy assets aka strategy shares send to the treasury
    event RedeemSplit(
        uint256 indexed redeemed,
        uint256 indexed premium,
        uint256 indexed shares,
        uint256 split
    );
    event vaultShareAdded(
        address indexed caller,
        address indexed receiver,
        uint256 indexed strategyAssets,
        uint256 totalStrategyAssets
    );

    IUbiquityAlgorithmicDollarManager private _manager;

    IERC4626 private _strategy;
    uint16 private _premium; // e.g 4200 = 42%
    uint16 private _minSplit; // e.g 500 = 5%
    uint16 private constant PRECISION = 10_000;

    // access control is handled at the UBQManager level
    modifier onlyIncentiveManager() {
        require(
            _manager.hasRole(_manager.INCENTIVE_MANAGER_ROLE(), msg.sender),
            "PYield::!incentive Mgr"
        );
        _;
    }

    /// @notice proxy yield constructor that will invest in a strategy and used the strategy shares as underlying asset
    /// @param strategy_ address of ubiquity Dollar manager
    /// @param manager_ address of ubiquity Dollar manager
    /// @param minSplit_ proportion of rewards to be withdrawn in uAR
    /// @param premium_ premium for the uAR rewards
    /// @dev a premium can be 0 up to PRECISION i.e a premium of 500 would mean a 5% increased reward on the uAR split
    constructor(
        IERC4626 strategy_,
        address manager_,
        uint16 minSplit_,
        uint16 premium_
    )
        ERC4626(IERC20Metadata(strategy_))
        ERC20("proxy yield token", "pYLD")
        Pausable()
    {
        // all contracts are registered in the UBQManager
        _manager = IUbiquityAlgorithmicDollarManager(manager_);
        _strategy = strategy_;
        _premium = premium_;
        _minSplit = minSplit_;
    }

    /// @notice set the premium for uAR split
    /// @param premium_ new premium for uAR split
    /// @dev a premium can be 0 up to PRECISION i.e a premium of 500 would mean a 5% split
    function setPremium(uint16 premium_) external onlyIncentiveManager {
        require(
            _premium != premium_ && premium_ < PRECISION,
            "PYield::outOfRange"
        );
        _premium = premium_;
    }

    /// @notice get the premium
    function getPremium() external view returns (uint256) {
        return _premium;
    }

    /// @notice set the minimum split percentage for uAR split
    /// @param _split new premium for uAR split
    /// @dev a _split can be from minSplit up to PRECISION i.e a premium of 500 would mean a 5% split
    function setMinSplit(uint16 _split) external onlyIncentiveManager {
        require(
            _split != _minSplit && _split < PRECISION,
            "PYield::outOfRange"
        );
        _minSplit = _split;
    }

    /// @notice get the minimum split
    function getMinSplit() external view returns (uint256) {
        return _minSplit;
    }

    function manageVault(ERC4626 strategy_) external onlyIncentiveManager {
        // we need to check that the yield token total supply is zero
        // otherwise user could deposit on a vault and redeem the same share amount on another vault !
        require(totalSupply() == 0, "PYield::supply>0");
        _strategy = strategy_;
    }

    function pause() external virtual onlyIncentiveManager {
        _pause();
    }

    function unpause() external virtual onlyIncentiveManager {
        _unpause();
    }

    function totalAssets() public view virtual override returns (uint256) {
        // total assets represents what has been deposited in the vault
        // Very important as it used in all share to asset calculations
        // each time we deposit in the strategy we get strategy token
        return IERC20(_strategy).balanceOf(address(this));
    }

    /** @dev See {IERC4626-maxDeposit}. */
    function maxDeposit(address) public view override returns (uint256) {
        // limited by the underlying strategy
        return _strategy.maxDeposit(address(this));
    }

    /**
     * @dev Deposit into the proxy with the strategy asset i.e DAI/USDC and return proxy shares
     */
    function depositWithStrategyAsset(address receiver, uint256 assets)
        external
        returns (uint256)
    {
        require(assets > 0, "PYield::asset==0");
        IERC20 strategyAsset = IERC20(address(_strategy.asset()));
        // transfer the strategy asset to the proxy

        SafeERC20.safeTransferFrom(
            strategyAsset,
            _msgSender(),
            address(this),
            assets
        );
        // calculate the amount of strategy shares we can get for 'assets' startegy asset
        uint256 stratShares = _strategy.previewDeposit(assets);

        // deposit the asset to the strategy and get the strategy token our underlying asset
        strategyAsset.approve(address(_strategy), assets);
        uint256 stratAssets = _strategy.mint(stratShares, address(this));

        // register the new strategy shares inside the proxy
        require(stratAssets <= maxDeposit(receiver), "PYield::deposit>max");

        uint256 shares = previewDeposit(stratAssets);
        //_deposit(receiver, receiver, assets, shares);
        _mint(receiver, shares);

        emit Deposit(_msgSender(), receiver, stratAssets, shares);

        return shares;
    }

    /**
     * @dev Redeem proxy shares for underlying strategy asset i.e provide pDAI and return DAI
     */
    function reedemStrategyAsset(
        uint256 shares,
        address receiver,
        address owner,
        uint16 split
    ) external returns (uint256) {
        require(split >= _minSplit, "PYield::split<min");
        require(split <= PRECISION, "PYield::split>max");
        require(shares <= maxRedeem(owner), "PYield::redeem>max");

        uint256 assets = previewRedeem(shares);
        uint256 remainingStratShares = _withdrawWithSplit(
            _msgSender(),
            receiver,
            owner,
            assets,
            shares,
            split
        );
        _strategy.redeem(remainingStratShares, receiver, address(this));
        return assets;
    }

    /**
     * @dev Withdraw proxy asset for underlying strategy asset i.e provide sDAI amount and return DAI
     */
    function withdrawStrategyAsset(
        uint256 assets,
        address receiver,
        address owner,
        uint16 split
    ) external returns (uint256) {
        require(split >= _minSplit, "PYield::split<min");
        require(split <= PRECISION, "PYield::split>max");
        require(assets <= maxWithdraw(owner), "PYield::withdraw>max");
        uint256 shares = previewWithdraw(assets);

        uint256 remainingStratShares = _withdrawWithSplit(
            _msgSender(),
            receiver,
            owner,
            assets,
            shares,
            split
        );
        _strategy.redeem(remainingStratShares, receiver, address(this));
        return shares;
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override returns (uint256) {
        return redeemWithSplit(shares, receiver, owner, _minSplit);
    }

    function redeemWithSplit(
        uint256 shares,
        address receiver,
        address owner,
        uint16 split
    ) public returns (uint256) {
        require(split >= _minSplit, "PYield::split<min");
        require(split <= PRECISION, "PYield::split>max");
        require(shares <= maxRedeem(owner), "PYield::redeem>max");

        uint256 assets = previewRedeem(shares);
        uint256 remainingStratShares = _withdrawWithSplit(
            _msgSender(),
            receiver,
            owner,
            assets,
            shares,
            split
        );
        IERC20 strategyToken = IERC20(address(_strategy));
        SafeERC20.safeTransfer(strategyToken, receiver, remainingStratShares);
        return assets;
    }

    /**
     * @dev Withdraw/redeem common workflow.
     * @return remaining strategy shares to be sent to receiver
     */
    function _withdrawWithSplit(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares,
        uint16 split
    ) internal whenNotPaused returns (uint256) {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transfered, which is a valid state.

        // proxy shares (i.e pDAI) correspond to an amount of proxy asset (i.e sDAI)
        // which are actually strategy shares that correspond to an amount of stratgey asset (i.e DAI)
        _burn(owner, shares);
        /*   uint stratAssetAmount = strategyToken.balanceOf(address(this)); */

        uint256 splitStratShares = (split * assets) / PRECISION;
        uint256 remainingStratShares = assets - splitStratShares;

        IERC20 strategyToken = IERC20(address(_strategy));
        // send the rewards to the treasury
        SafeERC20.safeTransfer(
            strategyToken,
            _manager.treasuryAddress(),
            splitStratShares
        );
        // get the underlying asset amount corresponding to splitStratShares which are strategy shares
        uint256 stratAsset = _strategy.previewRedeem(splitStratShares);
        // as this asset is a stablecoin we can calculate and mint uCR premium
        uint256 splitWithPremium = (_premium * stratAsset) / PRECISION;
        IERC20Ubiquity(_manager.autoRedeemTokenAddress()).mint(
            receiver,
            splitWithPremium
        );

        emit RedeemSplit(
            remainingStratShares,
            splitWithPremium,
            shares,
            splitStratShares
        );
        // added for compatibility purposes
        emit Withdraw(caller, receiver, owner, assets, shares);
        return remainingStratShares;
    }

    /** @dev See {IERC4626-withdraw}. */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override returns (uint256) {
        require(assets <= maxWithdraw(owner), "PYield::withdraw>max");

        uint256 shares = previewWithdraw(assets);
        uint256 remainingStratShares = _withdrawWithSplit(
            _msgSender(),
            receiver,
            owner,
            assets,
            shares,
            _minSplit
        );
        IERC20 strategyToken = IERC20(address(_strategy));
        SafeERC20.safeTransfer(strategyToken, receiver, remainingStratShares);
        return shares;
    }
}
