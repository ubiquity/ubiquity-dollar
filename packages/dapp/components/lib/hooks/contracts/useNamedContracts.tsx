import useWeb3, { PossibleProviders } from "../useWeb3";

import allDeployments from "@ubiquity/contracts/deployments.json";
import addresses from "../../../config/named-accounts.json";
import { getCreditNftManagerContract, getERC20Contract } from "@/components/utils/contracts";
import { getCurveFactoryContract, getIJarContract } from "@/components/utils/contracts-external";
import { deployedChainId } from "@/components/utils/deployments";
import { getKeyFromValue } from "@/components/utils/protocol-version-safety";

const getCreditNftManager = () => {
  const chainId = "1" as deployedChainId;
  const mainnetDeployment = allDeployments[chainId];
  if (!mainnetDeployment) {
    throw new Error(`Mainnet deployment contracts artifact not found`);
  }
  // throw new Error(`No CreditNftManager in deployments artifact`);
  const contracts = mainnetDeployment.contracts;

  const newKey = getKeyFromValue("CreditNftManager");

  return contracts[newKey].address;
  // @FIXME: update deployment script
};

export type NamedContracts = ReturnType<typeof connectedContracts> | null;
export function connectedContracts(provider: NonNullable<PossibleProviders>) {
  return {
    curvePool: getCurveFactoryContract(addresses.curveFactory, provider),
    usdc: getERC20Contract(addresses.USDC, provider),
    dai: getERC20Contract(addresses.DAI, provider),
    usdt: getERC20Contract(addresses.USDT, provider),
    creditNftManager: getCreditNftManagerContract(getCreditNftManager(), provider),
    jarUsdc: getIJarContract(addresses.jarUSDCAddr, provider),
  };
}

let namedContracts: NamedContracts = null;
const useNamedContracts = () => {
  const [{ provider }] = useWeb3();
  return provider && (namedContracts || (namedContracts = connectedContracts(provider)));
};

export default useNamedContracts;
