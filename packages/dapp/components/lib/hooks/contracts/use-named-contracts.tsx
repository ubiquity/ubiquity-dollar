import useWeb3, { PossibleProviders } from "../use-web-3";

import NAMED_ACCOUNTS from "../../../config/named-accounts.json";
import { getCurveFactoryContract, getERC20Contract, getIJarContract, getYieldProxyContract } from "@/components/utils/contracts";

export type NamedContracts = ReturnType<typeof connectedContracts> | null;
export function connectedContracts(provider: NonNullable<PossibleProviders>) {
  return {
    curvePool: getCurveFactoryContract(NAMED_ACCOUNTS.curveFactory, provider),
    yieldProxy: getYieldProxyContract(NAMED_ACCOUNTS.yieldProxy, provider),
    usdc: getERC20Contract(NAMED_ACCOUNTS.USDC, provider),
    dai: getERC20Contract(NAMED_ACCOUNTS.DAI, provider),
    usdt: getERC20Contract(NAMED_ACCOUNTS.USDT, provider),
    jarUsdc: getIJarContract(NAMED_ACCOUNTS.jarUSDCAddr, provider),
  };
}

let namedContracts: NamedContracts = null;
const useNamedContracts = () => {
  const { provider } = useWeb3();
  return provider && (namedContracts || (namedContracts = connectedContracts(provider)));
};

export default useNamedContracts;
