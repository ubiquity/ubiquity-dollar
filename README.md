# Ubiquity Dollar

```bash
#!/usr/bin/env bash

# need 4 speed parallel installation (unstable)

mkdir -p uad-ui-deps
cd uad-ui-deps
wget https://raw.githubusercontent.com/ubiquity/uad-ui/main/package.json
yarn & # parallelizes dependency installation
git clone https://github.com/ubiquity/uad-ui.git ../uad-ui # parallelizes clone
cd ../uad-ui
mv ../uad-ui-deps/node_modules ./ # merge files
rm -r ../uad-ui-deps
yarn ape
```

```bash
#!/usr/bin/env bash

# normal

git clone https://github.com/ubiquity/uad-ui.git
cd uad-ui
yarn
yarn ape
```

→ [localhost:3000](https://localhost:3000/)

### Old Docs Below

Personal fork being updated because Vercel offers personal plans for free https://github.com/pavlovcik/uad-ui-launch

### Setup

You need to create `.env` file inside the contracts folder with at least the `API_KEY_ALCHEMY` and the `MNEMONIC` filled. Indeed `MNEMONIC` will be used to deploy locally and the first account will be the admin on all the smart contracts.

#### Configure metamask

make sure to switch to the hardhat network on metamask

- **chain ID:** 31337
- **RPC URL:** http://127.0.0.1:8545

then run the faucet to get some token on your address. You will need the `UAD_MANAGER_ADDRESS` that you can find in the output of the `yarn start`

```
cd contracts
npx hardhat --network localhost faucet --receiver YOUR_ETH_ADDRESS --manager UAD_MANAGER_ADDRESS
```
