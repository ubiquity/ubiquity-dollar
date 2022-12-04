import { ethers } from "ethers";
import { getSelectorsFromFacet, getContractInstance, FacetCutAction } from "./DiamondDeployHelper";
import { OptionDefinition } from "command-line-args";
import fs from "fs"
import path from "path"
import { loadEnv } from "../../shared";
import CommandLineArgs from "command-line-args"

import { Networks } from "../../shared/constants/networks";
import { execute, DeploymentResult } from "../../shared";

export const options: OptionDefinition[] = [
    { name: 'task', defaultOption: true },
    { name: 'manager', alias: 'm', type: String },
    { name: "network", alias: 'n', type: String },
]

export type cutType = {
    facetAddress: string,
    action: number,
    functionSelectors: string[]
}

export type DiamondArgs = {
    owner: string,
    init: string,
    initCalldata: string
}

export type ForgeArguments = {
    name: string,
    network: string,
    rpcUrl: string,
    privateKey: string,
    contractInstance: string,
    constructorArguments: [DiamondArgs, cutType[]] | string[],
    etherscanApiKey?: string,
}

const create = async (args: ForgeArguments): Promise<{ result: DeploymentResult | undefined, stderr: string }> => {
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
            const { deployedTo, deployer, transactionHash } = JSON.parse(found[0]);
            result = { deployedTo, deployer, transactionHash };
            console.log(`Deployed ${args.name} contract successfully. res: ${deployedTo}`);
        }
    }
    return { result, stderr }
}

async function deployDiamond() {
    const envPath = path.join(__dirname, "../../../.env");
    if (!fs.existsSync(envPath)) {
        throw new Error("Env file not found")
    }
    const env = loadEnv(envPath);

    let args;
    try {
        args = CommandLineArgs(options);
    } catch (error: any) {
        console.error(`Argument parse failed!, error: ${error}`)
        return;
    }

    let provider = ethers.getDefaultProvider(args.network, { etherscan: env.etherscanApiKey });
    let wallet = new ethers.Wallet(env.privateKey, provider);

    const diamondCutFacetContract = "src/manager/facets/DiamondCutFacet.sol:DiamondCutFacet";
    const diamondContract = "src/manager/Diamond.sol:Diamond";
    const diamondInitContract = "src/manager/upgradeInitializers/DiamondInit.sol:DiamondInit";
    const diamondLoupeFacetContract = "src/manager/facets/DiamondLoupeFacet.sol:DiamondLoupeFacet";
    const ownershipFacetContract = "src/manager/facets/OwnershipFacet.sol:OwnershipFacet";
    const managerFacetContract = "src/manager/facets/ManagerFacet.sol:ManagerFacet";

    const { stderr: diamondCutFacetError, result: diamondCutFacetResult } = await create({ ...env, name: "DiamondCutFacet", network: args.network, contractInstance: diamondCutFacetContract, constructorArguments: [] });
    if (!diamondCutFacetError && diamondCutFacetResult != undefined) {
        const { stderr: diamondInitError, result: diamondInitResult } = await create({ ...env, name: "DiamondInit", network: args.network, contractInstance: diamondInitContract, constructorArguments: [] });
        if (!diamondInitError && diamondInitResult != undefined) {
            const { stderr: diamondLoupeFacetError, result: diamondLoupeFacetResult } = await create({ ...env, name: "DiamondLoupeFacet", network: args.network, contractInstance: diamondLoupeFacetContract, constructorArguments: [] });
            if (!diamondLoupeFacetError && diamondLoupeFacetResult != undefined) {
                const { stderr: ownershipFacetError, result: ownershipFacetResult } = await create({ ...env, name: "OwnershipFacet", network: args.network, contractInstance: ownershipFacetContract, constructorArguments: [] });
                if (!ownershipFacetError && ownershipFacetResult != undefined) {
                    const { stderr: managerFacetError, result: managerFacetResult } = await create({ ...env, name: "ManagerFacet", network: args.network, contractInstance: managerFacetContract, constructorArguments: [] });
                    if (!managerFacetError && managerFacetResult != undefined) {
                        const cut = [] as cutType[];
                        const diamondCutFacetCut = {
                            facetAddress: diamondCutFacetResult.deployedTo,
                            action: FacetCutAction.Add,
                            functionSelectors: await getSelectorsFromFacet("DiamondCutFacet")
                        }
                        const diamondLoupeFacetCut = {
                            facetAddress: diamondLoupeFacetResult.deployedTo,
                            action: FacetCutAction.Add,
                            functionSelectors: await getSelectorsFromFacet("DiamondLoupeFacet")
                        }
                        const ownershipFacetCut = {
                            facetAddress: ownershipFacetResult.deployedTo,
                            action: FacetCutAction.Add,
                            functionSelectors: await getSelectorsFromFacet("OwnershipFacet")
                        }
                        const managerFacetCut = {
                            facetAddress: managerFacetResult.deployedTo,
                            action: FacetCutAction.Add,
                            functionSelectors: await getSelectorsFromFacet("ManagerFacet")
                        }

                        // add DiamondCutFacetCut DiamondLoupeFacet, OwnershipFacet and ManagerFacet
                        cut.push(diamondCutFacetCut, diamondLoupeFacetCut, ownershipFacetCut, managerFacetCut)

                        console.log('Diamond Cut:', cut)

                        // call to init function
                        let diamondInitInstance = getContractInstance("DiamondInit")
                        let functionCall = diamondInitInstance.interface.encodeFunctionData('init(address)', [wallet.address])
                        // call diamondCut function
                        let DiamondArgs = {
                            owner: wallet.address,
                            init: diamondInitResult.deployedTo,
                            initCalldata: functionCall
                        }
                        const { stderr: diamondError, result: diamondResult } = await create({ ...env, name: "Diamond", network: args.network, contractInstance: diamondContract, constructorArguments: [DiamondArgs, cut] });
                        if (!diamondError && diamondResult != undefined) {
                            console.log('Completed diamond deployment!!!')
                        } else {
                            console.log('diamondError', diamondError)
                        }
                    }
                }
            }
        }
    }
}

deployDiamond()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });