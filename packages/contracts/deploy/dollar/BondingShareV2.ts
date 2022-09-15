import { DeployFuncParam } from "../utils";
import { create } from "../create"

export const optionDefinitions = [
    { name: 'task', defaultOption: true },
    { name: 'manager', alias: 'm', type: String }
]

const func = async (params: DeployFuncParam) => {
    const contractInstance = "src/dollar/BondingShareV2.sol:BondingShareV2";
    const { env, args } = params;
    const manager = args.manager;
    const uri = JSON.stringify({
        "name": "Bonding Share",
        "description": "Ubiquity Bonding Share V2",
        "image": "https://bafybeifibz4fhk4yag5reupmgh5cdbm2oladke4zfd7ldyw7avgipocpmy.ipfs.infura-ipfs.io/"
    });

    const { stderr } = await create({ ...env, name: args.task, contractInstance, constructorArguments: [manager, uri] });
    return !stderr ? "succeeded" : "failed"
}
export default func;