import fs from "fs"

const deployment_file = "deployments.json";
export const exportDeployment = async (name: string, abi: JSON, deployedTo: string, deployer: string, transactionHash: string) => {
    let deployments: any = {};
    if (!fs.existsSync(deployment_file)) {
        deployments[name] = { address: deployedTo, deployer, transactionHash, abi };
    } else {
        deployments = await import(deployment_file);
        deployments[name] = { address: deployedTo, deployer, transactionHash, abi };
    }

    fs.writeFileSync(deployment_file, JSON.stringify(deployments));

}