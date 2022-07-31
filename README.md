# Ubiquity Dollar

Introducing the flagship product of [Ubiquity DAO](https://ubq.fi/). Ubiquity's Algorithmic Dollar (uAD) is an algorithmic stablecoin that maintains its peg by virtue of its monetary and fiscal policies.

The deployed smart contracts can be found in the [docs](https://dao.ubq.fi/smart-contracts).

![Ubiquity Dollar Logo](https://user-images.githubusercontent.com/4975670/153777249-527395c0-0c52-4731-8b0a-77b7885fafda.png)

## Installation

```bash
#!/usr/bin/env bash
# Ubiquity Dollar Installer

git clone https://github.com/ubiquity/ubiquity-dollar.git
yarn
yarn start
```

→ [localhost:3000](https://localhost:3000/)

## Metamask Development Wallet Setup

### Network Settings

Make sure you are using the following network configuration:

- `31337` chain ID of the Hardhat network.
- `http://127.0.0.1:8545` RPC endpoint of the Hardhat network.

### Shared Private Keys

- All Hardhat developers know about these keys. These keys are derived from the `test test test test test test test test test test test junk` mnemonic in the Hardhat docs.
- Do not send assets of value to these wallets.

```
0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6
0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a
0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba
```

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
