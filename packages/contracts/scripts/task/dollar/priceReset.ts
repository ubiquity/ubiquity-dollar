import { TaskFuncParam } from "../../shared";
import { constants } from "ethers"

export const optionDefinitions = [
    { name: 'task', defaultOption: true },
    { name: 'price', alias: 'p', type: Number },
    { name: "dryrun", alias: 'd', type: Boolean },
    { name: "twapUpdate", alias: 't', type: Boolean },
    { name: "network", alias: 'n', type: String },
]

const func = async (params: TaskFuncParam) => {
    const contractInstance = "src/dollar/Bonding.sol:Bonding";
    const { env, args } = params;
    const manager = args.manager;
    const sablier = args.sablier ?? constants.AddressZero;

    const { stderr } = await create({ ...env, name: args.task, network: args.network, contractInstance, constructorArguments: [manager, sablier] });
    return !stderr ? "succeeded" : "failed"
}
export default func;