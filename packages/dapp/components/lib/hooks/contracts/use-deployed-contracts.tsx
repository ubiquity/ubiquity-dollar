import { getDebtCouponManagerContract, getUbiquityManagerContract } from "@/components/utils/contracts";
import { useMemo } from "react";
import useWeb3Provider from "../use-web-3-provider";
import useDeployedAddress from "../use-deployed-address";

export type DeployedContracts = ReturnType<typeof useDeployedContracts> | null;
const useDeployedContracts = () => {
  const provider = useWeb3Provider();
  // cspell: disable-next-line
  const [addr1, addr2] = useDeployedAddress("Diamond", "Diamond");
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
