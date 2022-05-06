import { ethers } from "ethers";
import { useWeb3Provider, useDeployedAddress } from "@/lib/hooks";
import { UbiquityAlgorithmicDollarManager__factory, DebtCouponManager__factory } from "@/dollar-types";

export type DeployedContracts = ReturnType<typeof connectedContracts> | null;
export function connectedContracts(provider: ethers.providers.Web3Provider) {
  const [addr1, addr2] = useDeployedAddress("UbiquityAlgorithmicDollarManager", "DebtCouponManager");
  return {
    manager: UbiquityAlgorithmicDollarManager__factory.connect(addr1, provider),
    debtCouponManager: DebtCouponManager__factory.connect(addr2, provider),
  };
}

let deployedContracts: DeployedContracts = null;
const useNamedContracts = () => {
  const web3Provider = useWeb3Provider();
  return web3Provider && (deployedContracts || (deployedContracts = connectedContracts(web3Provider)));
};

export default useNamedContracts;
