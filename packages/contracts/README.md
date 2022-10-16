# Ubiquity Smart Contracts

@ubiquity/contracts contains the various Solidity smart contracts used within the Ubiqity Dollar Protocol.

## Install

You need to have [foundry-rs](https://github.com/foundry-rs/foundry) installed locally first.

```bash
yarn workspace @ubiquity/contracts forge install
```

## Build

```bash
yarn workspace @ubiquity/contracts run build
```

## Test

```bash
yarn workspace @ubquity/contracts run test
```

## Prettier

```bash
yarn workspace @ubiquity/contracts prettier
```

## Deploy

Deploy script has been built on top of `forge create` and typescript to manage deployments locally.

```bash
yarn workspace @ubiquity/contracts deploy DEPLOY_NAME ARGUMENTS
# e.g. yarn workspace @ubiuqity/contracts deploy Bonding --manager 0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98 --siblings 0x0000000000000000000000000000000000000000 --network mainnet

'DEPLOY_NAME': Must be configured in scripts/manager.ts
'ARGUMENTS': Deploy Arguments which has been configured per smart contract. You can find them in each deploy script file.
```
