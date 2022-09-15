import fs from "fs"
import path from "path"

const deployment_file = path.join(__dirname, "../deployments.json");
export const exportDeployment = async (name: string, abi: JSON, deployedTo: string, deployer: string, transactionHash: string) => {
    let deployments: any = {};
    if (!fs.existsSync(deployment_file)) {
        deployments[name] = { address: deployedTo, deployer, transactionHash, abi };
    } else {
        const existDeployments = await import(deployment_file);
        deployments = { ...existDeployments };
        deployments[name] = { address: deployedTo, deployer, transactionHash, abi };
    }

    fs.writeFileSync(deployment_file, JSON.stringify(deployments));

}