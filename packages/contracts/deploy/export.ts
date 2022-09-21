import fs from "fs"
import path from "path"

const deployment_file = path.join(__dirname, "../deployments.json");
export const exportDeployment = async (name: string, chainId: string, network: string, abi: JSON, deployedTo: string, deployer: string, transactionHash: string) => {
    let deployments: any = {};
    if (!fs.existsSync(deployment_file)) {
        const contracts: any = {}
        contracts[name] = { address: deployedTo, deployer, transactionHash, abi };
        const deployments_for_chain: any = {};
        deployments_for_chain[chainId] = {
            name: network,
            chainId,
            contracts
        }
        deployments[chainId] = deployments_for_chain;
    } else {
        const existDeployments = await import(deployment_file);

        console.log({ existDeployments });
        deployments = existDeployments.default;
        console.log({ deployments });
        const deployments_for_chain: any = deployments[chainId] ?? {};
        deployments_for_chain[name] = { address: deployedTo, deployer, transactionHash, abi };

        deployments[chainId] = deployments_for_chain;
    }
    console.log({ deployments });
    fs.writeFileSync(deployment_file, JSON.stringify(deployments));
}