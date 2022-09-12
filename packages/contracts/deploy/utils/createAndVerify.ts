import { exec } from "child_process"
import util from "util"
const execute = util.promisify(exec);

export type DeployArguments = {
    rpcURL: string,
    privateKey: string,
    contractInstance: string,
    constructorArguments: string[],
    etherscanApiKey: string,
    verify: boolean
}

export const createdAndVerify = async (args: DeployArguments) => {
    let flattenConstructorArgs = ``;
    for (const param of args.constructorArguments) {
        flattenConstructorArgs += `${param} `;
    }

    const executeCmd = `forge create --rpc-url ${args.rpcURL} --constructor-args ${flattenConstructorArgs} --private-key ${args.privateKey} ${args.contractInstance} --etherscan-api-key ${args.etherscanApiKey} ${args.verify ? `--verify` : ''}}`;
    const { stdout, stderr } = await execute(executeCmd)
    console.log({ stdout, stderr })
}