import { BigNumber, ethers } from "ethers";
import { useEffect, useState } from "react";

import { ManagedContracts } from "@/lib/hooks/contracts/use-manager-managed";
import { constrainNumber } from "@/lib/utils";
import withLoadedContext, { LoadedContext } from "@/lib/with-loaded-context";
import Button from "../ui/_button";
import PositiveNumberInput from "../ui/positive-number-input";

const toEtherNum = (n: BigNumber) => +n.toString() / 1e18;
const toNum = (n: BigNumber) => +n.toString();

const MIN_WEEKS = 1;
const MAX_WEEKS = 208;

// cspell: disable-next-line
type PrefetchedConstants = { totalShares: number; usdPerWeek: number; bondingDiscountMultiplier: BigNumber };
async function prefetchConstants(contracts: NonNullable<ManagedContracts>): Promise<PrefetchedConstants> {
  const reserves = await contracts.governanceMarket.getReserves();

  const ubqPrice = +reserves[0].toString() / +reserves[1].toString();
  const ubqPerBlock = await contracts.masterChef.governancePerBlock();
  const ubqMultiplier = await contracts.masterChef.governanceMultiplier();
  const actualUbqPerBlock = toEtherNum(ubqPerBlock.mul(ubqMultiplier).div(`${1e18}`));
  const blockCountInAWeek = toNum(await contracts.staking.blockCountInAWeek());
  const ubqPerWeek = actualUbqPerBlock * blockCountInAWeek;
  const totalShares = toEtherNum(await contracts.masterChef.totalShares());
  const usdPerWeek = ubqPerWeek * ubqPrice;
  // cspell: disable-next-line
  const bondingDiscountMultiplier = await contracts.staking.stakingDiscountMultiplier();
  // cspell: disable-next-line
  return { totalShares, usdPerWeek, bondingDiscountMultiplier };
}

async function calculateApyForWeeks(contracts: NonNullable<ManagedContracts>, prefetch: PrefetchedConstants, weeksNum: number): Promise<number> {
  // cspell: disable-next-line
  const { totalShares, usdPerWeek, bondingDiscountMultiplier } = prefetch;
  const DAYS_IN_A_YEAR = 365.2422;
  const usdAsLp = 0.7460387929; // TODO: Get this number from the Curve contract
  const bigNumberOneUsdAsLp = ethers.utils.parseEther(usdAsLp.toString());
  const weeks = BigNumber.from(weeksNum.toString());
  // cspell: disable-next-line
  const shares = toEtherNum(await contracts.ubiquityFormulas.durationMultiply(bigNumberOneUsdAsLp, weeks, bondingDiscountMultiplier));
  const rewardsPerWeek = (shares / totalShares) * usdPerWeek;
  const yearlyYield = (rewardsPerWeek / 7) * DAYS_IN_A_YEAR * 100;
  return Math.round(yearlyYield * 100) / 100;
}

type DepositShareProps = {
  onStake: ({ amount, weeks }: { amount: BigNumber; weeks: BigNumber }) => void;
  disabled: boolean;
  maxLp: BigNumber;
} & LoadedContext;

const DepositShare = ({ onStake, disabled, maxLp, managedContracts: contracts }: DepositShareProps) => {
  const [amount, setAmount] = useState("");
  const [weeks, setWeeks] = useState("");
  const [currentApy, setCurrentApy] = useState<number | null>(null);
  const [prefetched, setPrefetched] = useState<PrefetchedConstants | null>(null);
  const [aprBounds, setApyBounds] = useState<[number, number] | null>(null);

  function validateAmount(): string | null {
    if (amount) {
      const amountBig = ethers.utils.parseEther(amount);
      if (amountBig.gt(maxLp)) return `You don't have enough uAD-3CRV tokens`;
    }
    return null;
  }

  const error = validateAmount();
  const hasErrors = !!error;

  const onWeeksChange = (inputVal: string) => {
    setWeeks(inputVal && constrainNumber(parseInt(inputVal), MIN_WEEKS, MAX_WEEKS).toString());
  };

  const onAmountChange = (inputVal: string) => {
    setAmount(inputVal);
  };

  const onClickStake = () => {
    onStake({ amount: ethers.utils.parseEther(amount), weeks: BigNumber.from(weeks) });
  };

  const onClickMax = () => {
    setAmount(ethers.utils.formatEther(maxLp));
    setWeeks(MAX_WEEKS.toString());
  };

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

  const noInputYet = !amount || !weeks;
  const amountParsed = parseFloat(amount);

  return (
    <div className="panel">
      {/* cspell: disable-next-line */}
      <h2>Stake liquidity to receive UBQ</h2>
      <div>APR {currentApy ? `${currentApy}%` : aprBounds ? `${aprBounds[1]}%` : "..."}</div>
      <div>
        <PositiveNumberInput value={amount} onChange={onAmountChange} disabled={disabled} placeholder="uAD-3CRV LP Tokens" />
        <PositiveNumberInput value={weeks} fraction={false} onChange={onWeeksChange} disabled={disabled} placeholder={`Weeks (${MIN_WEEKS}-${MAX_WEEKS})`} />
        <Button disabled={disabled} onClick={onClickMax}>
          MAX
        </Button>
        <Button disabled={disabled || hasErrors || noInputYet || !amountParsed} onClick={onClickStake}>
          Stake LP Tokens
        </Button>
      </div>
      <div>{error && <p>{error}</p>}</div>
    </div>
  );
};

export default withLoadedContext(DepositShare);
