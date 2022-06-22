// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "../../dollar/contracts/interfaces/IUbiquityAlgorithmicDollarManager.sol";
import "../../dollar/contracts/interfaces/IUbiquityAlgorithmicDollar.sol";
import "./interfaces/IWyvernExchange.sol";

contract Lootbox is Ownable {

  IUbiquityAlgorithmicDollarManager public dollarManager;
  IUbiquityAlgorithmicDollar public dollarToken;
  IWyvernExchange public wyvernExchange;

  address public creditToken;

  uint256 public transactionFee;
  uint256 public cashbackPercentage;
  address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  IUniswapV2Router02 public uniswapRouter;

  modifier exceptBeforeBuy(uint256 _amountDollarToken) {

    string memory dollarTokenSymbol = dollarToken.symbol();
    string memory requireTextBalance = keccak256(abi.encodePacked("Insufficient Balance of ", dollarTokenSymbol));
    string memory requireTextAllowance = keccak256(abi.encodePacked("Allowance exceeds of ", dollarTokenSymbol));

    require(IERC20(dollarToken).balanceOf(msg.sender) >= _amountDollarToken * 10**18, requireTextBalance);

    require(IERC20(dollarToken).allowance(msg.sender, address(this)) >= _amountDollarToken * 10**18, requireTextAllowance);
    _;
  }

  constructor(
    IUbiquityAlgorithmicDollarManager _dollarManager,
    IUniswapV2Router02 _uniswapRouter,
    IWyvernExchange _wyvernExchange
  ) {
    dollarManager = _dollarManager;

    dollarToken = IUbiquityAlgorithmicDollar(dollarManager.dollarTokenAddress());
    creditToken = dollarManager.debtCouponAddress();

    uCRToken = _uCRToken;

    transactionFee = 25;
    cashbackPercentage = 100;

    uniswapRouter = _uniswapRouter;
    wyvernExchange = _wyvernExchange;
  }

  function setDollarToken(IUbiquityAlgorithmicDollar _dollarToken) public onlyOwner {
    dollarToken = _dollarToken;
  }

  function setCreditToken(address _creditToken) public onlyOwner {
    creditToken = _creditToken;
  }

  function setTransactionFee(uint256 _transactionFee) public onlyOwner {
    transactionFee = _transactionFee;
  }

  function setCashbackPercentage(uint256 _cashbackPercentage) public onlyOwner {
    cashbackPercentage = _cashbackPercentage;
  }

  function getAmountOutMin(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) external view returns (uint256) {
    address[] memory path;
    if (_tokenIn == WETH || _tokenOut == WETH) {
      path = new address[](2);
      path[0] = _tokenIn;
      path[1] = _tokenOut;
    } else {
      path = new address[](3);
      path[0] = _tokenIn;
      path[1] = WETH;
      path[2] = _tokenOut;
    }

    uint256[] memory amountOutMins = uniswapRouter.getAmountsOut(_amountIn, path);
    return amountOutMins[path.length - 1];
  }

  function buyNftFromOpenSeaByEth(
    address _nftAddr,
    uint256 _nftId,
    uint256 _price,
    uint256 _amountuAD,
    uint256 _amountOutMin
  ) public exceptBeforeBuy(_amountuAD) {
    uint256 cashbackAmount = (_amountuAD * 10**18 * cashbackPercentage) / 1000;

    require(IERC20(uCRToken).balanceOf(address(this)) >= cashbackAmount, "Insufficient Balance of uCR Token");

    IERC20(dollarToken).transferFrom(msg.sender, address(this), _amountuAD * 10**18);

    address[] memory path = new address[](2);
    path[0] = address(dollarToken);
    path[1] = uniswapRouter.WETH();
    uniswapRouter.swapExactTokensForETH(_amountuAD * 10**18, _amountOutMin, path, address(this), block.timestamp);

    address[] memory addrs = new address[](14);

    /* Exchange address, intended as a versioning mechanism. */
    addrs[0] = address(wyvernExchange);
    /* Order maker address. */
    addrs[1] = address(this);
    /* Order taker address, if specified. */
    addrs[2] = address(wyvernExchange);
    /* Order fee recipient or zero address for taker order. */
    addrs[3] = address(0);
    /* Target. */
    addrs[4] = address(this);
    
    uint256[] memory uints = new uint256[](18);

    /* Maker relayer fee of the order, unused for taker order. */
    uints[0] = 0;
    /* Taker relayer fee of the order, or maximum taker fee for a taker order. */
    uints[1] = 0;
    /* Maker protocol fee of the order, unused for taker order. */
    uints[2] = 0;
    /* Taker protocol fee of the order, or maximum taker fee for a taker order. */
    uints[3] = 0;

    // wyvernExchange.atomicMatch_(addrs, uints, feeMethodsSidesKindsHowToCalls, calldataBuy, calldataSell, replacementPatternBuy, replacementPatternSell, staticExtradataBuy, staticExtradataSell, vs, rssMetadata);
    IERC20(uCRToken).transfer(msg.sender, cashbackAmount);
  }

  function buyNFTFromOpenseaByExactToken(
    address _nftAddr,
    address _assetAddr,
    uint256 _nftId,
    uint256 _price,
    uint256 _amountuAD,
    uint256 _amountOutMin
  ) public exceptBeforeBuy(_amountuAD) {
    uint256 cashbackAmount = (_amountuAD * 10**18 * cashbackPercentage) / 1000;

    require(IERC20(uCRToken).balanceOf(address(this)) >= cashbackAmount, "Insufficient Balance of uCR Token");

    IERC20(dollarToken).transferFrom(msg.sender, address(this), _amountuAD * 10**18);

    address[] memory path = new address[](2);
    path[0] = address(dollarToken);
    path[1] = uniswapRouter.WETH();
    path[2] = _assetAddr;

    uniswapRouter.swapExactTokensForTokens(_amountuAD, _amountOutMin, path, address(this), block.timestamp);

    IERC20(uCRToken).transfer(msg.sender, cashbackAmount);
  }
}
