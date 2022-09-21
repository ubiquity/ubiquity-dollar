import { DeployFuncParam, deployments, Networks } from "../../shared";
import { create } from "../create"
import { ethers } from "ethers";

export const optionDefinitions = [
    { name: 'task', defaultOption: true },
    { name: 'treasury', alias: 't', type: String },
    { name: "network", alias: 'n', type: String },
]

const func = async (params: DeployFuncParam) => {
    const contractInstance = "src/ubiquistick/TheUbiquityStickSale.sol:TheUbiquityStickSale";
    const { env, args } = params;
    const treasury = args.treasury;

    const chainId = Networks[args.network] ?? undefined;
    if (!chainId) {
        throw new Error(`Unsupported network: ${args.network} Please configure it out first`);
    }

    const { result, stderr } = await create({ ...env, name: args.task, network: args.network, contractInstance, constructorArguments: [] });

    const signer = new ethers.Wallet(env.privateKey, new ethers.providers.JsonRpcProvider(env.rpcUrl));
    const ubiquityStickSaleAddress = result.deployedTo;
    const ubiquitystick_deployments = await deployments(chainId.toString(), "TheUbiquityStick");
    const ubiquityStickContract = new ethers.Contract(ubiquitystick_deployments.address, ubiquitystick_deployments.abi, signer)
    console.log("Granting minter role to TheUbiquityStickSale contract...");
    let tx = await ubiquityStickContract.setMinter(ubiquityStickSaleAddress);
    let receipt = await tx.wait();
    console.log("Granting minter role to TheUbiquityStickSale contract done!!!, hash: ", receipt.transactionHash);

    console.log("Setting up funds address and token contract...");
    const ubiquitysticksale_deployments = await deployments(chainId.toString(), "TheUbiquityStickSale");
    const ubiquityStickSaleConract = new ethers.Contract(ubiquityStickSaleAddress, ubiquitysticksale_deployments.abi, signer);
    tx = await ubiquityStickSaleConract.setFundsAddress(treasury);
    console.log("Setting funds address tx mined, tx: ", tx);
    receipt = await tx.wait();
    console.log("Setting funds address done, hash: ", receipt.transactionHash);

    tx = await ubiquityStickSaleConract.setTokenContract(ubiquitystick_deployments.address);
    console.log("Setting token address tx mined, tx: ", tx);
    receipt = await tx.wait();
    console.log("Setting token address done, hash: ", receipt.transactionHash);
    return !stderr ? "succeeded" : "failed"
}
export default func;