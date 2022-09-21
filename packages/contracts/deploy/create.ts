import { exportDeployment } from "./export";
import { Networks } from "./utils/constants/networks";
import { execute } from "./utils/helpers/execute";
import { ForgeArguments } from "./utils/types";
export const create = async (args: ForgeArguments): Promise<any> => {
    let flattenConstructorArgs = ``;
    for (const param of args.constructorArguments) {
        flattenConstructorArgs += `${param} `;
    }

    const chainId = Networks[args.network] ?? undefined;
    if (!chainId) {
        throw new Error(`Unsupported network: ${args.network} Please configure it out first`);
    }

    const prepareCmd = `forge create --json --rpc-url ${args.rpcUrl} --constructor-args ${flattenConstructorArgs} --private-key ${args.privateKey} ${args.contractInstance}`;
    let executeCmd: string;
    if (args.etherscanApiKey) {
        executeCmd = `${prepareCmd} --etherscan-api-key ${args.etherscanApiKey} --verify`
    } else {
        executeCmd = prepareCmd
    }
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
            await exportDeployment(args.name, chainId.toString(), args.network, abi, deployedTo, deployer, transactionHash);
        }
    }

    console.log("result: ", stdout);
    console.log("error: ", stderr);

    return { result, stderr }
}