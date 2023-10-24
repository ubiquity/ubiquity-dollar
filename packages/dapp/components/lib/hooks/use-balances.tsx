import { erc1155BalanceOf } from "@/lib/utils";
import { createContext, useContext, useEffect, useState } from "react";
import useNamedContracts from "./contracts/use-named-contracts";
import useWalletAddress from "./use-wallet-address";
import { ChildrenShim } from "./children-shim-d";
import useProtocolContracts from "@/components/lib/hooks/contracts/use-protocol-contracts";
import useWeb3 from "@/components/lib/hooks/use-web-3";
import { Balances } from "../types";

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

    if (contracts.creditNft && contracts.stakingShare) {
      const [dollar, _3crv, dollar3crv, credit, governance, creditNft, stakingShares, usdc, dai, usdt] = await Promise.all([
        contracts.dollarToken?.balanceOf(walletAddress),
        contracts._3crvToken?.balanceOf(walletAddress),
        contracts.curveMetaPoolDollarTriPoolLp?.balanceOf(walletAddress),
        contracts.creditToken?.balanceOf(walletAddress),
        contracts.governanceToken?.balanceOf(walletAddress),
        erc1155BalanceOf(walletAddress, contracts.creditNft),
        erc1155BalanceOf(walletAddress, contracts.stakingShare),
        namedContracts.usdc.balanceOf(walletAddress),
        namedContracts.dai.balanceOf(walletAddress),
        namedContracts.usdt.balanceOf(walletAddress),
      ]);
      setBalances({
        dollar,
        _3crv,
        dollar3crv,
        credit,
        creditNft,
        governance,
        stakingShares,
        usdc,
        dai,
        usdt,
      });
    }
  }

  useEffect(() => {
    refreshBalances();
  }, [walletAddress]);

  return <BalancesContext.Provider value={[balances, refreshBalances]}>{children}</BalancesContext.Provider>;
};

const useBalances = () => useContext(BalancesContext);

export default useBalances;
