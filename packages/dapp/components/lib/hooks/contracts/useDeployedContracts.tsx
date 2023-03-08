import { getDebtCouponManagerContract, getUbiquityManagerContract } from "@/components/utils/contracts";
import { useMemo } from "react";
import useDeployedAddress from "../useDeployedAddress";
import useWeb3Provider from "../useWeb3Provider";

export type DeployedContracts = ReturnType<typeof useDeployedContracts> | null;
const useDeployedContracts = () => {
  const provider = useWeb3Provider();
  // cspell: disable-next-line
  const [addr1, addr2] = useDeployedAddress("UbiquityAlgorithmicDollarManager", "DebtCouponManager");
  return useMemo(
    () =>
      addr1 && addr2 && provider
        ? {
            manager: getUbiquityManagerContract(addr1, provider),
            debtCouponManager: getDebtCouponManagerContract(addr2, provider),
          }
        : null,
    [addr1, addr2, provider]
  );
};

export default useDeployedContracts;
