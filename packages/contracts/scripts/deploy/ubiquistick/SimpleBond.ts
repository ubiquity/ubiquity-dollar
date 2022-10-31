import { OptionDefinition } from "command-line-args";

import { DeployFuncParam, deployments, Networks } from "../../shared";
import { create } from "../create"
import { ethers } from "ethers";

export const optionDefinitions: OptionDefinition[] = [
    { name: 'task', defaultOption: true },
    { name: 'treasury', alias: 't', type: String },
    { name: 'vestingBlocks', alias: 'v', type: Number },
    { name: 'testenv', alias: 'v', type: Boolean },
    { name: "network", alias: 'n', type: String },
]

const func = async (params: DeployFuncParam) => {
    const contractInstance = "src/ubiquistick/SimpleBond.sol:SimpleBond";
    const { env, args } = params;
    const treasury = args.treasury;
    const vestingBlocks = args.vestingBlocks ?? 32300; // about 5 days

    const chainId = Networks[args.network] ?? undefined;
    if (!chainId) {
        throw new Error(`Unsupported network: ${args.network} Please configure it out first`);
    }
    // If testenv is true, it means that the ownership is transferred in the deployment step
    // Must be careful when you deploy contracts to the mainnets.
    const testenv = args.testenv ?? true;
    const uAR_deployments = await deployments(chainId.toString(), "UAR");


    const { result, stderr } = await create({ ...env, name: args.task, network: args.network, contractInstance, constructorArguments: [uAR_deployments.address, vestingBlocks, treasury] });
    const signer = new ethers.Wallet(env.privateKey, new ethers.providers.JsonRpcProvider(env.rpcUrl));
    const simpleBondAddress = result!.deployedTo;
    const simple_bond_deployments = await deployments(chainId.toString(), "SimpleBond");
    const ubiquity_stick_deployments = await deployments(chainId.toString(), "TheUbiquityStick");
    const simpleBondContract = new ethers.Contract(simpleBondAddress, simple_bond_deployments.abi, signer)
    console.log("Setting up the sticker...");
    let tx = await simpleBondContract.setSticker(ubiquity_stick_deployments.address);
    let receipt = await tx.wait();
    console.log("Setting up the sticker done!!!, hash: ", receipt.transactionHash);

    if (testenv) {
        console.log("Transferring the ownership of UAR to SimpleBond contract deployed recently...");
        const uARContract = new ethers.Contract(uAR_deployments.address, uAR_deployments.abi, signer);
        tx = await uARContract.transferOwnership(simpleBondAddress);
        console.log("Transferring ownership tx mined. tx: ", tx);
        receipt = await tx.wait();
        console.log("Transferring ownership done, hash: ", receipt.transactionHash);

        // TODO: Set allowance for SimpleBond to spend treasury money
    }

    return !stderr ? "succeeded" : "failed"
}
export default func;