# uad-ui

Personal fork being updated because Vercel offers personal plans for free https://github.com/pavlovcik/uad-ui-launch

## Getting Started

### Cloning etc..

after git clone the project make sure to run

```bash
git submodule update --init --recursive --remote
```

You need to create `.env` file inside the contracts folder with at least the `ALCHEMY_API_KEY` and the `MNEMONIC` filled. Indeed `MNEMONIC` will be used to deploy locally and the first account will be the admin on all the smart contracts.

### DEV ONLY Running a local node that forks the mainnet

```
yarn start:dev
copy paste contracts/artifact/types inside frontend/contracts
// run the faucet task see below
we have to find the address of the ubiquitydollar copy paste the address inside frontend/pages/index.tsx
cd frontend
yarn && yarn build && yarn start

```

### Running a local node that forks the mainnet

then run

```bash
yarn install && yarn start
```

it will create a file inside `frontend` called **uad-contracts-deployment.json** where you can find all the address of the deployed contracts

it will launch a local node on port **8545** you can check the log in the root file `local.node.log`
after the node is launched it will build and run the front on port **3000**

### Configure metamask

make sure to switch to the hardhat network on metamask

- **chain ID:** 31337
- **RPC URL:** http://127.0.0.1:8545

then run the faucet to get some token on your address. You will need the `UAD_MANAGER_ADDRESS` that you can find in the output of the `yarn start`

```
cd contracts
npx hardhat --network localhost faucet --receiver YOUR_ETH_ADDRESS --manager UAD_MANAGER_ADDRESS
```

## Coding with typed object that represents the smart contract

to get the types from the smart contracts you can import from `contracts/artifacts/types`

```typescript
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";

const token = (await ethers.getContractAt("UbiquityAlgorithmicDollar", uAD.address)) as UbiquityAlgorithmicDollar;

const [sender] = await ethers.getSigners();

const tx = await token.transfer("0x000000000", 100);
```
