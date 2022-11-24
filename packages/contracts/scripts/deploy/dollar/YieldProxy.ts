import { OptionDefinition } from "command-line-args";

import { DeployFuncParam, deployments, Networks } from "../../shared";
import { create } from "../create"
import { ethers } from "ethers";

export const optionDefinitions: OptionDefinition[] = [
    { name: 'task', defaultOption: true },
    { name: 'manager', alias: 'm', type: String },
    { name: 'jar', alias: 'j', type: String },
    { name: "network", alias: 'n', type: String },
]

const func = async (params: DeployFuncParam) => {
    const contractInstance = "src/dollar/YieldProxy.sol:YieldProxy";
    const { env, args } = params;
    const chainId = Networks[args.network] ?? undefined;
    if (!chainId) {
        throw new Error(`Unsupported network: ${args.network} Please configure it out first`);
    }
    const uad_manager_deployments = await deployments(chainId.toString(), "UbiquityAlgorithmicDollarManager");
    const manager = args.manager ?? uad_manager_deployments.address;
    const jar_address = args.jar_address;
    // fees 10000 = 10% because feesMax = 100000 and 10000 / 100000 = 0.1
    const fees = 10000;
    // UBQRate 10e18, if the UBQRate is 10 then 10/10000 = 0.001
    // 1UBQ gives you 0.001% of fee reduction so 100000 UBQ gives you 100%
    const UBQRate = ethers.utils.parseEther("100");
    // bonusYield  5000 = 50% 100 = 1% 10 = 0.1% 1 = 0.01%
    const bonusYield = 5000;

    const { result, stderr } = await create({ ...env, name: args.task, network: args.network, contractInstance, constructorArguments: [manager, jar_address, fees, UBQRate, bonusYield] });

    const yield_proxy_address = result!.deployedTo;

    const signer = new ethers.Wallet(env.privateKey, new ethers.providers.JsonRpcProvider(env.rpcUrl));
    console.log("Granting UBQ_MINTER_ROLE...", { yield_proxy_address, uad_manager: manager })
    const uad_manager_contract = new ethers.Contract(manager, uad_manager_deployments.abi, signer)
    const tx = await uad_manager_contract.grantRole(yield_proxy_address);
    const receipt = await tx.wait();
    console.log("Granting UBQ_MINTER_ROLE done!!! hash: ", receipt.transactionHash);

    return !stderr ? "succeeded" : "failed"
}
export default func;