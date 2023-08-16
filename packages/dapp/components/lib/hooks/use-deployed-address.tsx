//@dev you need to run a build to generate these fixtures.
import contractDeployments from "@ubiquity/contracts/deployments.json";
import { useNetwork } from "wagmi";

const LOCAL_CHAIN = 31337;
const deployedContracts: Record<string, any> = contractDeployments;

const getContractAddress = (record: Record<string, any>, name: string): string | undefined => {
  const contractInstance = record.contracts?.[name];
  return contractInstance?.address;
};

const useDeployedAddress = (...names: string[]): string[] => {
  const { chain } = useNetwork();
  const chainId: number = chain?.id || LOCAL_CHAIN;

  if (!chainId) {
    return [];
  }

  const record = deployedContracts[chainId.toString()] || {};
  const addresses = names.map((name) => getContractAddress(record, name) || "");
  return addresses;
};

export default useDeployedAddress;
