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
import { OwnedSticks, SticksAllowance } from "./lib/state";
import AllowanceManager from "./AllowanceManager";
import RewardsManager from "./RewardsManager";
import { performTransaction } from "../common/utils";
import TransactionsDisplay from "../TransactionsDisplay";
import { PoolData, poolsByToken, allPools, UnipoolData, goldenPool } from "./lib/pools";
import { ERC20, ERC20__factory } from "../../contracts/artifacts/types";
import { UniswapV3Pool__factory, UniswapV2Pair__factory } from "../../abi/types";
import { ensureERC20Allowance } from "../common/contracts-shortcuts";

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

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

    (async () => {
      const chainAddresses = addresses[provider.network.chainId];
      const signer = provider.getSigner();

      const simpleBond = factories.simpleBond(chainAddresses.simpleBond, provider).connect(signer);

      const contracts = {
        ubiquiStick: factories.ubiquiStick(chainAddresses.ubiquiStick, provider).connect(signer),
        ubiquiStickSale: factories.ubiquiStickSale(chainAddresses.ubiquiStickSale, provider).connect(signer),
        simpleBond,
        rewardToken: ERC20__factory.connect(await simpleBond.tokenRewards(), provider).connect(signer),
        chainLink: factories.chainLink(chainAddresses.chainLinkEthUsd, provider),
      };

      setContracts(contracts);
      setTokensContracts(allPools.map((pool) => ERC20__factory.connect(pool.tokenAddress, provider)));
    })();
  }, [provider, account]);

  // ███████╗███████╗████████╗ ██████╗██╗  ██╗██╗███╗   ██╗ ██████╗
  // ██╔════╝██╔════╝╚══██╔══╝██╔════╝██║  ██║██║████╗  ██║██╔════╝
  // █████╗  █████╗     ██║   ██║     ███████║██║██╔██╗ ██║██║  ███╗
  // ██╔══╝  ██╔══╝     ██║   ██║     ██╔══██║██║██║╚██╗██║██║   ██║
  // ██║     ███████╗   ██║   ╚██████╗██║  ██║██║██║ ╚████║╚██████╔╝
  // ╚═╝     ╚══════╝   ╚═╝    ╚═════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝

  async function fetchUniPoolsData(provider: ethers.providers.Web3Provider): Promise<{ [poolAddress: string]: UnipoolData }> {
    const getUniPoolFullData = async (poolAddress: string, isV2: boolean): Promise<UnipoolData> => {
      const pool = isV2 ? UniswapV2Pair__factory.connect(poolAddress, provider) : UniswapV3Pool__factory.connect(poolAddress, provider);
      const t1 = ERC20__factory.connect(await pool.token0(), provider);
      const t2 = ERC20__factory.connect(await pool.token1(), provider);
      const d1 = await t1.decimals();
      const d2 = await t2.decimals();
      const b1 = await t1.balanceOf(pool.address);
      const b2 = await t2.balanceOf(pool.address);
      return {
        poolAddress: poolAddress,
        contract1: t1,
        contract2: t2,
        token1: t1.address,
        token2: t2.address,
        decimal1: d1,
        decimal2: d2,
        balance1: b1,
        balance2: b2,
        symbol1: await t1.symbol(),
        symbol2: await t2.symbol(),
        name1: await t1.name(),
        name2: await t2.name(),
      };
    };

    const newUniPoolsData = (await Promise.all(allPools.map((pool) => getUniPoolFullData(pool.poolAddress, pool.poolAddress === pool.tokenAddress)))).reduce(
      (acc, unipoolData) => {
        return { ...acc, [unipoolData.poolAddress]: unipoolData };
      },
      {}
    );

    return newUniPoolsData;

    // console.log();
  }

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
  const [needsStick, setNeedsStick] = useState<boolean>(true);

  async function refreshSimpleBondData() {
    if (isConnected && contracts && vestingTimeInDays !== null && blocksCountInAWeek !== null && vestingBlocks !== null) {
      const ratios = await Promise.all(allPools.map((pool) => contracts.simpleBond.rewardsRatio(pool.tokenAddress)));

      const newTokensRatios = Object.fromEntries(allPools.map((pool, i) => [pool.tokenAddress, ratios[i]]));

      const newUnipoolFullData = await fetchUniPoolsData(provider);

      const newPoolsData: { [token: string]: PoolData } = (
        await Promise.all(
          tokensContracts.map((tokenContract) =>
            Promise.all([tokenContract.address, tokenContract.balanceOf(account.address), tokenContract.decimals(), newTokensRatios[tokenContract.address]])
          )
        )
      ).reduce<{ [token: string]: PoolData }>((acc, [address, balance, decimals, reward]) => {
        const poolTokenBalance = +ethers.utils.formatUnits(balance, decimals);
        const apy = (reward.toNumber() / 1_000_000_000 / 5) * 365 * 100;
        const uniPoolData = newUnipoolFullData[poolsByToken[address].poolAddress];
        const liquidity1 = +ethers.utils.formatUnits(uniPoolData.balance1, uniPoolData.decimal1);
        const liquidity2 = +ethers.utils.formatUnits(uniPoolData.balance2, uniPoolData.decimal2);

        acc[address] = {
          poolTokenBalance,
          apy,
          token1: uniPoolData.token1,
          token2: uniPoolData.token2,
          liquidity1,
          liquidity2,
          symbol1: uniPoolData.symbol1,
          symbol2: uniPoolData.symbol2,
          name1: uniPoolData.name1,
          name2: uniPoolData.name2,
          decimals,
        };

        return acc;
      }, {});

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
          tokenName: pool.name,
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

      // Get wether the Ubiquistick is still neccesary

      setNeedsStick((await contracts.simpleBond.sticker()) !== ZERO_ADDRESS);

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

  const [uarUsdPrice, setUarUsdPrice] = useState<number | null>(null);
  async function refreshPrices() {
    if (!contracts || !tokensContracts || !poolsData) return;

    const goldenPoolData = poolsData[goldenPool.tokenAddress];

    if (!goldenPoolData || !goldenPoolData.liquidity1 || !goldenPoolData.liquidity2) return;

    // Assuming golden pool is uAR-ETH
    // Example: If we have 5 uAR and 100 ETH in the pool, then we take 1 uAR = 20 ETH

    const uarEthPrice = goldenPoolData.liquidity2 / goldenPoolData.liquidity1;

    const [, price] = await contracts.chainLink.latestRoundData();
    const ethUsdPrice = +ethers.utils.formatUnits(price, "wei") / 1e8;

    console.log("ETH-USD", ethUsdPrice);
    setUarUsdPrice(ethUsdPrice * uarEthPrice);
  }
  useEffect(() => {
    refreshPrices();
  }, [contracts, tokensContracts, poolsData]);

  // ████████╗██████╗  █████╗ ███╗   ██╗███████╗ █████╗  ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
  // ╚══██╔══╝██╔══██╗██╔══██╗████╗  ██║██╔════╝██╔══██╗██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
  //    ██║   ██████╔╝███████║██╔██╗ ██║███████╗███████║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
  //    ██║   ██╔══██╗██╔══██║██║╚██╗██║╚════██║██╔══██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
  //    ██║   ██║  ██║██║  ██║██║ ╚████║███████║██║  ██║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
  //    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

  const contractSetAllowance = async (data: { address: string; count: string; price: string }[]) => {
    if (!isConnected || !isLoaded || isTransacting) return;

    updateActiveTransaction({ id: "UBIQUISTICK_ALLOWANCE", title: "Setting allowance...", active: true });
    if (data.length > 1) {
      const addresses = data.map(({ address }) => address);
      const counts = data.map(({ count }) => utils.parseUnits(count, "wei"));
      const prices = data.map(({ price }) => utils.parseEther(price));
      await performTransaction(contracts.ubiquiStickSale.batchSetAllowances(addresses, counts, prices));
    } else {
      const { address, count, price } = data[0];
      await performTransaction(contracts.ubiquiStickSale.setAllowance(address, utils.parseUnits(count, "wei"), utils.parseEther(price)));
    }
    updateActiveTransaction({ id: "UBIQUISTICK_ALLOWANCE", active: false });
    await refreshUbiquistickData();
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
  const canUsePools = (sticksCount !== null && sticksCount > 0) || !needsStick;

  return (
    <div>
      <Header section="Launch Party" href="/launch-party" />
      <TransactionsDisplay />
      <CustomHeader />
      {isSaleContractOwner ? <AllowanceManager defaultAddress={account?.address || ""} onSubmit={contractSetAllowance} /> : null}
      {isSimpleBondOwner ? <RewardsManager onSubmit={contractSimpleBondSetReward} ratios={tokensRatios} /> : null}
      <Whitelist isConnected={isConnected} isLoaded={isLoaded} isWhitelisted={isWhitelisted} />
      <UbiquiStick isConnected={isConnected} onBuy={contractMintUbiquistick} sticks={sticks} allowance={allowance} />
      <FundingPools enabled={canUsePools} poolsData={poolsData} onDeposit={contractDepositAndBond} />
      <MultiplicationPool enabled={canUsePools} poolsData={poolsData} onDeposit={contractDepositAndBond} />
      <YourBonds enabled={canUsePools} bonds={bondsData} onClaim={contractClaimAll} uarUsdPrice={uarUsdPrice} />
      <Liquidate accumulated={rewardTokenBalance} uarUsdPrice={uarUsdPrice} poolAddress={goldenPool.tokenAddress} />
    </div>
  );
};

export default App;
