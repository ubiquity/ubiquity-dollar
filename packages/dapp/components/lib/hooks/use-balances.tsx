import { erc1155BalanceOf } from "@/lib/utils";
import { createContext, useContext, useEffect, useState } from "react";
import useManagerManaged from "./contracts/use-manager-managed";
import useNamedContracts from "./contracts/use-named-contracts";
import useWalletAddress from "./use-wallet-address";
import { ChildrenShim } from "./children-shim-d";
import { Balances } from "../types";


type RefreshBalances = () => Promise<void>;

export const BalancesContext = createContext<[Balances | null, RefreshBalances]>([null, async () => {}]);

export const BalancesContextProvider: React.FC<ChildrenShim> = ({ children }) => {
  const [balances, setBalances] = useState<Balances | null>(null);
  const [walletAddress] = useWalletAddress();
  const managedContracts = useManagerManaged();
  const namedContracts = useNamedContracts();

  async function refreshBalances() {
    if (walletAddress && managedContracts && namedContracts) {
      const [uad, _3crv, uad3crv, ucr, ubq, ucrNft, stakingShares, usdc, dai, usdt] = await Promise.all([
        managedContracts.dollarToken.balanceOf(walletAddress),
        managedContracts._3crvToken.balanceOf(walletAddress),
        managedContracts.dollarMetapool.balanceOf(walletAddress),
        managedContracts.creditToken.balanceOf(walletAddress),
        managedContracts.governanceToken.balanceOf(walletAddress),
        erc1155BalanceOf(walletAddress, managedContracts.creditNft),
        erc1155BalanceOf(walletAddress, managedContracts.stakingToken),
        (await namedContracts).usdc.balanceOf(walletAddress),
        (await namedContracts).dai.balanceOf(walletAddress,),
        (await namedContracts).usdt.balanceOf(walletAddress),
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
  }

  useEffect(() => {
    refreshBalances();
  }, [walletAddress, managedContracts]);

  return <BalancesContext.Provider value={[balances, refreshBalances]}>{children}</BalancesContext.Provider>;
};

const useBalances = () => useContext(BalancesContext);

export default useBalances;
