import { DebtCouponManager__factory, ERC20__factory, ICurveFactory__factory, IJar__factory, YieldProxy__factory } from "@ubiquity/dollar/artifacts/types";
import useWeb3, { PossibleProviders } from "../useWeb3";

import DollarDeployments from "@ubiquity/dollar/deployments.json";
import NAMED_ACCOUNTS from "../../../config/named-accounts.json";

const getDebtCouponManagerAddress = () => {
  const contractDeployments: Record<string, any> = DollarDeployments;
  const record = contractDeployments["1"] ?? {};
  const contract = record[0]?.contracts ? record[0]?.contracts["DebtCouponManager"] : undefined;
  return contract ? contract.address : undefined
}
export const DEBT_COUPON_MANAGER_ADDRESS = getDebtCouponManagerAddress();

export type NamedContracts = ReturnType<typeof connectedContracts> | null;
export function connectedContracts(provider: NonNullable<PossibleProviders>) {
  return {
    curvePool: ICurveFactory__factory.connect(NAMED_ACCOUNTS.curveFactory, provider),
    yieldProxy: YieldProxy__factory.connect(NAMED_ACCOUNTS.yieldProxy, provider),
    usdc: ERC20__factory.connect(NAMED_ACCOUNTS.USDC, provider),
    dai: ERC20__factory.connect(NAMED_ACCOUNTS.DAI, provider),
    usdt: ERC20__factory.connect(NAMED_ACCOUNTS.USDT, provider),
    debtCouponManager: DebtCouponManager__factory.connect(DEBT_COUPON_MANAGER_ADDRESS, provider),
    jarUsdc: IJar__factory.connect(NAMED_ACCOUNTS.jarUSDCAddr, provider),
  };
}

let namedContracts: NamedContracts = null;
const useNamedContracts = () => {
  const [{ provider }] = useWeb3();
  return provider && (namedContracts || (namedContracts = connectedContracts(provider)));
};

export default useNamedContracts;
