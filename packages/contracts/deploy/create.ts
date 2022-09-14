import { execute } from "./utils/helpers/execute";
import { ForgeArguments } from "./utils/types";

export const create = async (args: ForgeArguments) => {
    let flattenConstructorArgs = ``;
    for (const param of args.constructorArguments) {
        flattenConstructorArgs += `${param} `;
    }

    const executeCmd = `forge create --rpc-url ${args.rpcUrl} --constructor-args ${flattenConstructorArgs} --private-key ${args.privateKey} ${args.contractInstance} --etherscan-api-key ${args.etherscanApiKey ? `${args.etherscanApiKey} --verify` : ``}`;
    const { stdout, stderr } = await execute(executeCmd)
    console.log({ stdout, stderr })
}