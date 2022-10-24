// @dev you need to run a build to generate these fixtures.
import contractDeployments from "@ubiquity/contracts/deployments.json";

const LOCAL_CHAIN = 31337;
const deployedContracts: Record<string, any> = contractDeployments;

const useDeployedAddress = (...names: string[]): string[] => {
  const chainId: number = typeof window === "undefined" ? null : window?.ethereum?.networkVersion || LOCAL_CHAIN;
  if (chainId) {
    const record = deployedContracts[chainId.toString()] ?? {};

    const getContractAddress = (name: string): string | undefined => {
      const contractInstance = record?.contracts ? record?.contracts[name] : undefined;
      return contractInstance?.address || undefined;
    };

    const addresses = names.map((name) => getContractAddress(name) || "");
    return addresses;
  } else {
    return [];
  }
};

export default useDeployedAddress;
