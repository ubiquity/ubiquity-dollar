import UbiquityDollarDeployments from "@ubiquity/dollar/deployments.json";
import UbiquityStickDeployments from "@ubiquity/ubiquistick/deployments.json";

const _dollarDeployments = (): Record<string, any> => {
    return UbiquityDollarDeployments;
}

const _stickDeployments = (): Record<string, any> => {
    return UbiquityStickDeployments;
}

export const getDeployments = (chainId: number, contractName: string): { address: string; abi: any } | undefined => {
    const dollarRecord = _dollarDeployments()[chainId.toString()] ?? {};
    const dollarContract = dollarRecord[0]?.contracts ? dollarRecord[0]?.contracts[contractName] : undefined;
    if (dollarContract) return { address: dollarContract.address, abi: dollarContract.abi };

    const stickRecord = _stickDeployments()[chainId.toString()] ?? {};
    const stickContract = stickRecord[0]?.contract ? stickRecord[0]?.contract[contractName] : undefined;

    return stickContract ? { address: stickContract.address, abi: stickContract.abi } : undefined;

}