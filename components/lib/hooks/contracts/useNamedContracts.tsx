import { DebtCouponManager__factory, ERC20__factory, ICurveFactory__factory, IJar__factory, YieldProxy__factory } from "@/dollar-types";
import useWeb3, { PossibleProviders } from "../useWeb3";

import dollarDeployments from "@/fixtures/contracts-addresses/dollar.json";
import NAMED_ACCOUNTS from "@/fixtures/named-accounts.json";

export const DEBT_COUPON_MANAGER_ADDRESS = dollarDeployments[1].DebtCouponManager;

export type NamedContracts = ReturnType<typeof connectedContracts> | null;
export function connectedContracts(provider: NonNullable<PossibleProviders>) {
  return {
    curvePool: ICurveFactory__factory.connect(NAMED_ACCOUNTS.curveFactory, provider),
    yieldProxy: YieldProxy__factory.connect(NAMED_ACCOUNTS.yieldProxy, provider),
    usdc: ERC20__factory.connect(NAMED_ACCOUNTS.USDC, provider),
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
