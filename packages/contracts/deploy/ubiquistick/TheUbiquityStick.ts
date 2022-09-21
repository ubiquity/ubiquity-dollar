import { DeployFuncParam } from "../utils";
import { create } from "../create"

export const optionDefinitions = [
    { name: 'task', defaultOption: true },
    { name: "network", alias: 'n', type: String },
]

const func = async (params: DeployFuncParam) => {
    const contractInstance = "src/ubiquistick/TheUbiquityStick.sol:TheUbiquityStick";
    const { env, args } = params;
    const { result, stderr } = await create({ ...env, name: args.task, network: args.network, contractInstance, constructorArguments: [] });

    // TODO: Do we need to set tokenURI during the deployment? For example, if we should have 10k tokens, 
    // this part will definitely be an issue to consume lots of gas. General idea is to set baseURI and others are getting generated
    // from baseURI automatically. So it might be a way to have them as a forge script.
    //
    // prev source code:  
    // 
    // await theUbiquityStick.connect(deployer).setTokenURI(0, tokenURIs.standardJson);
    // await theUbiquityStick.connect(deployer).setTokenURI(1, tokenURIs.goldJson);
    // await theUbiquityStick.connect(deployer).setTokenURI(2, tokenURIs.invisibleJson);
    return !stderr ? "succeeded" : "failed"
}
export default func;