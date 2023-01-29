import { getUbiquityDollarManagerContract } from "@/components/utils/contracts";
import { useBlockNumber } from "@usedapp/core";
import { useQuery } from "wagmi";
import useDeployedAddress from "../useDeployedAddress";
import useWeb3Provider from "../useWeb3Provider";

const useGlobalManager = () => {
  const provider = useWeb3Provider();
  const [address] = useDeployedAddress("UbiquityAlgorithmicDollarManager");
  const blockNumber = useBlockNumber();
  return useQuery(
    ["globalManager", address, blockNumber],
    async () => {
      if (!address) {
        throw new Error("Address not found");
      }
      if (!provider) {
        throw new Error("Provider not found");
      }

      const manager = getUbiquityDollarManagerContract(address, provider);

      const [[dollarTokenAddress, bondTokenAddress, debtCouponAddress, creditLineAddress], treasuryAddress, frontendAddress, backendAddress, metaPoolAddress] =
        await Promise.all([
          manager.getTokensAddresses(),
          manager.getTreasuryAddress(),
          manager.getFrontendAddress(),
          manager.getBackendAddress(),
          manager.getMetaPoolAddress(),
        ]);

      return {
        manager,
        dollarTokenAddress,
        bondTokenAddress,
        debtCouponAddress,
        creditLineAddress,
        treasuryAddress,
        frontendAddress,
        backendAddress,
        metaPoolAddress,
      };
    },
    {
      enabled: !!address && !!provider,
      retry: false,
    }
  );
};

export default useGlobalManager;
