import { exportDeployment } from "./export";
import { execute } from "./utils/helpers/execute";
import { ForgeArguments } from "./utils/types";
export const create = async (args: ForgeArguments): Promise<any> => {
    let flattenConstructorArgs = ``;
    for (const param of args.constructorArguments) {
        flattenConstructorArgs += `${param} `;
    }

    const executeCmd = `forge create --json --rpc-url ${args.rpcUrl} --constructor-args ${flattenConstructorArgs} --private-key ${args.privateKey} ${args.contractInstance} --etherscan-api-key ${args.etherscanApiKey ? `${args.etherscanApiKey} --verify` : ``}`;
    let stdout;
    let stderr;
    let result: any = {};
    try {
        const { stdout: _stdout, stderr: _stderr } = await execute(executeCmd)
        stdout = _stdout;
        stderr = _stderr;
    } catch (err: any) {
        console.log(err);
        stdout = err?.stdout;
        stderr = err?.stderr;
    }
    if (stdout) {
        const regex = /{(?:[^{}]*|(R))*}/g;
        const found = stdout.match(regex);
        if (found && JSON.parse(found[0])?.deployedTo) {
            const { abi } = await import(`../artifacts/${args.name}.sol/${args.name}.json`)
            const { deployedTo, deployer, transactionHash } = JSON.parse(found[0]);
            result = { deployedTo, deployer, transactionHash };
            await exportDeployment(args.name, abi, deployedTo, deployer, transactionHash);
        }
    }

    console.log("result: ", stdout);
    console.log("error: ", stderr);

    return { result, stderr }
}