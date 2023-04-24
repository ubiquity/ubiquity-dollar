// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

// Modified from FraxPool.sol by Frax Finance
// https://github.com/FraxFinance/frax-solidity/blob/master/src/hardhat/contracts/Frax/Pools/FraxPool.sol

//import {TransferHelper} from "uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {OwnershipFacet} from "./OwnershipFacet.sol";
import {UbiquityGovernanceToken} from "../core/UbiquityGovernanceToken.sol";
import {UbiquityDollarToken} from "../core/UbiquityDollarToken.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {TWAPOracleDollar3poolFacet} from "./TWAPOracleDollar3poolFacet.sol";
//import "../../Governance/AccessControl.sol";
import {LibUbiquityPool} from "../libraries/LibUbiquityPool.sol";
import {IStableSwap3Pool} from "../interfaces/IStableSwap3Pool.sol";
import {IMetaPool} from "../interfaces/IMetaPool.sol";

contract UbiquityPoolFacet {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    ERC20 private collateralToken;
    address private collateralAddress;

    address private ubiquityDollarTokenAddress;
    address private ubquityGovernanceTokenAddress;
    address private timelockAddress;
    UbiquityDollarToken private ubiquityDollarToken;

    TWAPOracleDollar3poolFacet private collatTWAPOracle;
    address public collatTWAPOracleAddress;

    TWAPOracleDollar3poolFacet private dollarTWAPOracle;
    address public dollarTWAPOracleAddress;

    IStableSwap3Pool curve3Pool;
    address private curve3PoolAddress;

    uint256 public mintingFee;
    uint256 public redemptionFee;
    uint256 public buybackFee;
    uint256 public recollatFee;

    mapping (address => uint256) public redeemCollateralBalances;
    uint256 public unclaimedPoolCollateral;
    uint256 public unclaimedPoolUAD;
    mapping (address => uint256) public lastRedeemed;

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    uint256 private constant COLLATERAL_RATIO_PRECISION = 1e6;
    uint256 private constant COLLATERAL_RATIO_MAX = 1e6;
    
    // Pool_ceiling is the total units of collateral that a pool contract can hold
    uint256 public poolCeiling = 0;

    // Stores price of the collateral, if price is paused
    uint256 public pausedPrice = 0;

    // Bonus rate on FXS minted during recollateralizeFRAX(); 6 decimals of precision, set to 0.75% on genesis
    uint256 public bonusRate = 7500;

    // Number of blocks to wait before being able to collectRedemption()
    uint256 public redemptionDelay = 1;

    // AccessControl Roles
    bytes32 private constant MINT_PAUSER = keccak256("MINT_PAUSER");
    bytes32 private constant REDEEM_PAUSER = keccak256("REDEEM_PAUSER");
    bytes32 private constant BUYBACK_PAUSER = keccak256("BUYBACK_PAUSER");
    bytes32 private constant RECOLLATERALIZE_PAUSER = keccak256("RECOLLATERALIZE_PAUSER");
    bytes32 private constant COLLATERAL_PRICE_PAUSER = keccak256("COLLATERAL_PRICE_PAUSER");
    
    // AccessControl state variables
    bool public mintPaused = false;
    bool public redeemPaused = false;
    bool public recollateralizePaused = false;
    bool public buyBackPaused = false;
    bool public collateralPricePaused = false;

    /* ========== MODIFIERS ========== */

    // modifier onlyByOwnGov() {
    //     require(msg.sender == timelock_address || msg.sender == owner, "Not owner or timelock");
    //     _;
    // }

    // modifier notRedeemPaused() {
    //     require(redeemPaused == false, "Redeeming is paused");
    //     _;
    // }

    // modifier notMintPaused() {
    //     require(mintPaused == false, "Minting is paused");
    //     _;
    // }
 
    /* ========== CONSTRUCTOR ========== */
    
    // constructor (
    //     address _ubiquityDollarTokenAddress,
    //     address _ubiquityGovernanceTokenAddress,
    //     address _collateralAddress,
    //     address _creatorAddress,
    //     address _timelockAddress,
    //     uint256 _poolCeiling
    // ) public {
    //     require(
    //         (_ubiquityDollarTokenAddress != address(0))
    //         && (_ubiquityGovernanceTokenAddress != address(0))
    //         && (_collateral_address != address(0))
    //         && (_creator_address != address(0))
    //         && (_timelock_address != address(0))
    //     , "Zero address detected"); 
    //     ubiquityDollarToken = UbiquityDollarToken(_ubquityDollarTokenAddress);
    //     ubiquityGovernanceToken = UbiquityGovernanceToken(_ubiquityGovernanceTokenAddress);
    //     ubquityDollarTokenAddress = _ubquityDollarTokenAddress;
    //     ubquityGovernanceTokenAddress = _ubquityGovernanceTokenAddress;
    //     collateralAddress = _collateralAddress;
    //     timelockAddress = _timelockAddress;
    //     collateralToken = ERC20(_collateralAddress);
    //     poolCeiling = _poolCeiling;
    //     missingDecimals = uint(18).sub(collateralToken.decimals());

    //     _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    //     grantRole(MINT_PAUSER, timelock_address);
    //     grantRole(REDEEM_PAUSER, timelock_address);
    //     grantRole(RECOLLATERALIZE_PAUSER, timelock_address);
    //     grantRole(BUYBACK_PAUSER, timelock_address);
    //     grantRole(COLLATERAL_PRICE_PAUSER, timelock_address);
    // }

    // /* ========== VIEWS ========== */

    // // Returns dollar value of collateral held in this Frax pool
    // function collatDollarBalance() public view returns (uint256) {
    //     if(collateralPricePaused == true){
    //         return (collteralToken.balanceOf(address(this)).sub(unclaimedPoolCollateral)).mul(10 ** missingDecimals).mul(pausedPrice).div(PRICE_PRECISION);
    //     } else {
    //         uint256 curve3PoolPrice = curve3Pool.get_virtual_price();
    //         uint256 curve3PoolCollatPrice = collatTWAPOracle.price0Average();

    //         uint256 collatUSDPrice = curve3PoolPrice.mul(PRICE_PRECISION).div(curve3PoolCollatPrice);
    //         return (collteralToken.balanceOf(address(this)).sub(unclaimedPoolCollateral)).mul(10 ** missingDecimals).mul(collatUSDPrice).div(PRICE_PRECISION); //.mul(getCollateralPrice()).div(1e6);    
    //     }
    // }

    // /* ========== PUBLIC FUNCTIONS ========== */
    
    // // Returns the price of the pool collateral in USD
    // function getCollateralPrice() public view returns (uint256) {
    //     if(collateralPricePaused == true){
    //         return pausedPrice;
    //     } else {
    //         uint256 curve3PoolPrice = curve3Pool.get_virtual_price();
    //         uint256 curve3PoolCollatPrice = collatTwapOracle.price0Average();
    //         return curve3PoolCollatPrice.mul(PRICE_PRECISION).div(curve3PoolCollatPrice);
    //     }
    // }

    // function setCollatETHOracle(address _collatTWAPOracleAddress, address _curve3PoolAddress) external onlyByOwnGov {
    //     collatTwapOracleAddress = _collatTWAPOracleAddress;
    //     collatTwapOracle = TWAPOracleDollar3pool(_collatTWAPOracleAddress);
    //     curve3PoolAddress = _curve3PoolAddress;
    // }

    // // We separate out the 1t1, fractional and algorithmic minting functions for gas efficiency 
    // function mint1t1FRAX(uint256 collateralAmount, uint256 dollarOutMin) external notMintPaused {
    //     uint256 collateralAmountD18 = collateralAmount * (10 ** missingDecimals);

    //     require(FRAX.global_collateral_ratio() >= COLLATERAL_RATIO_MAX, "Collateral ratio must be >= 1");
    //     require((collteralToken.balanceOf(address(this))).sub(unclaimedPoolCollateral).add(collateral_amount) <= pool_ceiling, "[Pool's Closed]: Ceiling reached");
        
    //     (uint256 frax_amount_d18) = FraxPoolLibrary.calcMint1t1FRAX(
    //         getCollateralPrice(),
    //         collateral_amount_d18
    //     ); //1 FRAX for each $1 worth of collateral

    //     frax_amount_d18 = (frax_amount_d18.mul(uint(1e6).sub(minting_fee))).div(1e6); //remove precision at the end
    //     require(FRAX_out_min <= frax_amount_d18, "Slippage limit reached");

    //     TransferHelper.safeTransferFrom(address(collteralToken), msg.sender, address(this), collateral_amount);
    //     FRAX.pool_mint(msg.sender, frax_amount_d18);
    // }

    // // 0% collateral-backed
    // function mintAlgorithmicFRAX(uint256 fxs_amount_d18, uint256 FRAX_out_min) external notMintPaused {
    //     uint256 fxs_price = FRAX.fxs_price();
    //     require(FRAX.global_collateral_ratio() == 0, "Collateral ratio must be 0");
        
    //     (uint256 frax_amount_d18) = FraxPoolLibrary.calcMintAlgorithmicFRAX(
    //         fxs_price, // X FXS / 1 USD
    //         fxs_amount_d18
    //     );

    //     frax_amount_d18 = (frax_amount_d18.mul(uint(1e6).sub(minting_fee))).div(1e6);
    //     require(FRAX_out_min <= frax_amount_d18, "Slippage limit reached");

    //     FXS.pool_burn_from(msg.sender, fxs_amount_d18);
    //     FRAX.pool_mint(msg.sender, frax_amount_d18);
    // }

    // // Will fail if fully collateralized or fully algorithmic
    // // > 0% and < 100% collateral-backed
    // function mintFractionalFRAX(uint256 collateral_amount, uint256 fxs_amount, uint256 FRAX_out_min) external notMintPaused {
    //     uint256 fxs_price = FRAX.fxs_price();
    //     uint256 global_collateral_ratio = FRAX.global_collateral_ratio();

    //     require(global_collateral_ratio < COLLATERAL_RATIO_MAX && global_collateral_ratio > 0, "Collateral ratio needs to be between .000001 and .999999");
    //     require(collteralToken.balanceOf(address(this)).sub(unclaimedPoolCollateral).add(collateral_amount) <= pool_ceiling, "Pool ceiling reached, no more FRAX can be minted with this collateral");

    //     uint256 collateral_amount_d18 = collateral_amount * (10 ** missingDecimals);
    //     FraxPoolLibrary.MintFF_Params memory input_params = FraxPoolLibrary.MintFF_Params(
    //         fxs_price,
    //         getCollateralPrice(),
    //         fxs_amount,
    //         collateral_amount_d18,
    //         global_collateral_ratio
    //     );

    //     (uint256 mint_amount, uint256 fxs_needed) = FraxPoolLibrary.calcMintFractionalFRAX(input_params);

    //     mint_amount = (mint_amount.mul(uint(1e6).sub(minting_fee))).div(1e6);
    //     require(FRAX_out_min <= mint_amount, "Slippage limit reached");
    //     require(fxs_needed <= fxs_amount, "Not enough FXS inputted");

    //     FXS.pool_burn_from(msg.sender, fxs_needed);
    //     TransferHelper.safeTransferFrom(address(collteralToken), msg.sender, address(this), collateral_amount);
    //     FRAX.pool_mint(msg.sender, mint_amount);
    // }

    // // Redeem collateral. 100% collateral-backed
    // function redeem1t1FRAX(uint256 FRAX_amount, uint256 COLLATERAL_out_min) external notRedeemPaused {
    //     require(FRAX.global_collateral_ratio() == COLLATERAL_RATIO_MAX, "Collateral ratio must be == 1");

    //     // Need to adjust for decimals of collateral
    //     uint256 FRAX_amount_precision = FRAX_amount.div(10 ** missingDecimals);
    //     (uint256 collateral_needed) = FraxPoolLibrary.calcRedeem1t1FRAX(
    //         getCollateralPrice(),
    //         FRAX_amount_precision
    //     );

    //     collateral_needed = (collateral_needed.mul(uint(1e6).sub(redemption_fee))).div(1e6);
    //     require(collateral_needed <= collteralToken.balanceOf(address(this)).sub(unclaimedPoolCollateral), "Not enough collateral in pool");
    //     require(COLLATERAL_out_min <= collateral_needed, "Slippage limit reached");

    //     redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender].add(collateral_needed);
    //     unclaimedPoolCollateral = unclaimedPoolCollateral.add(collateral_needed);
    //     lastRedeemed[msg.sender] = block.number;
        
    //     // Move all external functions to the end
    //     FRAX.pool_burn_from(msg.sender, FRAX_amount);
    // }

    // // Will fail if fully collateralized or algorithmic
    // // Redeem FRAX for collateral and FXS. > 0% and < 100% collateral-backed
    // function redeemFractionalFRAX(uint256 FRAX_amount, uint256 FXS_out_min, uint256 COLLATERAL_out_min) external notRedeemPaused {
    //     uint256 fxs_price = FRAX.fxs_price();
    //     uint256 global_collateral_ratio = FRAX.global_collateral_ratio();

    //     require(global_collateral_ratio < COLLATERAL_RATIO_MAX && global_collateral_ratio > 0, "Collateral ratio needs to be between .000001 and .999999");
    //     uint256 col_price_usd = getCollateralPrice();

    //     uint256 FRAX_amount_post_fee = (FRAX_amount.mul(uint(1e6).sub(redemption_fee))).div(PRICE_PRECISION);

    //     uint256 fxs_dollar_value_d18 = FRAX_amount_post_fee.sub(FRAX_amount_post_fee.mul(global_collateral_ratio).div(PRICE_PRECISION));
    //     uint256 fxs_amount = fxs_dollar_value_d18.mul(PRICE_PRECISION).div(fxs_price);

    //     // Need to adjust for decimals of collateral
    //     uint256 FRAX_amount_precision = FRAX_amount_post_fee.div(10 ** missingDecimals);
    //     uint256 collateral_dollar_value = FRAX_amount_precision.mul(global_collateral_ratio).div(PRICE_PRECISION);
    //     uint256 collateral_amount = collateral_dollar_value.mul(PRICE_PRECISION).div(col_price_usd);


    //     require(collateral_amount <= collteralToken.balanceOf(address(this)).sub(unclaimedPoolCollateral), "Not enough collateral in pool");
    //     require(COLLATERAL_out_min <= collateral_amount, "Slippage limit reached [collateral]");
    //     require(FXS_out_min <= fxs_amount, "Slippage limit reached [FXS]");

    //     redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender].add(collateral_amount);
    //     unclaimedPoolCollateral = unclaimedPoolCollateral.add(collateral_amount);

    //     redeemFXSBalances[msg.sender] = redeemFXSBalances[msg.sender].add(fxs_amount);
    //     unclaimedPoolFXS = unclaimedPoolFXS.add(fxs_amount);

    //     lastRedeemed[msg.sender] = block.number;
        
    //     // Move all external functions to the end
    //     FRAX.pool_burn_from(msg.sender, FRAX_amount);
    //     FXS.pool_mint(address(this), fxs_amount);
    // }

    // // Redeem FRAX for FXS. 0% collateral-backed
    // function redeemAlgorithmicFRAX(uint256 FRAX_amount, uint256 FXS_out_min) external notRedeemPaused {
    //     uint256 fxs_price = FRAX.fxs_price();
    //     uint256 global_collateral_ratio = FRAX.global_collateral_ratio();

    //     require(global_collateral_ratio == 0, "Collateral ratio must be 0"); 
    //     uint256 fxs_dollar_value_d18 = FRAX_amount;

    //     fxs_dollar_value_d18 = (fxs_dollar_value_d18.mul(uint(1e6).sub(redemption_fee))).div(PRICE_PRECISION); //apply fees

    //     uint256 fxs_amount = fxs_dollar_value_d18.mul(PRICE_PRECISION).div(fxs_price);
        
    //     redeemFXSBalances[msg.sender] = redeemFXSBalances[msg.sender].add(fxs_amount);
    //     unclaimedPoolFXS = unclaimedPoolFXS.add(fxs_amount);
        
    //     lastRedeemed[msg.sender] = block.number;
        
    //     require(FXS_out_min <= fxs_amount, "Slippage limit reached");
    //     // Move all external functions to the end
    //     FRAX.pool_burn_from(msg.sender, FRAX_amount);
    //     FXS.pool_mint(address(this), fxs_amount);
    // }

    // // After a redemption happens, transfer the newly minted FXS and owed collateral from this pool
    // // contract to the user. Redemption is split into two functions to prevent flash loans from being able
    // // to take out FRAX/collateral from the system, use an AMM to trade the new price, and then mint back into the system.
    // function collectRedemption() external {
    //     require((lastRedeemed[msg.sender].add(redemption_delay)) <= block.number, "Must wait for redemption_delay blocks before collecting redemption");
    //     bool sendFXS = false;
    //     bool sendCollateral = false;
    //     uint FXSAmount = 0;
    //     uint CollateralAmount = 0;

    //     // Use Checks-Effects-Interactions pattern
    //     if(redeemFXSBalances[msg.sender] > 0){
    //         FXSAmount = redeemFXSBalances[msg.sender];
    //         redeemFXSBalances[msg.sender] = 0;
    //         unclaimedPoolFXS = unclaimedPoolFXS.sub(FXSAmount);

    //         sendFXS = true;
    //     }
        
    //     if(redeemCollateralBalances[msg.sender] > 0){
    //         CollateralAmount = redeemCollateralBalances[msg.sender];
    //         redeemCollateralBalances[msg.sender] = 0;
    //         unclaimedPoolCollateral = unclaimedPoolCollateral.sub(CollateralAmount);

    //         sendCollateral = true;
    //     }

    //     if(sendFXS){
    //         TransferHelper.safeTransfer(address(FXS), msg.sender, FXSAmount);
    //     }
    //     if(sendCollateral){
    //         TransferHelper.safeTransfer(address(collteralToken), msg.sender, CollateralAmount);
    //     }
    // }


    // // When the protocol is recollateralizing, we need to give a discount of FXS to hit the new CR target
    // // Thus, if the target collateral ratio is higher than the actual value of collateral, minters get FXS for adding collateral
    // // This function simply rewards anyone that sends collateral to a pool with the same amount of FXS + the bonus rate
    // // Anyone can call this function to recollateralize the protocol and take the extra FXS value from the bonus rate as an arb opportunity
    // function recollateralizeFRAX(uint256 collateral_amount, uint256 FXS_out_min) external {
    //     require(recollateralizePaused == false, "Recollateralize is paused");
    //     uint256 collateral_amount_d18 = collateral_amount * (10 ** missingDecimals);
    //     uint256 fxs_price = FRAX.fxs_price();
    //     uint256 frax_total_supply = FRAX.totalSupply();
    //     uint256 global_collateral_ratio = FRAX.global_collateral_ratio();
    //     uint256 global_collat_value = FRAX.globalCollateralValue();

    //     (uint256 collateral_units, uint256 amount_to_recollat) = FraxPoolLibrary.calcRecollateralizeFRAXInner(
    //         collateral_amount_d18,
    //         getCollateralPrice(),
    //         global_collat_value,
    //         frax_total_supply,
    //         global_collateral_ratio
    //     ); 

    //     uint256 collateral_units_precision = collateral_units.div(10 ** missingDecimals);

    //     uint256 fxs_paid_back = amount_to_recollat.mul(uint(1e6).add(bonus_rate).sub(recollat_fee)).div(fxs_price);

    //     require(FXS_out_min <= fxs_paid_back, "Slippage limit reached");
    //     TransferHelper.safeTransferFrom(address(collteralToken), msg.sender, address(this), collateral_units_precision);
    //     FXS.pool_mint(msg.sender, fxs_paid_back);
        
    // }

    // // Function can be called by an FXS holder to have the protocol buy back FXS with excess collateral value from a desired collateral pool
    // // This can also happen if the collateral ratio > 1
    // function buyBackFXS(uint256 FXS_amount, uint256 COLLATERAL_out_min) external {
    //     require(buyBackPaused == false, "Buyback is paused");
    //     uint256 fxs_price = FRAX.fxs_price();
    
    //     FraxPoolLibrary.BuybackFXS_Params memory input_params = FraxPoolLibrary.BuybackFXS_Params(
    //         availableExcessCollatDV(),
    //         fxs_price,
    //         getCollateralPrice(),
    //         FXS_amount
    //     );

    //     (uint256 collateral_equivalent_d18) = (FraxPoolLibrary.calcBuyBackFXS(input_params)).mul(uint(1e6).sub(buyback_fee)).div(1e6);
    //     uint256 collateral_precision = collateral_equivalent_d18.div(10 ** missingDecimals);

    //     require(COLLATERAL_out_min <= collateral_precision, "Slippage limit reached");
    //     // Give the sender their desired collateral and burn the FXS
    //     FXS.pool_burn_from(msg.sender, FXS_amount);
    //     TransferHelper.safeTransfer(address(collteralToken), msg.sender, collateral_precision);
    // }

    // /* ========== RESTRICTED FUNCTIONS ========== */

    // function toggleMinting() external {
    //     require(hasRole(MINT_PAUSER, msg.sender));
    //     mintPaused = !mintPaused;

    //     emit MintingToggled(mintPaused);
    // }

    // function toggleRedeeming() external {
    //     require(hasRole(REDEEM_PAUSER, msg.sender));
    //     redeemPaused = !redeemPaused;

    //     emit RedeemingToggled(redeemPaused);
    // }

    // function toggleRecollateralize() external {
    //     require(hasRole(RECOLLATERALIZE_PAUSER, msg.sender));
    //     recollateralizePaused = !recollateralizePaused;

    //     emit RecollateralizeToggled(recollateralizePaused);
    // }
    
    // function toggleBuyBack() external {
    //     require(hasRole(BUYBACK_PAUSER, msg.sender));
    //     buyBackPaused = !buyBackPaused;

    //     emit BuybackToggled(buyBackPaused);
    // }

    // function toggleCollateralPrice(uint256 _new_price) external {
    //     require(hasRole(COLLATERAL_PRICE_PAUSER, msg.sender));
    //     // If pausing, set paused price; else if unpausing, clear pausedPrice
    //     if(collateralPricePaused == false){
    //         pausedPrice = _new_price;
    //     } else {
    //         pausedPrice = 0;
    //     }
    //     collateralPricePaused = !collateralPricePaused;

    //     emit CollateralPriceToggled(collateralPricePaused);
    // }

    // // Combined into one function due to 24KiB contract memory limit
    // function setPoolParameters(uint256 new_ceiling, uint256 new_bonus_rate, uint256 new_redemption_delay, uint256 new_mint_fee, uint256 new_redeem_fee, uint256 new_buyback_fee, uint256 new_recollat_fee) external onlyByOwnGov {
    //     pool_ceiling = new_ceiling;
    //     bonus_rate = new_bonus_rate;
    //     redemption_delay = new_redemption_delay;
    //     minting_fee = new_mint_fee;
    //     redemption_fee = new_redeem_fee;
    //     buyback_fee = new_buyback_fee;
    //     recollat_fee = new_recollat_fee;

    //     emit PoolParametersSet(new_ceiling, new_bonus_rate, new_redemption_delay, new_mint_fee, new_redeem_fee, new_buyback_fee, new_recollat_fee);
    // }

    // function setTimelock(address new_timelock) external onlyByOwnGov {
    //     timelock_address = new_timelock;

    //     emit TimelockSet(new_timelock);
    // }

    // /* ========== EVENTS ========== */

    // event PoolParametersSet(uint256 new_ceiling, uint256 new_bonus_rate, uint256 new_redemption_delay, uint256 new_mint_fee, uint256 new_redeem_fee, uint256 new_buyback_fee, uint256 new_recollat_fee);
    // event TimelockSet(address new_timelock);
    // event MintingToggled(bool toggled);
    // event RedeemingToggled(bool toggled);
    // event RecollateralizeToggled(bool toggled);
    // event BuybackToggled(bool toggled);
    // event CollateralPriceToggled(bool toggled);

}