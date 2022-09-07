# Ubiquity- Proxy yield aggregator

Forge test scripts located in: test/ <br />

# Repo Setup

After cloning, run:

```
mkdir lib 
```
we should have a `ubiquity/ubiquity-dollar/contracts/yield-aggregator/lib` folder
```
forge install foundry-rs/forge-stdfor
```
```
forge install openzeppelin/openzeppelin-contracts
```
```
forge build
```

# tests

Forge has been installed into the repo. Article here about how to install locally to run tests: <br /> https://mirror.xyz/crisgarner.eth/BhQzl33tthkJJ3Oh2ehAD_2FXGGlMupKlrUUcDk0ALA <br />
To run all test on forked mainnet: <br />

```
forge test --fork-url https://eth-mainnet.alchemyapi.io/v2/YOURKEYHERE
```

To run a test cases for specific one: <br />
```
forge test -m  testExample  --fork-url https://eth-mainnet.alchemyapi.io/v2/YOURKEYHERE -vvvvv
```
for test containing string
```
forge test --mc ERC4626  --fork-url https://eth-mainnet.alchemyapi.io/v2/YOURKEYHERE -v
forge test --mc Proxy  --fork-url https://eth-mainnet.alchemyapi.io/v2/YOURKEYHERE -vvvv

``` 

### strategy

Admin can CRUD on a valid strategy. A strategy is a protocol that follows the [ERC-4626](https://eips.ethereum.org/EIPS/eip-4626) standard ([working example from rari capital](https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol) ). To be valid strategies are restricted to single stablecoin e.g. deposit USDC/DAI/USDT but not an LP token even if it represents a pool of stablecoins.

When they will implement ERC4626 in yearn V3 these would be [valid yearn strategies](https://vaults.yearn.finance/ethereum/stables)

to swap from one strategy to another it would be nice to go through an [ERC4626 router](https://github.com/fei-protocol/ERC4626)

### deployment on goerli

here is an ERC4626 example deployed on goerli
