import { getCreditNftManagerContract, getUbiquityDollarManagerContract } from "@/components/utils/contracts";
import { useMemo } from "react";
import useDeployedAddress from "../useDeployedAddress";
import useWeb3Provider from "../useWeb3Provider";

import { getKeyFromValue } from "@/components/utils/protocol-version-safety";

export type DeployedContracts = ReturnType<typeof useDeployedContracts> | null;
const useDeployedContracts = () => {
  const provider = useWeb3Provider();
  const [globalManagerAddress, creditNftManagerAddress] = useDeployedAddress(getKeyFromValue("UbiquityDollarManager"), getKeyFromValue("CreditNftManager"));
  return useMemo(
    () =>
      globalManagerAddress && creditNftManagerAddress && provider
        ? {
            globalManager: getUbiquityDollarManagerContract(globalManagerAddress, provider),
            creditNftManager: getCreditNftManagerContract(creditNftManagerAddress, provider),
          }
        : null,
    [globalManagerAddress, creditNftManagerAddress, provider]
  );
};

export default useDeployedContracts;
