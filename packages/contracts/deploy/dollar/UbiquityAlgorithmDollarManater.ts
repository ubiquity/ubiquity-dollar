import { create } from "../create"
import { DeployFuncParam } from "../utils";

export const optionDefinitions = [
    { name: 'task', defaultOption: true },
    { name: 'admin', alias: 'a', type: String }
]

const func = async (params: DeployFuncParam) => {
    const contractInstance = "src/dollar/UbiquityAlgorithmicDollarManager.sol:UbiquityAlgorithmicDollarManager";
    const { env, args } = params;
    const admin_addr = args.admin;

    // TODO: Need to compare bytecode with previous deployedBytecode and deploy if there's a change.
    // If there's no change, we need to check `--force` flag
    const { stdout, stderr } = await create({ ...env, name: args.task, contractInstance, constructorArguments: [admin_addr] });
    console.log({ stdout, stderr });
    return "OK"
}
export default func; ""
