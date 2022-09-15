import { create } from "../create"
import { DeployFuncParam } from "../utils";

export const optionDefinitions = [
    { name: 'task', defaultOption: true },
    { name: 'admin', alias: 'a', type: String }
]

const func = async (params: DeployFuncParam) => {
    const contractInstance = "../src/dollar/UbiquityAlgorithmicDollarManager.sol:UbiquityAlgorithmicDollarManager";
    const { env, args } = params;
    console.log({ env, args })
    const admin_addr = args.admin;
    const { stdout, stderr } = await create({ ...env, contractInstance, constructorArguments: [admin_addr] });
    console.log({ stdout, stderr });
    return "OK"
}
export default func;