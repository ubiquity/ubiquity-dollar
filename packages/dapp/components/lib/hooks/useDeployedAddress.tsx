// @dev you need to run a build to generate these fixtures.
import contractDeployments from "@ubiquity/contracts/deployments.json";
import { useNetwork } from "wagmi";

const LOCAL_CHAIN = 31337;
const deployedContracts: Record<string, any> = contractDeployments;

const useDeployedAddress = (...names: string[]): string[] => {
  const { chain } = useNetwork();
  const chainId: number = chain?.id || LOCAL_CHAIN;
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
