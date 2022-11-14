import { ethers } from "ethers";
import { getSelectorsFromFacet, getContractInstance, FacetCutAction } from "./DiamondDeployHelper";
import { OptionDefinition } from "command-line-args";
import fs from "fs"
import path from "path"
import { loadEnv } from "../../shared";
import CommandLineArgs from "command-line-args"

import { Networks } from "../../shared/constants/networks";
import { ForgeArguments } from "../../shared/types";
import { execute, DeploymentResult } from "../../shared";

export const options: OptionDefinition[] = [
    { name: 'task', defaultOption: true },
    { name: 'manager', alias: 'm', type: String },
    { name: "diamondCutFacet", alias: 'c', type: String },
    { name: "network", alias: 'n', type: String },
]

export type cutType = {
    facetAddress: string,
    action: number,
    functionSelectors: string[]
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

    let provider = ethers.getDefaultProvider(args.network);
    let wallet = new ethers.Wallet(env.privateKey, provider);

    const diamondCutFacetContract = "src/diamond/facets/DiamondCutFacet.sol:DiamondCutFacet";
    const diamondContract = "src/diamond/Diamond.sol:Diamond";
    const diamondInitContract = "src/diamond/upgradeInitializers/DiamondInit.sol:DiamondInit";
    const diamondLoupeFacetContract = "src/diamond/facets/DiamondLoupeFacet.sol:DiamondLoupeFacet";
    const ownershipFacetContract = "src/diamond/facets/OwnershipFacet.sol:OwnershipFacet";

    const { stderr: diamondCutFacetError, result: diamondCutFacetResult } = await create({ ...env, name: "DiamondCutFacet", network: args.network, contractInstance: diamondCutFacetContract, constructorArguments: [] });
    if (!diamondCutFacetError && diamondCutFacetResult != undefined) {
        const { stderr: diamondError, result: diamondResult } = await create({ ...env, name: "Diamond", network: args.network, contractInstance: diamondContract, constructorArguments: [wallet.address, diamondCutFacetResult.deployedTo] });
        if (!diamondError && diamondResult != undefined) {
            const { stderr: diamondInitError, result: diamondInitResult } = await create({ ...env, name: "DiamondInit", network: args.network, contractInstance: diamondInitContract, constructorArguments: [] });
            if (!diamondInitError && diamondInitResult != undefined) {
                const { stderr: diamondLoupeFacetError, result: diamondLoupeFacetResult } = await create({ ...env, name: "DiamondLoupeFacet", network: args.network, contractInstance: diamondLoupeFacetContract, constructorArguments: [] });
                if (!diamondLoupeFacetError && diamondLoupeFacetResult != undefined) {
                    const { stderr: ownershipFacetError, result: ownershipFacetResult } = await create({ ...env, name: "OwnershipFacet", network: args.network, contractInstance: ownershipFacetContract, constructorArguments: [] });
                    if (!ownershipFacetError && ownershipFacetResult != undefined) {
                        const cut = [] as cutType[];
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

                        // add DiamondLoupeFacet and OwnershipFacet
                        cut.push(diamondLoupeFacetCut, ownershipFacetCut)

                        console.log('Diamond Cut:', cut)

                        let diamondCutFacetInstance = getContractInstance("DiamondCutFacet", wallet)
                        let diamondCut = diamondCutFacetInstance.attach(diamondResult.deployedTo);

                        let tx
                        let receipt
                        // call to init function
                        let diamondInitInstance = getContractInstance("DiamondInit")
                        let functionCall = diamondInitInstance.interface.encodeFunctionData('init')
                        // call diamondCut function
                        tx = await diamondCut.diamondCut(cut, diamondInitResult.deployedTo, functionCall)
                        console.log('Diamond cut tx: ', tx.hash)
                        receipt = await tx.wait()
                        if (!receipt.status) {
                            throw Error(`Diamond upgrade failed: ${tx.hash}`)
                        }
                        console.log('Completed diamond cut')
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