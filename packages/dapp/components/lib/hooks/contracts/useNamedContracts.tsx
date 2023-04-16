import useWeb3, { PossibleProviders } from "../useWeb3";

import Deployed_Contracts from "@ubiquity/contracts/deployments.json";
import NAMED_ACCOUNTS from "../../../config/named-accounts.json";
import { getCurveFactoryContract, getDebtCouponManagerContract, getERC20Contract, getIJarContract, getYieldProxyContract } from "@/components/utils/contracts";

const getDebtCouponManagerAddress = () => {
  const contractDeployments: Record<string, any> = Deployed_Contracts;
  const record = contractDeployments["1"] ?? {};
  const contract = record?.contracts ? record?.contracts["DebtCouponManager"] : undefined;
  return contract ? contract.address : undefined;
};
export const DEBT_COUPON_MANAGER_ADDRESS = getDebtCouponManagerAddress();

export type NamedContracts = ReturnType<typeof connectedContracts> | null;
export function connectedContracts(provider: NonNullable<PossibleProviders>) {
  return {
    curvePool: getCurveFactoryContract(NAMED_ACCOUNTS.curveFactory, provider),
    yieldProxy: getYieldProxyContract(NAMED_ACCOUNTS.yieldProxy, provider),
    usdc: getERC20Contract(NAMED_ACCOUNTS.USDC, provider),
    dai: getERC20Contract(NAMED_ACCOUNTS.DAI, provider),
    usdt: getERC20Contract(NAMED_ACCOUNTS.USDT, provider),
    debtCouponManager: getDebtCouponManagerContract(DEBT_COUPON_MANAGER_ADDRESS, provider),
    jarUsdc: getIJarContract(NAMED_ACCOUNTS.jarUSDCAddr, provider),
  };
}

let namedContracts: NamedContracts = null;
const useNamedContracts = () => {
  const { provider } = useWeb3();
  return provider && (namedContracts || (namedContracts = connectedContracts(provider)));
};

export default useNamedContracts;
