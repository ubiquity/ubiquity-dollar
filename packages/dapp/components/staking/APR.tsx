import { BigNumber, ethers } from "ethers";
import { useEffect, useState } from "react";

import { ManagedContracts } from "@/lib/hooks/contracts/useManagerManaged";
import withLoadedContext, { LoadedContext } from "@/lib/withLoadedContext";

const toEtherNum = (n: BigNumber) => +n.toString() / 1e18;
const toNum = (n: BigNumber) => +n.toString();

const MIN_WEEKS = 1;
const MAX_WEEKS = 208;

type PrefetchedConstants = { totalShares: number; usdPerWeek: number; bondingDiscountMultiplier: BigNumber };
async function prefetchConstants(contracts: NonNullable<ManagedContracts>): Promise<PrefetchedConstants> {
  const reserves = await contracts.governanceMarket.getReserves();

  const ubqPrice = +reserves[0].toString() / +reserves[1].toString();
  const ubqPerBlock = await contracts.masterChef.uGOVPerBlock();
  const ubqMultiplier = await contracts.masterChef.uGOVmultiplier();
  const actualUbqPerBlock = toEtherNum(ubqPerBlock.mul(ubqMultiplier).div(`${1e18}`));
  const blockCountInAWeek = toNum(await contracts.staking.blockCountInAWeek());
  const ubqPerWeek = actualUbqPerBlock * blockCountInAWeek;
  const totalShares = toEtherNum(await contracts.masterChef.totalShares());
  const usdPerWeek = ubqPerWeek * ubqPrice;
  const bondingDiscountMultiplier = await contracts.staking.bondingDiscountMultiplier();
  return { totalShares, usdPerWeek, bondingDiscountMultiplier };
}

async function calculateApyForWeeks(contracts: NonNullable<ManagedContracts>, prefetch: PrefetchedConstants, weeksNum: number): Promise<number> {
  const { totalShares, usdPerWeek, bondingDiscountMultiplier } = prefetch;
  const DAYS_IN_A_YEAR = 365.2422;
  const usdAsLp = 0.7460387929; // TODO: Get this number from the Curve contract
  const bigNumberOneUsdAsLp = ethers.utils.parseEther(usdAsLp.toString());
  const weeks = BigNumber.from(weeksNum.toString());
  const shares = toEtherNum(await contracts.ubiquityFormulas.durationMultiply(bigNumberOneUsdAsLp, weeks, bondingDiscountMultiplier));
  const rewardsPerWeek = (shares / totalShares) * usdPerWeek;
  const yearlyYield = (rewardsPerWeek / 7) * DAYS_IN_A_YEAR * 100;
  return Math.round(yearlyYield * 100) / 100;
}

type APRProps = {
  weeks: string;
} & LoadedContext;

const APR = ({ managedContracts: contracts, weeks }: APRProps) => {
  const [currentApy, setCurrentApy] = useState<number | null>(null);
  const [prefetched, setPrefetched] = useState<PrefetchedConstants | null>(null);
  const [aprBounds, setApyBounds] = useState<[number, number] | null>(null);

  useEffect(() => {
    (async function () {
      const prefetched = await prefetchConstants(contracts);
      setPrefetched(prefetched);
      const [minApy, maxApy] = await Promise.all([
        calculateApyForWeeks(contracts, prefetched, MIN_WEEKS),
        calculateApyForWeeks(contracts, prefetched, MAX_WEEKS),
      ]);
      setApyBounds([minApy, maxApy]);
    })();
  }, []);

  useEffect(() => {
    (async function () {
      if (prefetched && weeks) {
        setCurrentApy(await calculateApyForWeeks(contracts, prefetched, parseInt(weeks)));
      } else {
        setCurrentApy(null);
      }
    })();
  }, [prefetched, weeks]);

  return <div>APR {currentApy ? `${currentApy}%` : aprBounds ? `${aprBounds[1]}%` : "..."}</div>;
};

export default withLoadedContext(APR);
