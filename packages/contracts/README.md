# Ubiquity Dollar Smart Contracts

`@ubiquity/contracts` contains the various Solidity smart contracts used within the Ubiquity Algorithmic Dollar Protocol.

## Install

You need to have [Foundry](https://github.com/foundry-rs/foundry) installed locally first. Check [Foundry Book](https://book.getfoundry.sh/getting-started/installation)

Then you'll be able to:

```bash
yarn workspace @ubiquity/contracts run forge:install
```

## Build

```bash
yarn workspace @ubiquity/contracts run build
```

## Test

```bash
yarn workspace @ubiquity/contracts run test:unit
```

## Deploy

Deploy script has been built on top of `forge create` and typescript to manage deployments locally.

```sh
# Deploy Local Development

yarn start:anvil

yarn deploy:development

```
