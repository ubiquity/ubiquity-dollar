# Ubiquity Dollar

Introducing the flagship product of [Ubiquity DAO](https://ubq.fi/). Ubiquity's Algorithmic Dollar (uAD) is an algorithmic stablecoin that maintains its peg by virtue of its monetary and fiscal policies.

The deployed smart contracts can be found in the [docs](https://dao.ubq.fi/smart-contracts).

![Ubiquity Dollar Logo](https://user-images.githubusercontent.com/4975670/153777249-527395c0-0c52-4731-8b0a-77b7885fafda.png)

## Contributing

- We welcome everybody to participate in improving the codebase.

- We offer incentives for contributors to solve issues.

- Please learn how to contribute via our bounty program [here](https://github.com/ubiquity/ubiquity-dollar/wiki/Bounty-Rules/).

## Yarn Workspaces

The repo has been built as a [yarn workspace](https://yarnpkg.com/features/workspaces) monorepo.

<pre>
&lt;root&gt;
├── <a href="https://github.com/ubiquity/ubiquity-dollar/tree/development/packages">packages</a>
│   ├── <a href="https://github.com/ubiquity/ubiquity-dollar/tree/development/packages/contracts">contracts</a>: Smart contracts for Ubiquity Dollar and UbiquiStick
│   ├── <a href="https://github.com/ubiquity/ubiquity-dollar/tree/development/packages/dapp">dapp</a>: User interface
</pre>

## Installation

- We use [Foundry](https://github.com/foundry-rs/foundry).
- Here are their [docs](https://book.getfoundry.sh/).
- Please follow their installation guide for your OS before proceeding.

```bash
git clone https://github.com/ubiquity/ubiquity-dollar.git
yarn
```

## Build

```bash
yarn build:all # builds the smart contracts and user interface
```

To build individual package, run the build command for each package:

```bash
yarn workspace @ubiquity/contracts build # Build smart contracts
yarn workspace @ubiquity/dapp build # Build the user interface
```

**_NOTE_**: Dapp package depends on the contracts package.

## Test

As of the last time this was updated this supports smart contract unit tests. In the future we will include UI tests.

```bash
yarn test:all
```

## Running workspace specific commands

```bash
# SCRIPT_NAME=XXX

yarn workspace @ubiquity/contracts $SCRIPT_NAME
yarn workspace @ubiquity/dapp $SCRIPT_NAME

# For example...

yarn workspace @ubiquity/contracts test # Run the smart contract unit tests
yarn workspace @ubiquity/dapp start # Run the application at http://localhost:3000

```

## Committing Code

1. We [automatically enforce](https://github.com/conventional-changelog/commitlint) the [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/) format for commit messages. This can be frustrating for junior developers, but I promise that you'll quickly get used to it!

The Conventional Commits specification is a lightweight convention on top of commit messages. It provides an easy set of rules for creating an explicit commit history; which makes it easier to write automated tools on top of. 

We use [prettier](https://github.com/prettier/prettier) and [eslint](https://github.com/eslint/eslint) on [staged files](https://github.com/okonet/lint-staged) in order to enforce a uniform code style. Please do not circumvent these rules.

## MetaMask Development Wallet Setup

### Network Settings

Make sure you are using the following network configuration:

- `31337` chain ID of the Hardhat network.
- `http://127.0.0.1:8545` RPC endpoint of the Hardhat network.

### Shared Private Keys

- These keys are derived from the `upset concert service toy elephant spoil gun yellow girl provide click beauty`.
- Do not send assets of value to these wallets.

| PATH              | ADDRESS                                    | PRIVATE KEY                                                        |
| :---------------- | :----------------------------------------- | :----------------------------------------------------------------- |
| m/44'/60'/0'/0/0  | 0xa18E35a6E821AaDC80AFD132FFa72879f999F2fc | 0x4454691749f69f1224e443731757b75005d0335d38cd3900d7f74e64625c6091 |
| m/44'/60'/0'/0/1  | 0x959d25B75324fBE0ADc75a454Df286eaBc7B45a7 | 0x61aefdfdd9dc3f84b6e9e061dd51781b126a78f54836ae77d9b9b81017d801b6 |
| m/44'/60'/0'/0/2  | 0x1cDd6EfC312982F337E45cBA1050422908564358 | 0x934eaa469cf07f77eef7eba88279d7be916887e7be42bbf8abeac1e300c02d5e |
| m/44'/60'/0'/0/3  | 0x1853E2B5F1135e888a85b1C0Cf54D5Fa4E82d5A1 | 0xa6eebebb2e7a4adc76a4710e980af27f550a55b2753bf3e9badaf635c34f9f91 |
| m/44'/60'/0'/0/4  | 0x7f1F7e985F85891Be5E38fCC6242fFCF81a08576 | 0xf50d765fff48f95cca730165913c8e645f13f8bc5a14e8cb2edf125748ef1afe |
| m/44'/60'/0'/0/5  | 0xd7a01fd8a68723baB8dBbE162504D8b4Fb49e2c9 | 0x727d650cc0c833f8ae2bff91d14e2fc4b23cee28e6d961c5307666e58a12b163 |
| m/44'/60'/0'/0/6  | 0xC16AD476ab93b80C16fD6F00cDD79E4F9A7b7a76 | 0xa65196f91a8b6007808c508beda7f755ca808f899c4254865766e5aecb837528 |
| m/44'/60'/0'/0/7  | 0x4A3DdEfFB0d2C1f69C083f578301896757B2b232 | 0x13d5a3866730f686dc8bf248710106a8e660bc861739cadf71c5dd261f90b533 |
| m/44'/60'/0'/0/8  | 0x9Bf996d84AAecBb2E06dc5F277B7A26EBCA52A67 | 0x61eafce90092133ec543caa90c085af57c850df1b400f0af5cd0bf34fcddb052 |
| m/44'/60'/0'/0/9  | 0x71454ff148c22f6D2Fc50C13aF0B702Aaa134189 | 0x3c82c68b4df60547a5fb926bf8d9513f4a6cf07604cb6429778ef6dce4eb48fb |
| m/44'/60'/0'/0/10 | 0x53e93feD0C06D78ec86cEfC58b619BD6B5F93Ade | 0x79c924066175ae04a3ef3cd88d293e1c2f7fd7a860c5ddb8f09077bd4225c757 |

### Ubiquity Dollar Contracts Setup

This section is for the Ubiquity Dollar core protocol smart contracts (not the UbiquiStick NFT or UI related code.)

You need to create `.env` file inside the contracts folder with at least the `API_KEY_ALCHEMY` and the `MNEMONIC` filled. Indeed `MNEMONIC` will be used to deploy locally and the first account will be the admin on all the smart contracts.

Run the faucet to get tokens to your address. You will need the `UAD_MANAGER_ADDRESS` that you can find in the output of the `yarn start`

```bash
YOUR_ETH_ADDRESS= # enter address here
UAD_MANAGER_ADDRESS= # enter address here
yarn hardhat --network localhost faucet --receiver $YOUR_ETH_ADDRESS --manager $UAD_MANAGER_ADDRESS
```

Sine stabilitate nihil habemus.
