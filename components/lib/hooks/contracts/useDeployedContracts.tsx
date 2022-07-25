import { DebtCouponManager__factory, UbiquityAlgorithmicDollarManager__factory } from "@/dollar-types";
import { useDeployedAddress, useWeb3Provider } from "@/lib/hooks";
import { PossibleProviders } from "../useWeb3";

export type DeployedContracts = ReturnType<typeof connectedContracts> | null;
export function connectedContracts(provider: NonNullable<PossibleProviders>) {
  const [addr1, addr2] = useDeployedAddress("UbiquityAlgorithmicDollarManager", "DebtCouponManager");
  return addr1 && addr2
    ? {
        manager: UbiquityAlgorithmicDollarManager__factory.connect(addr1, provider),
        debtCouponManager: DebtCouponManager__factory.connect(addr2, provider),
      }
    : null;
}

let deployedContracts: DeployedContracts = null;
const useNamedContracts = () => {
  const web3Provider = useWeb3Provider();
  return web3Provider && (deployedContracts || (deployedContracts = connectedContracts(web3Provider)));
};

export default useNamedContracts;
