import { DeployFuncParam, deployments } from "../utils";
import { create } from "../create"
import { ethers } from "ethers";

export const optionDefinitions = [
    { name: 'task', defaultOption: true },
    { name: 'manager', alias: 'm', type: String },
    { name: "network", alias: 'n', type: String },
]

const func = async (params: DeployFuncParam) => {
    const contractInstance = "src/dollar/DebtCoupon.sol:DebtCoupon";
    const { env, args } = params;
    const manager = args.manager;

    const { result, stderr } = await create({ ...env, name: args.task, contractInstance, network: args.network, constructorArguments: [manager] });

    const debtCoupon = result.deployedTo;
    const uad_manager_deployments = await deployments("UbiquityAlgorithmicDollarManager");
    const signer = new ethers.Wallet(env.privateKey, new ethers.providers.JsonRpcProvider(env.rpcUrl));
    console.log("Updating debtCoupon address of UbiquityAlgorithmicDollarManager", { debtCoupon, uad_manager: uad_manager_deployments.address })
    const uad_manager_contract = new ethers.Contract(uad_manager_deployments.address, uad_manager_deployments.abi, signer)
    const tx = await uad_manager_contract.setDebtCouponAddress(debtCoupon);
    const receipt = await tx.wait();
    console.log("DebtCoupon address updated successfully!!! hash: ", receipt.transactionHash);
    return !stderr ? "succeeded" : "failed"
}
export default func;