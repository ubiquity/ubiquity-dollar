import { exportDeployment } from "./export";
import { Networks } from "../shared/constants/networks";
import { ForgeArguments } from "../shared/types";
import { execute, DeploymentResult } from "../shared";


export const create = async (args: ForgeArguments): Promise<{ result: DeploymentResult | undefined, stderr: string }> => {
    let flattenConstructorArgs = ``;
    let prepareCmd: string;
    if (args.constructorArguments.length !== 0) {
        for (const param of args.constructorArguments) {
            flattenConstructorArgs += `${param} `;
        }
        prepareCmd = `forge create --json --rpc-url ${args.rpcUrl} --constructor-args ${flattenConstructorArgs} --private-key ${args.privateKey} ${args.contractInstance}`;
    } else {
        prepareCmd = `forge create --json --rpc-url ${args.rpcUrl} --private-key ${args.privateKey} ${args.contractInstance}`;
    }

    const chainId = Networks[args.network] ?? undefined;
    if (!chainId) {
        throw new Error(`Unsupported network: ${args.network} Please configure it out first`);
    }

    let executeCmd: string;
    if (args.etherscanApiKey) {
        executeCmd = `${prepareCmd} --etherscan-api-key ${args.etherscanApiKey} --verify`
    } else {
        executeCmd = prepareCmd
    }
    let stdout;
    let stderr: string;
    let result: DeploymentResult | undefined;

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
            const { abi } = await import(`../out/${args.name}.sol/${args.name}.json`)
            const { deployedTo, deployer, transactionHash } = JSON.parse(found[0]);
            result = { deployedTo, deployer, transactionHash };
            await exportDeployment(args.name, chainId.toString(), args.network, abi, deployedTo, deployer, transactionHash);
        }
    }

    console.log("result: ", stdout);
    console.log("error: ", stderr);

    return { result, stderr }
}