# dynamic-uad-ui

after git clone the project make sure to run

```bash
git submodule update --init --recursive --remote
```

You need to create `.env` file inside the contracts folder with at least the ALCHEMY_API_KEY filled.

then run ```bash
yarn start```
it will create a file inside `frontend/src` called **uad-contracts-deployment.json** where you can find all the address of the deployed contracts

it will launch a local node on port **8545** you can check the log in the root file `local.node.log`
after the node is launched it will build and run the front on port **3000**

make sure to switch to the hardhat network on metamask

- **chain ID:** 31337
- **RPC URL:** http://127.0.0.1:8545

to get the types from the smart contracts you can import from `contracts/artifacts/types`

```typescript
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";

const token = (await ethers.getContractAt("UbiquityAlgorithmicDollar", uAD.address)) as UbiquityAlgorithmicDollar;

const [sender] = await ethers.getSigners();

const tx = await token.transfer("0x000000000", 100);

```
