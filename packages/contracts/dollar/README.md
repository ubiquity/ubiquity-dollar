# Ubiquity Algorithmic Dollar Contracts

![Logo of the project](https://bafybeifibz4fhk4yag5reupmgh5cdbm2oladke4zfd7ldyw7avgipocpmy.ipfs.infura-ipfs.io/)

## Table of Contents

1. [Getting started](#Getting)
2. [Building](#Building)
3. [Deployment](#Deployment)
4. [Testing](#Testing)
5. [Contracts](#Contracts)
6. [Licensing](#Licensing)

## Getting started

### Prerequisites

- [Node.js](https://nodejs.org/en/download/)

### Installing

Install dependencies:

```sh
yarn install
```

## Building

Compile the smart contracts:

```sh
yarn run compile
```

To verify the accounts that will be used by hardhat

```sh
yarn hardhat accounts
```

## Deployment

To deploy the smart contracts on a network defined in the `hardhat.config.ts`
rename the `example.env` file to `.env` and fill the `MNEMONIC`, `API_KEY_ALCHEMY` and
`API_KEY_COINMARKETCAP` environment variables.

```sh
yarn hardhat run --network <your-network> scripts/deployment.ts
```

Note that by default smart contracts will be deployed locally using hardhat development node.

## Mainnet monitoring

### Token

this task will retrieve information about all our tokens including LP token

```sh
yarn hardhat --network mainnet token
```

### Incentives

this task will retrieve information about the current incentives and penalty on uAD buy and sell

```sh
yarn hardhat --network mainnet incentive
```

### Metapool

this task will retrieve information about our curve uAD-3CRV metapool

```sh
yarn hardhat --network mainnet metapool
```

### Price

this task will retrieve information about uAD price

```sh
yarn hardhat --network mainnet price
```

### Manager

this task will all the addresses registered in the manager

```sh
yarn hardhat --network mainnet manager
```

### Get Bonding Contract Transactions

this task will retrieve and filter the bonding contract transactions, print a summary and save them to a file

```sh
# OPTIONS: --end-block <INT> [--is-error <BOOLEAN>] [--name <STRING>] [--start-block <INT>] [path]

#   --end-block  	The end block for the Etherscan request (defaults to latest block)
#   --is-error   	Select transactions that were errors (default: false)
#   --name       	The function name (use empty string for all) (default: "deposit")
#   --start-block	The starting block for the Etherscan request (defaults is contract creation block) (default: 12595544)
#   path	The path to store the bonding contract transactions (default: "./bonding_transactions.json")

yarn hardhat --network mainnet getBondingTransactions
```

## Testing

### Requirements:

- node 14.15 (use nvm)

Rename the `example.env` file to `.env` and fill:

- `API_KEY_ALCHEMY`: [get key at Alchemy API Dashboard](https://dashboard.alchemyapi.io/)
- `API_KEY_COINMARKETCAP`: [get key at CoinMarket](https://pro.coinmarketcap.com/login)

### Launch all tests

```sh
yarn run test
```

if you experience some timeout issues try running tests one by one

### Forking

To run a local node that forks mainnet we use Hardhat with the Alchemy API.

```sh
yarn node:start
```

If you are using Metamask on the browser, you can point it to the local node
from the network menu by adding a custom RPC network with the following configuration:

- Network name: `Hardhat`
- RPC Url: `http://localhost:8545`
- Chain ID: `31337`

### Give yourself funds

We recommend you use a separate browser session with Metamask for development.
When you are prompted with the mnemonic phrase copy it to the .env file:

```bash
MNEMONIC="test test test test test test test test test test test junk"
```

(remember to use the quotation marks)

When the hardhat fork starts it will create 10 accounts with 10000 ETH each from
that phrase. Metamask will be using these accounts too.

Now for the sake of testing you may want to give yourself uAD, uCR, UBQ, and uAD3CRV-f tokens.
To do this, there is a tasks named faucet that gives you 1000 of each, transferred from
the Ubiquity treasury account.

```sh
yarn node:faucet
```

This is to be run only when the `yarn node:start` task is running on another terminal window.

## Contracts

- twapOracle
  - `0x7944d5b8f9668AfB1e648a61e54DEa8DE734c1d1`
- debtCoupon
  - `0xcEFAF85110536eC6F78B0B71624BfA584B6fABa1`
- uADToken
  - `0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6`
- couponCalculator
  - `0x4F3dF4c1e22209d623ab55923109112f1E2B17DE`
- dollarMintingCalculator
  - `0xab840faA6A5eF68D8D32370EBC297f4DdC9F870F`
- bondingShare
  - `0x2dA07859613C14F6f05c97eFE37B9B4F212b5eF5`
- bondingContract
  - `0xC251eCD9f1bD5230823F9A0F99a44A87Ddd4CA38`
- uAD-3CRV metapool deployed aka stableSwapMetaPool
  - `0x20955CB69Ae1515962177D164dfC9522feef567E`
- curve3PoolToken
  - `0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490`
- uGOVToken
  - `0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0`
- sushiSwapPool
  - `0x534ac94F198F1fef0aDC45227A2185C7cE8d75dC`
- masterChef
  - `0xdae807071b5AC7B6a2a343beaD19929426dBC998`
- formulas
  - `0x54F528979A50FA8Fe99E0118EbbEE5fC8Ea802F7`
- autoRedeemToken
  - `0x5894cFEbFdEdBe61d01F20140f41c5c49AedAe97`
- uarCalculator
  - `0x75d6F33BcF784504dA74e4aD60c677CD1fD3e2d5`
- ExcessDollarsDistributor
  - `0x25d2b980E406bE97237A06Bca636AeD607661Dfa`
- debtCouponMgr
  - `0x432120Ad63779897A424f7905BA000dF38A74554`
- UbiquityAlgorithmicDollarManager
  - `0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98`
- curveIncentive
  - `0x86965cdB680350C5de2Fd8D28055DecDDD52745E`
- treasury
  - `0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd | ubq.eth`

## Licensing

Copyright (c) 2021 Ubiquity
Licensed under the MIT License

```

```
