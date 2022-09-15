import { exportDeployment } from "./export";
import { execute } from "./utils/helpers/execute";
import { ForgeArguments } from "./utils/types";
export const create = async (args: ForgeArguments): Promise<any> => {
    let flattenConstructorArgs = ``;
    for (const param of args.constructorArguments) {
        flattenConstructorArgs += `${param} `;
    }

    const executeCmd = `forge create --json --rpc-url ${args.rpcUrl} --constructor-args ${flattenConstructorArgs} --private-key ${args.privateKey} ${args.contractInstance} --etherscan-api-key ${args.etherscanApiKey ? `${args.etherscanApiKey} --verify` : ``}`;
    const { stdout, stderr } = await execute(executeCmd)
    const regex = /{(?:[^{}]*|(R))*}/g;
    const found = stdout.match(regex);
    if (found) {
        const { abi } = await import(`../artifacts/${args.name}.sol/${args.name}.json`)
        const { deployedTo, deployer, transactionHash } = JSON.parse(found[0]);
        await exportDeployment(args.name, abi, deployedTo, deployer, transactionHash);
    }

    return { stdout, stderr }
}