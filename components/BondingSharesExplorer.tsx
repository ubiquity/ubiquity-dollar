import { BigNumber, ethers } from "ethers";
import { ChangeEvent, memo, useState, useCallback, useEffect } from "react";
import { connectedWithUserContext, UserContext } from "./context/connected";
import { formatEther } from "./common/format";
import { useAsyncInit, performTransaction } from "./common/utils";
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

  // const ethers.utils.formatEther(bond.lpAmount)
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

const MIN_WEEKS = 1;
const MAX_WEEKS = 208;

const DepositShare2 = ({ onStake, disabled, maxLp, contracts }: { onStake: Actions["onStake"]; disabled: boolean; maxLp: number } & UserContext) => {
  const [amount, setAmount] = useState("");
  const [weeks, setWeeks] = useState("");
  const [expectedShares, setExpectedShares] = useState<null | number>(null);

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
      if (amount && weeks) {
        const weeksBig = BigNumber.from(weeks);
        const amountBig = ethers.utils.parseEther(amount);
        const bondingDiscountMultiplier = await contracts.bonding.bondingDiscountMultiplier();
        const expectedShares = await contracts.ubiquityFormulas.durationMultiply(amountBig, weeksBig, bondingDiscountMultiplier);
        const expectedSharesNum = +ethers.utils.formatEther(expectedShares);
        setExpectedShares(Math.round(expectedSharesNum * 10000) / 10000);
      } else {
        setExpectedShares(null);
      }
    })();
  }, [amount, weeks]);

  const noInputYet = !amount || !weeks;

  return (
    <div>
      <div className="mb-4 flex justify-center">
        <div className="flex flex-col">
          <input type="number" value={amount} onChange={onAmountChange} disabled={disabled} placeholder="uAD-3CRV LP Tokens" />
          <div
            className={`text-right text-xs text-gray-100 mr-2 -mt-1 ${disabled ? "opacity-25" : "cursor-pointer"}`}
            onClick={disabled ? undefined : onClickMax}
          >
            MAX
          </div>
        </div>

        <input
          type="number"
          value={weeks}
          onChange={onWeeksChange}
          disabled={disabled}
          placeholder={`Weeks (${MIN_WEEKS}-${MAX_WEEKS})`}
          min={MIN_WEEKS}
          max={MAX_WEEKS}
        />
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
