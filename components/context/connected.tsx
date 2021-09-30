import { BigNumber, ethers, utils } from "ethers";
import { createContext, Dispatch, SetStateAction, useContext, useState, useEffect, useCallback } from "react";

import { UbiquityAlgorithmicDollarManager } from "../../contracts/artifacts/types/UbiquityAlgorithmicDollarManager";
import { EthAccount } from "../common/types";
import { connectedContracts, Contracts } from "../../contracts";
import { formatEther } from "../common/format";

export interface Balances {
  uad: BigNumber;
  crv: BigNumber;
  uad3crv: BigNumber;
  uar: BigNumber;
  ubq: BigNumber;
  bondingShares: BigNumber;
  bondingSharesLP: BigNumber;
  debtCoupon: BigNumber;
}

export interface ConnectedContext {
  manager: UbiquityAlgorithmicDollarManager | null;
  setManager: Dispatch<SetStateAction<UbiquityAlgorithmicDollarManager | null>>;
  provider: ethers.providers.Web3Provider | null;
  setProvider: Dispatch<SetStateAction<ethers.providers.Web3Provider | null>>;
  account: EthAccount | null;
  setAccount: Dispatch<SetStateAction<EthAccount | null>>;
  signer: ethers.providers.JsonRpcSigner | null;
  setSigner: Dispatch<SetStateAction<ethers.providers.JsonRpcSigner | null>>;
  balances: Balances | null;
  setBalances: Dispatch<SetStateAction<Balances | null>>;
  twapPrice: BigNumber | null;
  setTwapPrice: Dispatch<SetStateAction<BigNumber | null>>;
  contracts: Contracts | null;
  setContracts: Dispatch<SetStateAction<Contracts | null>>;
  ubqUadReserve: { uad: BigNumber; ubq: BigNumber } | null;
  ubqPrice: number | null;
}

const ConnectedContext = createContext<ConnectedContext>({} as ConnectedContext);

interface Props {
  children: React.ReactNode;
}

export const ConnectedNetwork = (props: Props): JSX.Element => {
  const [provider, setProvider] = useState<ethers.providers.Web3Provider | null>(null);
  const [signer, setSigner] = useState<ethers.providers.JsonRpcSigner | null>(null);
  const [manager, setManager] = useState<UbiquityAlgorithmicDollarManager | null>(null);
  const [account, setAccount] = useState<EthAccount | null>(null);
  const [balances, setBalances] = useState<Balances | null>(null);
  const [twapPrice, setTwapPrice] = useState<BigNumber | null>(null);
  const [contracts, setContracts] = useState<Contracts | null>(null);
  const [ubqUadReserve, setUbqUadReserve] = useState<{ uad: BigNumber; ubq: BigNumber } | null>(null);
  const [ubqPrice, setUbqPrice] = useState<number | null>(null);

  const value: ConnectedContext = {
    provider,
    setProvider,
    signer,
    setSigner,
    manager,
    setManager,
    account,
    setAccount,
    balances,
    setBalances,
    twapPrice,
    setTwapPrice,
    contracts,
    setContracts,
    ubqUadReserve,
    ubqPrice,
  };

  useEffect(() => {
    (async function () {
      console.time("Connecting contracts");
      const { provider, contracts } = await connectedContracts();
      const signer = await provider.getSigner();
      console.timeEnd("Connecting contracts");
      // (window as any).contracts = contracts;
      // (window as any).signer = signer;
      // (window as any).provider = provider;
      const toEtherNum = (n: BigNumber) => +n.toString() / 1e18;
      const toNum = (n: BigNumber) => +n.toString();

      const reserves = await contracts.ugovUadPair.getReserves();
      setUbqUadReserve({ ubq: reserves.reserve0, uad: reserves.reserve1 });
      const ubqPrice = +reserves.reserve0.toString() / +reserves.reserve1.toString();
      console.log("UBQ Price", ubqPrice);
      setUbqPrice(ubqPrice);
      const ubqPerBlock = await contracts.masterChef.uGOVPerBlock();
      const ubqMultiplier = await contracts.masterChef.uGOVmultiplier();
      const ugovDivider = toNum(await contracts.masterChef.uGOVDivider());

      console.log("UBQ per block", toEtherNum(ubqPerBlock));
      console.log("UBQ Multiplier", toEtherNum(ubqMultiplier));
      const actualUbqPerBlock = toEtherNum(ubqPerBlock.mul(ubqMultiplier).div(`${1e18}`));
      console.log("Actual UBQ per block", actualUbqPerBlock);
      console.log("Extra UBQ per block to treasury", actualUbqPerBlock / ugovDivider);
      const blockCountInAWeek = toNum(await contracts.bonding.blockCountInAWeek());
      console.log("Block count in a week", blockCountInAWeek);

      const ubqPerWeek = actualUbqPerBlock * blockCountInAWeek;
      console.log("UBQ Minted per week", ubqPerWeek);
      console.log("Extra UBQ minted per week to treasury", ubqPerWeek / ugovDivider);

      const DAYS_IN_A_YEAR = 365.2422;
      const totalShares = toEtherNum(await contracts.masterChef.totalShares());
      console.log("Total Bonding Shares", totalShares);
      const usdPerWeek = ubqPerWeek * ubqPrice;
      const usdPerDay = usdPerWeek / 7;
      const usdPerYear = usdPerDay * DAYS_IN_A_YEAR;
      console.log("USD Minted per day", usdPerDay);
      console.log("USD Minted per week", usdPerWeek);
      console.log("USD Minted per year", usdPerYear);
      const usdAsLp = 0.75;
      const bigNumberOneUsdAsLp = ethers.utils.parseEther(usdAsLp.toString());

      const bondingDiscountMultiplier = await contracts.bonding.bondingDiscountMultiplier();
      const sharesResults = await Promise.all(
        [1, 50, 100, 208].map(async (i) => {
          const weeks = BigNumber.from(i.toString());
          const shares = toEtherNum(await contracts.ubiquityFormulas.durationMultiply(bigNumberOneUsdAsLp, weeks, bondingDiscountMultiplier));
          return [i, shares];
        })
      );
      const apyResultsDisplay = sharesResults.map(([weeks, shares]) => {
        const rewardsPerWeek = (shares / totalShares) * usdPerWeek;
        const weeklyYield = rewardsPerWeek * 100;
        const yearlyYield = (rewardsPerWeek / 7) * DAYS_IN_A_YEAR * 100;
        return { lp: 1, weeks: weeks, shares: shares / usdAsLp, weeklyYield: `${weeklyYield.toPrecision(2)}%`, yearlyYield: `${yearlyYield.toPrecision(4)}%` };
      });
      console.table(apyResultsDisplay);

      setSigner(signer);
      setProvider(provider);
      setContracts(contracts);
      setManager(contracts.manager);
    })();
  }, []);

  return <ConnectedContext.Provider value={value}>{props.children}</ConnectedContext.Provider>;
};

export const useConnectedContext = (): ConnectedContext => useContext(ConnectedContext);

export type AnonContext = {
  contracts: Contracts;
  provider: ethers.providers.Web3Provider;
};

export type UserContext = {
  contracts: Contracts;
  provider: ethers.providers.Web3Provider;
  account: EthAccount;
  signer: ethers.providers.JsonRpcSigner;
};

export function useUserContractsContext(): UserContext | null {
  const { provider, account, signer, contracts } = useConnectedContext();
  if (provider && account && signer && contracts) {
    return { provider, account, signer, contracts };
  } else {
    return null;
  }
}

export function useAnonContractsContext(): AnonContext | null {
  const { provider, contracts } = useConnectedContext();
  if (provider && contracts) {
    return { provider, contracts };
  } else {
    return null;
  }
}

export function connectedWithUserContext<T>(El: (params: UserContext & T) => JSX.Element) {
  return (otherParams: T) => {
    const context = useUserContractsContext();
    return context ? <El {...context} {...otherParams} /> : null;
  };
}
