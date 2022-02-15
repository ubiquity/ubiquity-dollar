import { task } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";
import type { Deployment } from "hardhat-deploy/dist/types";

task("abi", "Get contract abi")
  .addPositionalParam(
    "nameOrAddress",
    `Name or the address of contract.
     Use 'hardhat' network to get abi from compiled contract,
     either get abi of latest deployed contract`
  )
  .setAction(async (taskArgs: { nameOrAddress: string }, { deployments, ethers }) => {
    const { nameOrAddress } = taskArgs;
    const { utils } = ethers;

    let contractFactory;
    let deploy: Deployment = { address: "", abi: [] };
    const { chainId, name: chainName } = await ethers.provider.getNetwork();
    let name: string = "";

    if (chainId == 31337) {
      try {
        contractFactory = await ethers.getContractFactory(nameOrAddress);

        console.log(nameOrAddress, "abi from compiled contract");
        console.log(contractFactory.interface.format(utils.FormatTypes.full));
      } catch (e) {
        console.log("No contract with this name", nameOrAddress);
      }
    } else {
      const deploys = await deployments.all();
      for (const [_name, _deploy] of Object.entries(deploys)) {
        if (_deploy.address === nameOrAddress || _name === nameOrAddress) {
          deploy = _deploy;
          name = _name;
          break;
        }
      }
      if (deploy.address) {
        const iface = new utils.Interface(deploy.abi);
        console.log(`${name} abi from deployed contract ${chainName}@${deploy.address}`);
        console.log(iface.format(utils.FormatTypes.full));
      } else {
        console.log("No contract deployed at this name or address", nameOrAddress);
      }
    }
  });
