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
import RewardsManager from "./RewardsManager";
import { performTransaction } from "../common/utils";
import TransactionsDisplay from "../TransactionsDisplay";
import { pools, goldenPool, PoolData } from "./lib/pools";
import { ERC20, ERC20__factory } from "../../contracts/artifacts/types";
import { stringify } from "querystring";
import { ensureERC20Allowance } from "../common/contracts-shortcuts";

const App = () => {
  const { provider, account, updateActiveTransaction, activeTransactions, contracts: ubqContracts } = useConnectedContext();
  const [contracts, setContracts] = useState<Contracts | null>(null);
  const [tokensContracts, setTokensContracts] = useState<ERC20[]>([]);

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
      simpleBond: factories.simpleBond(chainAddresses.simpleBond, provider).connect(signer),
    });

    const allPools = pools.concat([goldenPool]);

    setTokensContracts(allPools.map((pool) => ERC20__factory.connect(pool.tokenAddress, provider)));
  }, [provider, account]);

  // ███████╗███████╗████████╗ ██████╗██╗  ██╗██╗███╗   ██╗ ██████╗
  // ██╔════╝██╔════╝╚══██╔══╝██╔════╝██║  ██║██║████╗  ██║██╔════╝
  // █████╗  █████╗     ██║   ██║     ███████║██║██╔██╗ ██║██║  ███╗
  // ██╔══╝  ██╔══╝     ██║   ██║     ██╔══██║██║██║╚██╗██║██║   ██║
  // ██║     ███████╗   ██║   ╚██████╗██║  ██║██║██║ ╚████║╚██████╔╝
  // ╚═╝     ╚══════╝   ╚═╝    ╚═════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝

  const [isSaleContractOwner, setIsSaleContractOwner] = useState<boolean | null>(null);
  const [isSimpleBondOwner, setIsSimpleBondOwner] = useState<boolean>(false);

  async function refreshOwnerData() {
    if (!isConnected || !contracts) return;
    setIsSaleContractOwner((await contracts.ubiquiStickSale.owner()).toLowerCase() === account.address.toLowerCase());
    setIsSimpleBondOwner((await contracts.simpleBond.owner()).toLowerCase() === account.address.toLowerCase());
  }

  const [sticks, setSticks] = useState<OwnedSticks | null>(null);
  const [allowance, setAllowance] = useState<SticksAllowance | null>(null);
  const [vestingTimeInDays, setVestingTimeInDays] = useState<number | null>(null); // Milliseconds

  async function refreshUbiquistickData() {
    if (isConnected && contracts && ubqContracts) {
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

      const blocksCountInAWeek = (await ubqContracts.bonding.blockCountInAWeek()).toNumber();
      const vestingBlocks = (await contracts.simpleBond.vestingBlocks()).toNumber();
      setVestingTimeInDays(vestingBlocks / (blocksCountInAWeek / 7));
    }
  }

  const [tokensRatios, setTokensRatios] = useState<{ [token: string]: ethers.BigNumber }>({});
  const [poolsData, setPoolsData] = useState<{ [token: string]: PoolData }>({});

  async function refreshSimpleBondData() {
    if (isConnected && contracts && vestingTimeInDays !== null) {
      const allPools = pools.concat([goldenPool]);
      const ratios = await Promise.all(allPools.map((pool) => contracts.simpleBond.rewardsRatio(pool.tokenAddress)));

      const newTokensRatios = Object.fromEntries(allPools.map((pool, i) => [pool.tokenAddress, ratios[i]]));
      setTokensRatios(newTokensRatios);

      setPoolsData(
        (
          await Promise.all(
            tokensContracts.map((tokenContract) =>
              Promise.all([tokenContract.address, tokenContract.balanceOf(account.address), tokenContract.decimals(), newTokensRatios[tokenContract.address]])
            )
          )
        )
          .map(([address, balance, decimals, reward]) => [
            address,
            +ethers.utils.formatUnits(balance, decimals),
            (reward.toNumber() / 1_000_000_000 / vestingTimeInDays) * 365 * 100,
          ])
          .reduce((acc, [address, poolTokenBalance, apy]) => ({ ...acc, [address]: { poolTokenBalance, apy, liquidity1: 500, liquidity2: 1000 } }), {})
      );

      // TODO: Get actual liquidity after we use LP contracts instead of regular ERC-20 contracts
    }
  }

  useEffect(() => {
    refreshOwnerData();
    refreshUbiquistickData();
  }, [contracts]);

  useEffect(() => {
    refreshSimpleBondData();
  }, [contracts, vestingTimeInDays]);

  // ████████╗██████╗  █████╗ ███╗   ██╗███████╗ █████╗  ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
  // ╚══██╔══╝██╔══██╗██╔══██╗████╗  ██║██╔════╝██╔══██╗██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
  //    ██║   ██████╔╝███████║██╔██╗ ██║███████╗███████║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
  //    ██║   ██╔══██╗██╔══██║██║╚██╗██║╚════██║██╔══██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
  //    ██║   ██║  ██║██║  ██║██║ ╚████║███████║██║  ██║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
  //    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

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

  const contractMintUbiquistick = async () => {
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

  const contractSimpleBondSetReward = async ({ token, ratio }: { token: string; ratio: ethers.BigNumber }) => {
    if (!isConnected || !isLoaded || isTransacting) return;

    updateActiveTransaction({ id: "SIMPLE_BOND_SET_REWARD", title: "Setting reward...", active: true });
    await performTransaction(contracts.simpleBond.setRewards(token, ratio));
    updateActiveTransaction({ id: "SIMPLE_BOND_SET_REWARD", active: false });
    await refreshSimpleBondData();
  };

  const contractDepositAndBond = async ({ token, amount }: { token: string; amount: number }) => {
    console.log("DEPOSIT!", token, amount);
    if (!isConnected || !isLoaded || isTransacting || tokensContracts.length === 0) return;
    if (!token || !amount) return;
    const contract = tokensContracts.find((tc) => tc.address === token);
    if (!contract) return;
    updateActiveTransaction({ id: "DEPOSIT_AND_BOND", title: "Depositing...", active: true });
    const decimals = await contract.decimals();
    const symbol = await contract.symbol();
    const bnAmount = ethers.utils.parseUnits(amount.toString(), decimals);
    const signer = provider.getSigner();
    if (await ensureERC20Allowance(symbol, contract, bnAmount, signer, contracts.simpleBond.address, decimals)) {
      if (await performTransaction(contracts.simpleBond.bond(token, bnAmount))) {
        console.log("Deposit successful!");
        refreshSimpleBondData();
      } else {
        console.log("Deposit failed!");
      }
    } else {
      console.error("Error setting ERC20 allowance");
    }

    updateActiveTransaction({ id: "DEPOSIT_AND_BOND", active: false });
  };

  // ██████╗ ███████╗██████╗ ██╗██╗   ██╗███████╗██████╗
  // ██╔══██╗██╔════╝██╔══██╗██║██║   ██║██╔════╝██╔══██╗
  // ██║  ██║█████╗  ██████╔╝██║██║   ██║█████╗  ██║  ██║
  // ██║  ██║██╔══╝  ██╔══██╗██║╚██╗ ██╔╝██╔══╝  ██║  ██║
  // ██████╔╝███████╗██║  ██║██║ ╚████╔╝ ███████╗██████╔╝
  // ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝  ╚══════╝╚═════╝

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
      {isSimpleBondOwner ? <RewardsManager onSubmit={contractSimpleBondSetReward} ratios={tokensRatios} /> : null}
      <Whitelist isConnected={isConnected} isLoaded={isLoaded} isWhitelisted={isWhitelisted} />
      <UbiquiStick isConnected={isConnected} onBuy={contractMintUbiquistick} sticks={sticks} allowance={allowance} />
      <FundingPools isWhitelisted={isWhitelisted} poolsData={poolsData} onDeposit={contractDepositAndBond} />
      <MultiplicationPool isWhitelisted={isWhitelisted} poolsData={poolsData} onDeposit={contractDepositAndBond} />
      <YourBonds isWhitelisted={isWhitelisted} />
      <Liquidate accumulated={3500} />
    </div>
  );
};

export default App;
