import { execute } from "../process/execute";

export type DeployArguments = {
    rpcUrl: string,
    privateKey: string,
    contractInstance: string,
    constructorArguments: string[],
    etherscanApiKey?: string,
}

export const createdAndVerify = async (args: DeployArguments) => {
    let flattenConstructorArgs = ``;
    for (const param of args.constructorArguments) {
        flattenConstructorArgs += `${param} `;
    }

    const executeCmd = `forge create --rpc-url ${args.rpcUrl} --constructor-args ${flattenConstructorArgs} --private-key ${args.privateKey} ${args.contractInstance} --etherscan-api-key ${args.etherscanApiKey ? `${args.etherscanApiKey} --verify` : ``}`;
    const { stdout, stderr } = await execute(executeCmd)
    console.log({ stdout, stderr })
}