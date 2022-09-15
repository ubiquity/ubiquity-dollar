import { DeployFuncParam } from "../utils";
import { create } from "../create"
import { constants } from "ethers"

export const optionDefinitions = [
    { name: 'task', defaultOption: true },
    { name: 'manager', alias: 'm', type: String },
    { name: "sablier", alias: 's', type: String }
]

const func = async (params: DeployFuncParam) => {
    const contractInstance = "src/dollar/Bonding.sol:Bonding";
    const { env, args } = params;
    const manager = args.manager;
    const sablier = args.sablier ?? constants.AddressZero;

    const { stderr } = await create({ ...env, name: args.task, contractInstance, constructorArguments: [manager, sablier] });
    return !stderr ? "succeeded" : "failed"
}
export default func;