import { useEffect, useState } from "react";
import Header from "../Header";
import CustomHeader from "./Header";
import Whitelist from "./Whitelist";
import UbiquiStick from "./UbiquiStick";
import { ethers, utils } from "ethers";
import FundingPools from "./FundingPools";
import MultiplicationPool from "./MultiplicationPool";
import YourBonds from "./YourBonds";
import Liquidate from "./Liquidate";
import { Contracts, factories, addresses } from "./lib/contracts";
import { useConnectedContext } from "../context/connected";
import { OwnedSticks, SticksAllowance } from "./lib/types/state";
import AllowanceManager from "./AllowanceManager";
import { performTransaction } from "../common/utils";
import TransactionsDisplay from "../TransactionsDisplay";

const App = () => {
  const { provider, account, updateActiveTransaction, activeTransactions } = useConnectedContext();
  const [contracts, setContracts] = useState<Contracts | null>(null);

  // Contracts loading

  useEffect(() => {
    if (!provider || !account) {
      return;
    }

    const chainAddresses = addresses[provider.network.chainId];
    const signer = provider.getSigner();

    setContracts({
      ubiquiStick: factories.ubiquiStick(chainAddresses.ubiquiStick, provider).connect(signer),
      ubiquiStickSale: factories.ubiquiStickSale(chainAddresses.ubiquiStickSale, provider).connect(signer),
    });
  }, [provider, account]);

  // Data fetching

  const [sticks, setSticks] = useState<OwnedSticks | null>(null);
  const [allowance, setAllowance] = useState<SticksAllowance | null>(null);
  const [isSaleContractOwner, setIsSaleContractOwner] = useState<boolean | null>(null);

  async function refreshUbiquistickData() {
    if (isConnected && contracts) {
      const newSticks: OwnedSticks = { standard: 0, gold: 0 };

      const sticksAmount = (await contracts.ubiquiStick.balanceOf(account.address)).toNumber();

      await Promise.all(
        new Array(sticksAmount).fill(0).map(async (_, i) => {
          const id = (await contracts.ubiquiStick.tokenOfOwnerByIndex(account.address, i)).toNumber();
          const isGold = await contracts.ubiquiStick.gold(id);
          if (isGold) {
            newSticks.gold += 1;
          } else {
            newSticks.standard += 1;
          }
        })
      );

      setSticks(newSticks);

      const allowance = await contracts.ubiquiStickSale.allowance(account.address);
      setAllowance({ count: +allowance.count.toString(), price: +allowance.price.toString() / 1e18 });

      const ownerAddress = await contracts.ubiquiStickSale.owner();

      setIsSaleContractOwner(ownerAddress.toLowerCase() === account.address.toLowerCase());
    }
  }

  useEffect(() => {
    refreshUbiquistickData();
  }, [contracts]);

  // Contract transactions
  const contractSetAllowance = async ({ address, count, price }: { address: string; count: string; price: string }) => {
    if (!isConnected || !isLoaded || isTransacting) return;

    if (address && count && price) {
      updateActiveTransaction({ id: "UBIQUISTICK_ALLOWANCE", title: "Setting allowance...", active: true });
      console.log(utils.parseUnits(count, "wei"));
      await performTransaction(contracts.ubiquiStickSale.setAllowance(address, utils.parseUnits(count, "wei"), utils.parseEther(price)));
      updateActiveTransaction({ id: "UBIQUISTICK_ALLOWANCE", active: false });
      await refreshUbiquistickData();
    }
  };

  const contractsMintUbiquistick = async () => {
    if (!isConnected || !isLoaded || isTransacting) return;

    updateActiveTransaction({ id: "UBIQUISTICK_MINT", title: "Minting Ubiquistick...", active: true });
    await performTransaction(
      provider.getSigner().sendTransaction({
        to: contracts.ubiquiStickSale.address,
        value: ethers.utils.parseEther(allowance.price.toString()),
      })
    );
    updateActiveTransaction({ id: "UBIQUISTICK_MINT", active: false });
    await refreshUbiquistickData();
  };

  // Derived values

  const isConnected = !!(provider && account);
  const isLoaded = !!(contracts && sticks && allowance);
  const isTransacting = activeTransactions.some((tx) => tx.active);
  const sticksCount = sticks ? sticks.gold + sticks.standard : null;
  const isWhitelisted = !!allowance && sticksCount !== null && (allowance.count > 0 || sticksCount > 0);

  return (
    <div>
      <Header section="Launch Party" href="/launch-party" />
      <TransactionsDisplay />
      <CustomHeader />
      {isSaleContractOwner ? <AllowanceManager defaultAddress={account?.address || ""} onSubmit={contractSetAllowance} /> : null}
      <Whitelist isConnected={isConnected} isLoaded={isLoaded} isWhitelisted={isWhitelisted} />
      <UbiquiStick isConnected={isConnected} onBuy={contractsMintUbiquistick} sticks={sticks} allowance={allowance} />
      <FundingPools isWhitelisted={isWhitelisted} />
      <MultiplicationPool />
      <YourBonds isWhitelisted={isWhitelisted} />
      <Liquidate accumulated={3500} />
    </div>
  );
};

export default App;
