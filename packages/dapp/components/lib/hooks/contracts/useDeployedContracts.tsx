import { DebtCouponManager__factory, UbiquityAlgorithmicDollarManager__factory } from "@ubiquity/dollar/artifacts/types";
import useDeployedAddress from "../useDeployedAddress";
import { PossibleProviders } from "../useWeb3";
import useWeb3Provider from "../useWeb3Provider";

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
const useDeployedContracts = () => {
  const web3Provider = useWeb3Provider();
  return web3Provider && (deployedContracts || (deployedContracts = connectedContracts(web3Provider)));
};

export default useDeployedContracts;
