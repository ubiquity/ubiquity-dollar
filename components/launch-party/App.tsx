import { useEffect, useState } from "react";
import Header from "../Header";
import CustomHeader from "./Header";
import Whitelist from "./Whitelist";
import UbiquiStick from "./UbiquiStick";
import { ethers, utils } from "ethers";
import FundingPools from "./FundingPools";
import MultiplicationPool from "./MultiplicationPool";
import YourBonds, { BondData } from "./YourBonds";
import Liquidate from "./Liquidate";
import { Contracts, factories, addresses } from "./lib/contracts";
import { useConnectedContext } from "../context/connected";
import { OwnedSticks, SticksAllowance } from "./lib/types/state";
import AllowanceManager from "./AllowanceManager";
import RewardsManager from "./RewardsManager";
import { performTransaction } from "../common/utils";
import TransactionsDisplay from "../TransactionsDisplay";
import { pools, goldenPool, PoolData, PoolInfo, poolsByToken, allPools } from "./lib/pools";
import { ERC20, ERC20__factory } from "../../contracts/artifacts/types";
import { stringify } from "querystring";
import { ensureERC20Allowance } from "../common/contracts-shortcuts";

const App = () => {
  const { provider, account, updateActiveTransaction, activeTransactions, contracts: ubqContracts } = useConnectedContext();
  const [contracts, setContracts] = useState<Contracts | null>(null);
  const [tokensContracts, setTokensContracts] = useState<ERC20[]>([]);
  // const [decimalsByToken, setDecimalsByToken] = useState<{ [token: string]: number }>({});

  // Contracts loading

  useEffect(() => {
    if (!provider || !account) {
      return;
    }

    const loadContracts = async () => {
      const chainAddresses = addresses[provider.network.chainId];
      const signer = provider.getSigner();

      const simpleBond = factories.simpleBond(chainAddresses.simpleBond, provider).connect(signer);

      setContracts({
        ubiquiStick: factories.ubiquiStick(chainAddresses.ubiquiStick, provider).connect(signer),
        ubiquiStickSale: factories.ubiquiStickSale(chainAddresses.ubiquiStickSale, provider).connect(signer),
        simpleBond,
        rewardToken: ERC20__factory.connect(await simpleBond.tokenRewards(), provider).connect(signer),
      });

      setTokensContracts(allPools.map((pool) => ERC20__factory.connect(pool.tokenAddress, provider)));
    };

    loadContracts();

    // fetchTokensDecimals();
  }, [provider, account]);

  // ███████╗███████╗████████╗ ██████╗██╗  ██╗██╗███╗   ██╗ ██████╗
  // ██╔════╝██╔════╝╚══██╔══╝██╔════╝██║  ██║██║████╗  ██║██╔════╝
  // █████╗  █████╗     ██║   ██║     ███████║██║██╔██╗ ██║██║  ███╗
  // ██╔══╝  ██╔══╝     ██║   ██║     ██╔══██║██║██║╚██╗██║██║   ██║
  // ██║     ███████╗   ██║   ╚██████╗██║  ██║██║██║ ╚████║╚██████╔╝
  // ╚═╝     ╚══════╝   ╚═╝    ╚═════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝

  // async function fetchTokensDecimals() {
  //   setDecimalsByToken(
  //     await (await Promise.all(tokensContracts.map(async (tokenContract) => [tokenContract.address, await tokenContract.decimals()]))).reduce(
  //       (acc, [address, decimals]) => ({ ...acc, [address]: decimals }),
  //       {}
  //     )
  //   );
  // }

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
  const [blocksCountInAWeek, setBlocksCountInAWeek] = useState<number | null>(null);
  const [vestingBlocks, setVestingBlocks] = useState<number | null>(null);
  const [rewardTokenBalance, setRewardTokenBalance] = useState<number | null>(null);

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
      setBlocksCountInAWeek(blocksCountInAWeek);
      setVestingBlocks(vestingBlocks);
      setVestingTimeInDays(vestingBlocks / (blocksCountInAWeek / 7));
    }
  }

  const [tokensRatios, setTokensRatios] = useState<{ [token: string]: ethers.BigNumber }>({});
  const [poolsData, setPoolsData] = useState<{ [token: string]: PoolData }>({});
  const [bondsData, setBondsData] = useState<BondData[] | null>(null);

  async function refreshSimpleBondData() {
    if (isConnected && contracts && vestingTimeInDays !== null && blocksCountInAWeek !== null && vestingBlocks !== null) {
      const ratios = await Promise.all(allPools.map((pool) => contracts.simpleBond.rewardsRatio(pool.tokenAddress)));

      const newTokensRatios = Object.fromEntries(allPools.map((pool, i) => [pool.tokenAddress, ratios[i]]));

      const newPoolsData: { [token: string]: PoolData } = (
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
          decimals,
        ])
        .reduce(
          (acc, [address, poolTokenBalance, apy, decimals]) => ({
            ...acc,
            [address]: { poolTokenBalance, apy, liquidity1: 500, liquidity2: 1000, decimals },
          }),
          {}
        );

      // TODO: Get actual liquidity after we use LP contracts instead of regular ERC-20 contracts

      // Get the current bonds data

      const currentBlock = await provider.getBlockNumber();
      const bondsCount = (await contracts.simpleBond.bondsCount(account.address)).toNumber();

      const newBondsData: BondData[] = (
        await Promise.all(
          Array(bondsCount)
            .fill(null)
            .map(async (_, i) => ({
              bond: await contracts.simpleBond.bonds(account.address, i),
              rewards: await contracts.simpleBond.rewardsBondOf(account.address, i),
            }))
        )
      ).map(({ bond: { token, amount, rewards, claimed, block }, rewards: { rewardsClaimable } }) => {
        const pool = poolsByToken[token];
        const decimals = newPoolsData[token]?.decimals;
        if (!pool || !decimals) console.error("No pool found for token", token);
        return {
          tokenName: `${pool.token1}-${pool.token2}`,
          claimed: +ethers.utils.formatUnits(claimed, decimals),
          claimable: +ethers.utils.formatUnits(rewardsClaimable, decimals),
          rewards: +ethers.utils.formatUnits(rewards, decimals),
          depositAmount: +ethers.utils.formatUnits(amount, decimals),
          endsAtBlock: block.toNumber() + vestingBlocks,
          endsAtDate: new Date(+new Date() + ((block.toNumber() + vestingBlocks - currentBlock) / blocksCountInAWeek) * 7 * 24 * 60 * 60 * 1000),
          rewardPrice: 1, // TODO: Get price for each LP contract
        };
      });

      // Get the balance of the reward token

      const newRewardTokenBalance = +ethers.utils.formatUnits(await contracts.rewardToken.balanceOf(account.address), await contracts.rewardToken.decimals());

      // Set all the states

      setTokensRatios(newTokensRatios);
      setPoolsData(newPoolsData);
      setBondsData(newBondsData);
      setRewardTokenBalance(newRewardTokenBalance);
    }
  }

  useEffect(() => {
    refreshOwnerData();
    refreshUbiquistickData();
  }, [contracts]);

  useEffect(() => {
    refreshSimpleBondData();
  }, [contracts, vestingTimeInDays, blocksCountInAWeek, vestingBlocks]);

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

  const contractClaimAll = async () => {
    if (!isConnected || !isLoaded || isTransacting) return;
    updateActiveTransaction({ id: "SIMPLE_BOND_CLAIM_ALL", title: "Claiming all rewards...", active: true });
    await performTransaction(contracts.simpleBond.claim());
    updateActiveTransaction({ id: "SIMPLE_BOND_CLAIM_ALL", active: false });
    refreshSimpleBondData();
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
      <YourBonds isWhitelisted={isWhitelisted} bonds={bondsData} onClaim={contractClaimAll} />
      <Liquidate accumulated={rewardTokenBalance} />
    </div>
  );
};

export default App;
