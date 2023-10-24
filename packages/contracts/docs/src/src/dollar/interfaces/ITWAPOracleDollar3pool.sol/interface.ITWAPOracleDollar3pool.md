# ITWAPOracleDollar3pool
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/7c3a0bb87e5e9b32000b3291b4e7da4b119ff3fa/src/dollar/interfaces/ITWAPOracleDollar3pool.sol)

TWAP oracle interface for Curve MetaPool

**What is Curve 3Pool**

The pool that consists of 3 tokens: DAI, USDC, USDT.
Users are free to trade (swap) those tokens. When user adds liquidity
to the pool then he is rewarded with the pool's LP token 3CRV.
1 3CRV LP token != 1 stable coin token.

Add liquidity example:
1. User sends 5 USDC to the pool
2. User gets 5 3CRV LP tokens

Remove liquidity example:
1. User sends 99 3CRV LP tokens
2. User gets 99 USDT tokens

**What is Curve MetaPool**

The pool that consists of 2 tokens: stable coin and 3CRV LP token.
For example the pool may contain Ubiquity Dollar and 3CRV LP token.
This allows users to trade between Ubiquity Dollar and any of the tokens
from the Curve 3Pool (DAI, USDC, USDT). When user adds liquidity to the pool
then he is rewarded with MetaPool LP tokens. 1 Dollar3CRV LP token != 1 stable coin token.

Add liquidity example:
1. User sends 100 Ubiquity Dollars to the pool
2. User gets 100 Dollar3CRV LP tokens of the pool

Remove liquidity example:
1. User sends 100 Dollar3CRV LP tokens to the pool
2. User gets 100 Dollar/DAI/USDC/USDT (may choose any) tokens


## Functions
### update

Updates the following state variables to the latest values from MetaPool:
- Dollar / 3CRV LP quote
- 3CRV LP / Dollar quote
- cumulative prices
- update timestamp


```solidity
function update() external;
```

### consult

Returns the quote for the provided `token` address

If the `token` param is Dollar then returns 3CRV LP / Dollar quote

If the `token` param is 3CRV LP then returns Dollar / 3CRV LP quote

*This will always return 0 before update has been called successfully for the first time*


```solidity
function consult(address token) external view returns (uint256 amountOut);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|Token address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amountOut`|`uint256`|Token price, Dollar / 3CRV LP or 3CRV LP / Dollar quote|


