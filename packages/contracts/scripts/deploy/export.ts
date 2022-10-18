import fs from "fs"
import path from "path"
import { ChainDeployments, ContractDeployments, DeploymentsForChain } from "../shared";

const deployment_file = path.join(__dirname, "../deployments.json");
export const exportDeployment = async (name: string, chainId: string, network: string, abi: JSON, deployedTo: string, deployer: string, transactionHash: string) => {
    let deployments: ChainDeployments = {};
    if (!fs.existsSync(deployment_file)) {
        const contracts: ContractDeployments = {}
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
        const deployments_for_chain: DeploymentsForChain = deployments[chainId] ?? {};
        const contracts: ContractDeployments = deployments_for_chain["contracts"] ?? {}
        contracts[name] = { address: deployedTo, deployer, transactionHash, abi };

        deployments[chainId]["contracts"] = contracts;
    }
    console.log({ deployments });
    fs.writeFileSync(deployment_file, JSON.stringify(deployments));
}