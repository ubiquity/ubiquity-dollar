import { BigNumber, ethers } from "ethers";
import { ChangeEvent, memo, useState, useCallback, useEffect } from "react";
import { connectedWithUserContext, UserContext } from "./context/connected";
import { formatEther } from "./common/format";
import { useAsyncInit, performTransaction } from "./common/utils";
import { Contracts } from "../contracts";
import * as widget from "./ui/widget";
import { UBQIcon, LiquidIcon } from "./ui/icons";

type ShareData = {
  id: number;
  ugov: BigNumber;
  bond: {
    minter: string;
    lpFirstDeposited: BigNumber;
    creationBlock: BigNumber;
    lpRewardDebt: BigNumber;
    endBlock: BigNumber;
    lpAmount: BigNumber;
  };
  sharesBalance: BigNumber;
  weeksLeft: number;
};

type Model = {
  shares: ShareData[];
  totalShares: BigNumber;
  walletLpBalance: BigNumber;
  processing: boolean;
};

type Actions = {
  onWithdrawLp: (payload: { id: number; amount: null | number }) => void;
  onClaimUbq: (id: number) => void;
  onStake: (payload: { amount: number; weeks: number }) => void;
};

export const BondingSharesExplorerContainer = ({ contracts, provider, account, signer }: UserContext) => {
  const [model, setModel] = useState<Model | null>(null);

  useAsyncInit(fetchSharesInformation);
  async function fetchSharesInformation() {
    console.time("BondingShareExplorerContainer contract loading");
    const currentBlock = await provider.getBlockNumber();
    const blockCountInAWeek = +(await contracts.bonding.blockCountInAWeek()).toString();
    const totalShares = await contracts.masterChef.totalShares();
    const bondingShareIds = await contracts.bondingToken.holderTokens(account.address);
    const walletLpBalance = await contracts.metaPool.balanceOf(account.address);

    const shares: ShareData[] = [];
    await Promise.all(
      bondingShareIds.map(async (id) => {
        const [ugov, bond, bondingShareInfo, tokenBalance] = await Promise.all([
          contracts.masterChef.pendingUGOV(id),
          contracts.bondingToken.getBond(id),
          contracts.masterChef.getBondingShareInfo(id),
          contracts.bondingToken.balanceOf(account.address, id),
        ]);

        const endBlock = +bond.endBlock.toString();
        const blocksLeft = endBlock - currentBlock;
        const weeksLeft = Math.round((blocksLeft / blockCountInAWeek) * 100) / 100;

        // If this is 0 it means the share ERC1155 token was transferred to another account
        if (+tokenBalance.toString() > 0) {
          shares.push({ id: +id.toString(), ugov, bond, sharesBalance: bondingShareInfo[0], weeksLeft });
        }
      })
    );

    const sortedShares = shares.sort((a, b) => a.id - b.id);

    console.timeEnd("BondingShareExplorerContainer contract loading");
    setModel({ processing: false, shares: sortedShares, totalShares, walletLpBalance });
  }

  function allLpAmount(id: number): BigNumber {
    if (!model) throw new Error("No model");
    const lpAmount = model.shares.find((s) => s.id === id)?.bond?.lpAmount;
    if (!lpAmount) throw new Error("Could not find share in model");
    return lpAmount;
  }

  const actions: Actions = {
    onWithdrawLp: useCallback(
      async ({ id, amount }) => {
        if (!model || model.processing) return;
        console.log(`Withdrawing ${amount ? amount : "ALL"} LP from ${id}`);
        setModel({ ...model, processing: true });

        const isAllowed = await contracts.bondingToken.isApprovedForAll(account.address, contracts.bonding.address);
        if (!isAllowed) {
          // Allow bonding contract to control account share
          if (!(await performTransaction(contracts.bondingToken.connect(signer).setApprovalForAll(contracts.bonding.address, true)))) {
            return; // TODO: Show transaction errors to user
          }
        }

        const bigNumberAmount = amount ? ethers.utils.parseEther(amount.toString()) : allLpAmount(id);
        await performTransaction(contracts.bonding.connect(signer).removeLiquidity(bigNumberAmount, BigNumber.from(id)));

        fetchSharesInformation();
      },
      [model, contracts, signer]
    ),

    onClaimUbq: useCallback(
      async (id) => {
        if (!model || model.processing) return;
        console.log(`Claiming UBQ rewards from ${id}`);
        setModel({ ...model, processing: true });

        await performTransaction(contracts.masterChef.connect(signer).getRewards(BigNumber.from(id)));

        fetchSharesInformation();
      },
      [model, contracts, signer]
    ),

    onStake: useCallback(
      async ({ amount, weeks }) => {
        if (!model || model.processing) return;
        console.log(`Staking ${amount} for ${weeks} weeks`);
        setModel({ ...model, processing: true });
        const bigWeeks = BigNumber.from(weeks.toString());
        const bigAmount = ethers.utils.parseEther(amount.toString());
        const allowance = await contracts.metaPool.allowance(account.address, contracts.bonding.address);
        console.log("allowance", ethers.utils.formatEther(allowance));
        console.log("lpsAmount", ethers.utils.formatEther(bigAmount));
        if (allowance.lt(bigAmount)) {
          await performTransaction(contracts.metaPool.connect(signer).approve(contracts.bonding.address, bigAmount));
          const allowance2 = await contracts.metaPool.allowance(account.address, contracts.bonding.address);
          console.log("allowance2", ethers.utils.formatEther(allowance2));
        }
        await performTransaction(contracts.bonding.connect(signer).deposit(bigAmount, bigWeeks));

        fetchSharesInformation();
      },
      [model, contracts, signer]
    ),
  };

  return <BondingSharesExplorer model={model} actions={actions} />;
};

const LP_TO_USD = 1 / 0.75;

export const BondingSharesExplorer = memo(({ model, actions }: { model: Model | null; actions: Actions }) => {
  return (
    <widget.Container className="max-w-screen-md !mx-auto relative" transacting={model?.processing}>
      <widget.Title text="Liquidity Tokens Staking" />
      {model ? <BondingSharesInformation {...model} {...actions} /> : <widget.Loading text="Loading existing shares information" />}
    </widget.Container>
  );
});

export const BondingSharesInformation = ({ shares, totalShares, onWithdrawLp, onClaimUbq, onStake, processing, walletLpBalance }: Model & Actions) => {
  const totalUserShares = shares.reduce((sum, val) => {
    return sum.add(val.sharesBalance);
  }, BigNumber.from(0));

  const totalLpBalance = shares.reduce((sum, val) => {
    return sum.add(val.bond.lpAmount);
  }, BigNumber.from(0));

  const totalPendingUgov = shares.reduce((sum, val) => {
    return sum.add(val.ugov);
  }, BigNumber.from(0));

  const poolPercentage = formatEther(totalUserShares.mul(ethers.utils.parseEther("100")).div(totalShares));

  return (
    <div className="flex flex-col relative">
      <ConnectedDepositShare onStake={onStake} disabled={processing} maxLp={+ethers.utils.formatEther(walletLpBalance)} />
      <table className="border border-solid border-white border-opacity-10 border-collapse mb-4">
        <thead>
          <tr className="border-0 border-b border-solid border-white border-opacity-10 h-12">
            <th>ID</th>
            <th>Pending Reward</th>
            <th>Deposit</th>
            <th>Unlock time</th>
            <th></th>
          </tr>
        </thead>
        {shares.length > 0 ? (
          <tbody>
            {shares.map((share) => (
              <BondingShareRow key={share.id} {...share} onWithdrawLp={onWithdrawLp} onClaimUbq={onClaimUbq} />
            ))}
          </tbody>
        ) : (
          <tbody>
            <tr>
              <td className="py-4" colSpan={5}>
                Nothing staked yet
              </td>
            </tr>
          </tbody>
        )}
      </table>
      <div className="text-white">
        <div className="mb-2 ">
          {UBQIcon}
          <span className="text-accent">{formatEther(totalPendingUgov)} </span>
          pending UBQ rewards
        </div>
        <div className="mb-2">
          {LiquidIcon}
          {formatEther(totalLpBalance)} LP locked in Bonding Shares
        </div>
        <div className="mb-2">{poolPercentage}% pool ownership.</div>
      </div>
    </div>
  );
};

type BondingShareRowProps = ShareData & { onWithdrawLp: Actions["onWithdrawLp"]; onClaimUbq: Actions["onClaimUbq"] };
const BondingShareRow = ({ id, ugov, sharesBalance, bond, weeksLeft, onWithdrawLp, onClaimUbq }: BondingShareRowProps) => {
  const [withdrawAmount, setWithdrawAmount] = useState("");

  const numLpAmount = +formatEther(bond.lpAmount);
  const usdAmount = numLpAmount * LP_TO_USD;

  return (
    <tr key={id} className="h-12">
      <td className="pl-2">{id.toString()}</td>
      <td>
        <div className="text-accent whitespace-nowrap">
          {UBQIcon} <span>{formatEther(ugov)}</span>
        </div>
      </td>
      <td className="text-white" title={`LP = ${numLpAmount} | Shares = ${formatEther(sharesBalance)}`}>
        ${Math.round(usdAmount * 100) / 100}
      </td>
      <td>
        {weeksLeft <= 0 ? (
          bond.lpAmount.gt(0) ? (
            <>
              <input type="text" placeholder="All" className="!min-w-0 !w-10" value={withdrawAmount} onChange={(ev) => setWithdrawAmount(ev.target.value)} />
              <button onClick={() => onWithdrawLp({ id, amount: parseFloat(withdrawAmount) || null })}>Withdraw</button>
            </>
          ) : null
        ) : (
          <span>{weeksLeft}w</span>
        )}
      </td>
      <td>{ugov.gt(0) ? <button onClick={() => onClaimUbq(+id.toString())}>Claim</button> : null}</td>
    </tr>
  );
};

const constrainNumber = (num: number, min: number, max: number): number => {
  if (num < min) return min;
  else if (num > max) return max;
  else return num;
};

const toEtherNum = (n: BigNumber) => +n.toString() / 1e18;
const toNum = (n: BigNumber) => +n.toString();

const MIN_WEEKS = 1;
const MAX_WEEKS = 208;

type PrefetchedConstants = { totalShares: number; usdPerWeek: number; bondingDiscountMultiplier: BigNumber };
async function prefetchConstants(contracts: Contracts): Promise<PrefetchedConstants> {
  const reserves = await contracts.ugovUadPair.getReserves();
  const ubqPrice = +reserves.reserve0.toString() / +reserves.reserve1.toString();
  const ubqPerBlock = await contracts.masterChef.uGOVPerBlock();
  const ubqMultiplier = await contracts.masterChef.uGOVmultiplier();
  const actualUbqPerBlock = toEtherNum(ubqPerBlock.mul(ubqMultiplier).div(`${1e18}`));
  const blockCountInAWeek = toNum(await contracts.bonding.blockCountInAWeek());
  const ubqPerWeek = actualUbqPerBlock * blockCountInAWeek;
  const totalShares = toEtherNum(await contracts.masterChef.totalShares());
  const usdPerWeek = ubqPerWeek * ubqPrice;
  const bondingDiscountMultiplier = await contracts.bonding.bondingDiscountMultiplier();
  return { totalShares, usdPerWeek, bondingDiscountMultiplier };
}

async function calculateApyForWeeks(contracts: Contracts, prefetch: PrefetchedConstants, weeksNum: number): Promise<number> {
  const { totalShares, usdPerWeek, bondingDiscountMultiplier } = prefetch;
  const DAYS_IN_A_YEAR = 365.2422;
  const usdAsLp = 0.75; // TODO: Get this number from the Curve contract
  const bigNumberOneUsdAsLp = ethers.utils.parseEther(usdAsLp.toString());
  const weeks = BigNumber.from(weeksNum.toString());
  const shares = toEtherNum(await contracts.ubiquityFormulas.durationMultiply(bigNumberOneUsdAsLp, weeks, bondingDiscountMultiplier));
  const rewardsPerWeek = (shares / totalShares) * usdPerWeek;
  const yearlyYield = (rewardsPerWeek / 7) * DAYS_IN_A_YEAR * 100;
  return Math.round(yearlyYield * 100) / 100;
}

async function calculateExpectedShares(contracts: Contracts, prefetch: PrefetchedConstants, amount: string, weeks: string): Promise<number> {
  const { bondingDiscountMultiplier } = prefetch;
  const weeksBig = BigNumber.from(weeks);
  const amountBig = ethers.utils.parseEther(amount);
  const expectedShares = await contracts.ubiquityFormulas.durationMultiply(amountBig, weeksBig, bondingDiscountMultiplier);
  const expectedSharesNum = +ethers.utils.formatEther(expectedShares);
  return Math.round(expectedSharesNum * 10000) / 10000;
}

const DepositShare2 = ({ onStake, disabled, maxLp, contracts }: { onStake: Actions["onStake"]; disabled: boolean; maxLp: number } & UserContext) => {
  const [amount, setAmount] = useState("");
  const [weeks, setWeeks] = useState("");
  const [expectedShares, setExpectedShares] = useState<null | number>(null);
  const [currentApy, setCurrentApy] = useState<number | null>(null);
  const [prefetched, setPrefetched] = useState<PrefetchedConstants | null>(null);
  const [apyBounds, setApyBounds] = useState<[number, number] | null>(null);

  function validateAmount() {
    const amountNum = parseFloat(amount);
    if (amountNum > maxLp) return `You don't have enough ${maxLp} uAD-3CRV tokens`;
  }

  const error = validateAmount();
  const hasErrors = !!error;

  const onWeeksChange = (ev: ChangeEvent<HTMLInputElement>) => {
    setWeeks(ev.target.value && constrainNumber(parseInt(ev.target.value), MIN_WEEKS, MAX_WEEKS).toString());
  };

  const onAmountChange = (ev: ChangeEvent<HTMLInputElement>) => {
    setAmount(ev.target.value && constrainNumber(parseFloat(ev.target.value), 1, Infinity).toString());
  };

  const onClickStake = () => {
    onStake({ amount: parseFloat(amount), weeks: parseInt(weeks) });
  };

  const onClickMax = () => {
    setAmount(maxLp.toString());
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
      if (prefetched && amount && weeks) {
        setExpectedShares(await calculateExpectedShares(contracts, prefetched, amount, weeks));
        setCurrentApy(await calculateApyForWeeks(contracts, prefetched, parseInt(weeks)));
      } else {
        setExpectedShares(null);
        setCurrentApy(null);
      }
    })();
  }, [prefetched, amount, weeks]);

  const noInputYet = !amount || !weeks;

  return (
    <div>
      <div className="text-3xl text-accent mb-4 opacity-75">
        APY {currentApy ? `${currentApy}%` : apyBounds ? `${apyBounds[0]}% - ${apyBounds[1]}%` : "..."}
      </div>
      <div className="mb-4 flex justify-center">
        <input type="number" value={amount} onChange={onAmountChange} disabled={disabled} placeholder="uAD-3CRV LP Tokens" />

        <input
          type="number"
          value={weeks}
          onChange={onWeeksChange}
          disabled={disabled}
          placeholder={`Weeks (${MIN_WEEKS}-${MAX_WEEKS})`}
          min={MIN_WEEKS}
          max={MAX_WEEKS}
        />
        <button className="min-w-0" disabled={disabled} onClick={onClickMax}>
          MAX
        </button>
        <button disabled={disabled || hasErrors || noInputYet} onClick={onClickStake}>
          Stake LP Tokens
        </button>
      </div>
      {expectedShares && <p>Expected bonding shares {expectedShares}</p>}
      {error && <p>{error}</p>}
    </div>
  );
};

const ConnectedDepositShare = connectedWithUserContext(DepositShare2);

export default connectedWithUserContext(BondingSharesExplorerContainer);
