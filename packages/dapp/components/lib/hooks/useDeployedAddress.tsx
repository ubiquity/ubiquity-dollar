import { deployedChainId, deployedContractName } from "@/components/utils/deployments";
import contractDeployments from "@ubiquity/contracts/deployments.json";
import { useNetwork } from "wagmi";

const LOCAL_CHAIN = "31337" as deployedChainId;

const useDeployedAddress = (...contractNames: deployedContractName[]) => {
  const { chain } = useNetwork();
  const chainId = (chain?.id ?? LOCAL_CHAIN) as deployedChainId;
  if (!chainId) {
    return [];
  }
  const deployedContracts = contractDeployments[chainId].contracts;
  const addresses = contractNames.map((name: deployedContractName) => deployedContracts[name].address);
  return addresses;
};

export default useDeployedAddress;
