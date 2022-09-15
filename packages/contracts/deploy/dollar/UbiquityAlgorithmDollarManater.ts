import { Wallet } from "ethers"
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
    const wallet = new Wallet(env.privateKey);
    const adminAddress = await wallet.getAddress();

    return "OK"
}
export default func;