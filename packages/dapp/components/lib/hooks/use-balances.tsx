import { erc1155BalanceOf } from "@/lib/utils";
import { BigNumber } from "ethers";
import { createContext, useContext, useEffect, useState } from "react";
import useNamedContracts from "./contracts/use-named-contracts";
import useWalletAddress from "./use-wallet-address";
import { ChildrenShim } from "./children-shim-d";
import useProtocolContracts from "@/components/lib/hooks/contracts/use-protocol-contracts";
import { getERC20Contract } from "@/components/utils/contracts";
import useWeb3 from "@/components/lib/hooks/use-web-3";

export interface Balances {
  uad: BigNumber;
  _3crv: BigNumber;
  uad3crv: BigNumber;
  ucr: BigNumber;
  ucrNft: BigNumber;
  ubq: BigNumber;
  stakingShares: BigNumber;
  usdc: BigNumber;
  dai: BigNumber;
  usdt: BigNumber;
}

type RefreshBalances = () => Promise<void>;

export const BalancesContext = createContext<[Balances | null, RefreshBalances]>([null, async () => {}]);

export const BalancesContextProvider: React.FC<ChildrenShim> = ({ children }) => {
  const [balances, setBalances] = useState<Balances | null>(null);
  const [walletAddress] = useWalletAddress();
  const namedContracts = useNamedContracts();
  const protocolContracts = useProtocolContracts();
  const { provider } = useWeb3();

  async function refreshBalances() {
    if (!walletAddress || !namedContracts || !protocolContracts || !provider) {
      return;
    }

    const contracts = await protocolContracts;
   
    const _3crvToken = await contracts.managerFacet!.curve3PoolTokenAddress();
    const _3crvTokenContract = getERC20Contract(_3crvToken, provider);

    const [uad, _3crv, uad3crv, ucr, ubq, ucrNft, stakingShares, usdc, dai, usdt] = await Promise.all([
      contracts.dollarToken!.balanceOf(walletAddress),
      _3crvTokenContract.balanceOf(walletAddress),
      contracts.curveMetaPoolDollarTriPoolLp!.balanceOf(walletAddress),
      contracts.creditToken!.balanceOf(walletAddress),
      contracts.governanceToken!.balanceOf(walletAddress),
      erc1155BalanceOf(walletAddress, contracts.creditNft!),
      erc1155BalanceOf(walletAddress, contracts.stakingShare!),
      namedContracts.usdc.balanceOf(walletAddress),
      namedContracts.dai.balanceOf(walletAddress),
      namedContracts.usdt.balanceOf(walletAddress),
    ]);

    setBalances({
      uad,
      _3crv,
      uad3crv,
      ucr,
      ucrNft,
      ubq,
      stakingShares,
      usdc,
      dai,
      usdt,
    });
  }

  useEffect(() => {
    refreshBalances();
  }, [walletAddress, protocolContracts]);

  return <BalancesContext.Provider value={[balances, refreshBalances]}>{children}</BalancesContext.Provider>;
};

const useBalances = () => useContext(BalancesContext);

export default useBalances;
