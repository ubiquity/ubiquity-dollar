import fs from "fs"
import path from "path"

const deployment_file = path.join(__dirname, "../deployments.json");
export const exportDeployment = async (name: string, chainId: string, network: string, abi: JSON, deployedTo: string, deployer: string, transactionHash: string) => {
    let deployments: any = {};
    if (!fs.existsSync(deployment_file)) {
        const contracts: any = {}
        contracts[name] = { address: deployedTo, deployer, transactionHash, abi };
        deployments[chainId] = {
            name: network,
            chainId,
            contracts
        }
    } else {
        const existDeployments = await import(deployment_file);

        console.log({ existDeployments });
        deployments = existDeployments.default;
        console.log({ deployments });
        const deployments_for_chain: any = deployments[chainId] ?? {};
        const contracts: any = deployments_for_chain["contracts"] ?? {}
        contracts[name] = { address: deployedTo, deployer, transactionHash, abi };

        deployments[chainId]["contracts"] = contracts;
    }
    console.log({ deployments });
    fs.writeFileSync(deployment_file, JSON.stringify(deployments));
}