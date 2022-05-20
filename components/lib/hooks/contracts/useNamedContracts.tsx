import { ethers } from "ethers";
import { useWeb3Provider } from "@/lib/hooks";
import { ICurveFactory__factory, DebtCouponManager__factory, YieldProxy__factory, IJar__factory, ERC20__factory } from "@/dollar-types";

import NAMED_ACCOUNTS from "@/fixtures/named-accounts.json";
import dollarDeployments from "@/fixtures/contracts-addresses/dollar.json";

export const DEBT_COUPON_MANAGER_ADDRESS = dollarDeployments[1].DebtCouponManager;

export type NamedContracts = ReturnType<typeof connectedContracts> | null;
export function connectedContracts(provider: ethers.providers.Web3Provider) {
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
  const web3Provider = useWeb3Provider();
  return web3Provider && (namedContracts || (namedContracts = connectedContracts(web3Provider)));
};

export default useNamedContracts;
