// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUbiquityAlgorithmicDollar.sol";
import "./interfaces/IWyvernExchange.sol";

contract Lootbox is Ownable {
    IUbiquityAlgorithmicDollar public uADToken;
    address public uCRToken;

    uint256 public transactionFee;
    uint256 public cashbackPercentage;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IUniswapV2Router02 public uniswapRouter;

    modifier exceptBeforeBuy(uint256 _amountuAD) {
        require(
            IERC20(uADToken).balanceOf(msg.sender) >= _amountuAD * 10**18,
            "Insufficient Balance of uAD token "
        );

        require(
            IERC20(uADToken).allowance(msg.sender, address(this)) >=
                _amountuAD * 10**18,
            "You must approve uAD token before transfer"
        );
        _;
    }

    constructor(
        IUbiquityAlgorithmicDollar _uADToken,
        address _uCRToken,
        IUniswapV2Router02 _uniswapRouter
    ) {
        uADToken = _uADToken;
        uCRToken = _uCRToken;

        transactionFee = 25;
        cashbackPercentage = 100;

        uniswapRouter = _uniswapRouter;
    }

    function setTransactionFee(uint256 _transactionFee) public onlyOwner {
        transactionFee = _transactionFee;
    }

    function setCashbackPercentage(uint256 _cashbackPercentage)
        public
        onlyOwner
    {
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

        uint256[] memory amountOutMins = uniswapRouter.getAmountsOut(
            _amountIn,
            path
        );
        return amountOutMins[path.length - 1];
    }

    function buyNftFromOpenSeaByEth(
        address _nftAddr,
        uint256 _nftId,
        uint256 _price,
        uint256 _amountuAD,
        uint256 _amountOutMin
    ) public exceptBeforeBuy(_amountuAD) {
        uint256 cashbackAmount = (_amountuAD * 10**18 * cashbackPercentage) /
            1000;

        require(
            IERC20(uCRToken).balanceOf(address(this)) >= cashbackAmount,
            "Insufficient Balance of uCR Token"
        );

        IERC20(uADToken).transferFrom(
            msg.sender,
            address(this),
            _amountuAD * 10**18
        );

        address[] memory path = new address[](2);
        path[0] = address(uADToken);
        path[1] = uniswapRouter.WETH();
        uniswapRouter.swapExactTokensForETH(
            _amountuAD * 10**18,
            _amountOutMin,
            path,
            address(this),
            block.timestamp
        );

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
        uint256 cashbackAmount = (_amountuAD * 10**18 * cashbackPercentage) /
            1000;

        require(
            IERC20(uCRToken).balanceOf(address(this)) >= cashbackAmount,
            "Insufficient Balance of uCR Token"
        );

        IERC20(uADToken).transferFrom(
            msg.sender,
            address(this),
            _amountuAD * 10**18
        );

        address[] memory path = new address[](2);
        path[0] = address(uADToken);
        path[1] = uniswapRouter.WETH();
        path[2] = _assetAddr;

        uniswapRouter.swapExactTokensForTokens(
            _amountuAD,
            _amountOutMin,
            path,
            address(this),
            block.timestamp
        );

        IERC20(uCRToken).transfer(msg.sender, cashbackAmount);
    }
}
