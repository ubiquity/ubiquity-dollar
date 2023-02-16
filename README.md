![](https://byob.yarr.is/FibrinLab/ubiquity-dollar/coverage)

![Version](https://img.shields.io/badge/version-${{steps.version.outputs.version}}-blue)


![CodeQL](https://github.com/ubiquity/ubiquity-dollar/actions/workflows/codeql-analysis.yml/badge.svg?branch=development)
![Conventional Commits](https://github.com/ubiquity/ubiquity-dollar/actions/workflows/conventional-commits.yml/badge.svg?branch=development)
![Build and Test](https://github.com/ubiquity/ubiquity-dollar/actions/workflows/build-and-test.yml/badge.svg?branch=development)
![Yarn Audit](https://github.com/ubiquity/ubiquity-dollar/actions/workflows/yarn-audit.yml/badge.svg?branch=development)
![Slither Analysis](https://github.com/ubiquity/ubiquity-dollar/actions/workflows/slither-analysis.yml/badge.svg?branch=development)


# Ubiquity Dollar
Introducing the flagship product of [Ubiquity DAO](https://ubq.fi/). The Ubiquity Dollar (uAD) is a collateralized stablecoin.
- The deployed smart contracts can be found in the [docs](https://dao.ubq.fi/smart-contracts).
- The source code for those are archived [here](https://github.com/ubiquity/uad-contracts).

![Ubiquity Dollar Logo](https://user-images.githubusercontent.com/4975670/153777249-527395c0-0c52-4731-8b0a-77b7885fafda.png)
## Contributing
- We welcome everybody to participate in improving the codebase.
- We offer financial incentives for solved issues.
- Please learn how to contribute via the DevPool [here](https://dao.ubq.fi/devpool).
## Installation
- We use [Foundry](https://github.com/foundry-rs/foundry).
- Here are their [docs](https://book.getfoundry.sh/).
- Please follow their installation guide for your OS before proceeding.

### Development Setup
```sh
#!/bin/bash

git clone https://github.com/ubiquity/ubiquity-dollar.git
cd ubiquity-dollar/
yarn
yarn build:all # builds the smart contracts and user interface
yarn start & # starts the user interface and daemonize'd to continue to run tests in the background
yarn test:all
```
## Running workspace specific commands
Utilizing yarn workspaces, you can invoke scripts for each workspace individually.
```sh
# SCRIPT_NAME=XXX

yarn workspace @ubiquity/contracts $SCRIPT_NAME
yarn workspace @ubiquity/dapp $SCRIPT_NAME

# For example...

yarn workspace @ubiquity/contracts build # Build smart contracts
yarn workspace @ubiquity/contracts test # Run the smart contract unit tests

yarn workspace @ubiquity/dapp build # Build the user interface
yarn workspace @ubiquity/dapp start # Run the application at http://localhost:3000

```
## Committing Code

1. We [automatically enforce](https://github.com/conventional-changelog/commitlint) the [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/) format for commit messages.

> The Conventional Commits specification is a lightweight convention on top of commit messages. It provides an easy set of rules for creating an explicit commit history; which makes it easier to write automated tools on top of.

2. We use [prettier](https://github.com/prettier/prettier), [eslint](https://github.com/eslint/eslint) and [cspell](https://github.com/streetsidesoftware/cspell) on [staged files](https://github.com/okonet/lint-staged) in order to enforce a uniform code style. Please do not circumvent these rules.


### Network Settings
| Network | Chain ID | RPC Endpoint                  | Comment |
|---------|----------|-------------------------------|---------|
| `mainnet` | `1`        | `https://eth.ubq.fi/v1/mainnet` | Our dedicated mainnet gateway     |
| `anvil`   | `31337`    | `http://127.0.0.1:8545`         | Used for local development     |

## Deploying Contracts (Ubiquity Dollar Core)

In two separate terminals run the following commands:

```sh
yarn workspace @ubiquity/contracts start:anvil # starts the anvil testnet
```

```sh
yarn workspace @ubiquity/contracts deploy:development # deploys the contracts to the anvil testnet
```

You need to create `.env` file inside the contracts folder with `PRIVATE_KEY`, `PUBLIC_KEY`, `MNEMONIC`, and `CURVE_WHALE` all filled. `PRIVATE_KEY` will be used to deploy locally and the matching `PUBLIC_KEY` will be the admin on all the smart contracts. `MNEMONIC` is used when launching Anvil and will ensure your `PUBLIC_KEY` account is funded.

The `.env.example` is pre-populated with the recommend test `MNEMONIC`, test `PRIVATE_KEY`, and test `PUBLIC_KEY`.

If successful it will show a readout of accounts generated from `MNEMONIC` and the port it's listening on.

This will first impersonate the `CURVE_WHALE` and transfer some tokens so we can create a UbiquityDollar/3CRV pool, and then it will deploy the Ubiquity Dollar core protocol via a series of Solidity scripts via Forge.

## MetaMask Development Wallet Setup
### Shared Private Keys for Development

- These keys are derived from `test test test test test test test test test test test junk`.
- Do not send assets of value to these wallets.

```
Private Key; Address; Path
```

```
ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80; 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266; m/44'/60'/0'/0/0
59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d; 0x70997970c51812dc3a010c7d01b50e0d17dc79c8; m/44'/60'/0'/0/1
5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a; 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc; m/44'/60'/0'/0/2
7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6; 0x90f79bf6eb2c4f870365e785982e1f101e93b906; m/44'/60'/0'/0/3
47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a; 0x15d34aaf54267db7d7c367839aaf71a00a2c6a65; m/44'/60'/0'/0/4
8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba; 0x9965507d1a55bcc2695c58ba16fb37d819b0a4dc; m/44'/60'/0'/0/5
92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e; 0x976ea74026e726554db657fa54763abd0c3a0aa9; m/44'/60'/0'/0/6
4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356; 0x14dc79964da2c08b23698b3d3cc7ca32193d9955; m/44'/60'/0'/0/7
dbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97; 0x23618e81e3f5cdf7f54c3d65f7fbc0abf5b21e8f; m/44'/60'/0'/0/8
2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6; 0xa0ee7a142d267c1f36714e4a8f75612f20a79720; m/44'/60'/0'/0/9
```

## Yarn Workspaces

The repo has been built as a [yarn workspace](https://yarnpkg.com/features/workspaces) monorepo.

<pre>
&lt;root&gt;
├── <a href="https://github.com/ubiquity/ubiquity-dollar/tree/development/packages">packages</a>
│   ├── <a href="https://github.com/ubiquity/ubiquity-dollar/tree/development/packages/contracts">contracts</a>: Smart contracts for Ubiquity Dollar and UbiquiStick
│   ├── <a href="https://github.com/ubiquity/ubiquity-dollar/tree/development/packages/dapp">dapp</a>: User interface
</pre>

## Codebase Diagram

[Interactive Version](https://mango-dune-07a8b7110.1.azurestaticapps.net/?repo=ubiquity%2Fubiquity-dollar)

### Smart Contracts

![Visualization of the smart contracts codebase](./utils/diagram-contracts.svg)

### User Interface

![Visualization of the user interface codebase](./utils/diagram-ui.svg)

---

Sine stabilitate nihil habemus.
