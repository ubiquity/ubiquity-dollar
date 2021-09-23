import { BigNumber, ethers } from "ethers";
import { memo, useState } from "react";
import { useConnectedContractsWithAccount, useContractsCallback } from "./context/connected";
import { formatEther, formatMwei } from "./common/format";
import * as widget from "./ui/widget";

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
};

type Actions = { onWithdrawLp: (payload: { id: number; amount: null | number }) => void; onClaimUbq: (id: number) => void };

export const BondingSharesExplorerContainer = () => {
  const [model, setModel] = useState<Model | null>(null);

  useConnectedContractsWithAccount(async ({ contracts, provider, account }) => {
    console.time("BondingShareExplorerContainer contract loading");
    const currentBlock = await provider.getBlockNumber();
    const blockCountInAWeek = +(await contracts.bonding.blockCountInAWeek()).toString();
    const totalSharesSupply = await contracts.masterChef.totalShares();
    const bondingShareIds = await contracts.bondingToken.holderTokens(account.address);

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

    console.timeEnd("BondingShareExplorerContainer contract loading");

    setModel({
      shares,
      totalShares: totalSharesSupply,
    });
  });

  const actions: Actions = {
    onWithdrawLp: useContractsCallback(({ contracts }, { id, amount }) => {
      console.log(`Withdrawing ${amount ? amount : "ALL"} LP from ${id}`);
    }),

    onClaimUbq: useContractsCallback(({ contracts }, id) => {
      console.log(`Claiming rewards from ${id}`);
    }),
  };

  return <BondingSharesExplorer model={model} actions={actions} />;
};

export const BondingSharesExplorer = memo(({ model, actions }: { model: Model | null; actions: Actions }) => {
  console.log("Rendering BondingSharesExplorer", model);
  return (
    <widget.Container className="max-w-screen-md !mx-auto">
      <widget.Title text="Liquidity Tokens Staking" />
      {model ? <BondingSharesExplorerListing {...model} {...actions} /> : <div>Loading existing shares information...</div>}
    </widget.Container>
  );
});

export const BondingSharesExplorerListing = ({ shares, totalShares, onWithdrawLp, onClaimUbq }: Model & Actions) => {
  const [withdrawAmounts, setWithdrawAmounts] = useState<{ [key: number]: string }>({});

  const onWithdrawAmountChange = (id: number, amount: string) => {
    console.log("Changing withdraw amount");
    setWithdrawAmounts({ ...withdrawAmounts, [id]: amount.replaceAll(/[^0-9.]/g, "") });
  };

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
    <div className="flex flex-col">
      <table className="border border-solid border-white border-opacity-10 border-collapse mb-4">
        <thead>
          <tr className="border-0 border-b border-solid border-white border-opacity-10 h-12">
            <th>ID</th>
            <th>Pending Reward</th>
            <th>LP</th>
            <th>Shares</th>
            <th>Time left</th>
            <th></th>
          </tr>
        </thead>
        {shares.length > 0 ? (
          <tbody>
            {shares.map(({ id, ugov, sharesBalance: lpBalance, bond, weeksLeft }) => (
              <tr key={id} className="h-12">
                <td className="pl-2">{id.toString()}</td>
                <td>
                  <div className="text-accent whitespace-nowrap">
                    {UBQIcon} <span>{formatEther(ugov)}</span>
                  </div>
                </td>
                <td className="text-white">{formatEther(bond.lpAmount)}</td>
                <td className="text-white">{formatEther(lpBalance)}</td>
                <td>
                  {weeksLeft <= 0 ? (
                    <>
                      <input
                        type="text"
                        placeholder="All"
                        className="!min-w-0 !w-10"
                        value={withdrawAmounts[id] || ""}
                        onChange={(ev) => onWithdrawAmountChange(id, ev.target.value)}
                      />
                      <button onClick={() => onWithdrawLp({ id, amount: parseFloat(withdrawAmounts[id]) || null })}>Withdraw</button>
                    </>
                  ) : (
                    <span>{weeksLeft}w</span>
                  )}
                </td>
                <td>{ugov.gt(0) ? <button onClick={() => onClaimUbq(+id.toString())}>Claim</button> : null}</td>
              </tr>
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

const UBQIcon = (
  <span className="align-middle">
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 91.57 104.19" className="h-4 mr-2">
      <path d="M43.28.67 2.5 24.22A5 5 0 0 0 0 28.55v47.09A5 5 0 0 0 2.5 80l40.78 23.55a5 5 0 0 0 5 0L89.07 80a5 5 0 0 0 2.5-4.33V28.55a5 5 0 0 0-2.5-4.33L48.28.67a5 5 0 0 0-5 0zm36.31 25a2 2 0 0 1 0 3.46l-6 3.48c-2.72 1.57-4.11 4.09-5.34 6.3-.18.33-.36.66-.55 1-3 5.24-4.4 10.74-5.64 15.6C59.71 64.76 58 70.1 50.19 72.09a17.76 17.76 0 0 1-8.81 0c-7.81-2-9.53-7.33-11.89-16.59-1.24-4.86-2.64-10.36-5.65-15.6l-.54-1c-1.23-2.21-2.62-4.73-5.34-6.3l-6-3.47a2 2 0 0 1 0-3.47L43.28 7.6a5 5 0 0 1 5 0zM43.28 96.59 8.5 76.51A5 5 0 0 1 6 72.18v-36.1a2 2 0 0 1 3-1.73l6 3.46c1.29.74 2.13 2.25 3.09 4l.6 1c2.59 4.54 3.84 9.41 5 14.11 2.25 8.84 4.58 18 16.25 20.93a23.85 23.85 0 0 0 11.71 0C63.3 75 65.63 65.82 67.89 57c1.2-4.7 2.44-9.57 5-14.1l.59-1.06c1-1.76 1.81-3.27 3.1-4l5.94-3.45a2 2 0 0 1 3 1.73v36.1a5 5 0 0 1-2.5 4.33L48.28 96.59a5 5 0 0 1-5 0z" />
    </svg>
  </span>
);

const LiquidIcon = (
  <span className="align-middle">
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" className="h-6 mr-2">
      <path fill="none" d="M0 0h20v20H0z" />
      <path d="M10 2s-6.5 5.16-6.5 9.5a6.5 6.5 0 1 0 13 0C16.5 7.16 10 2 10 2zm0 14.5c-2.76 0-5-2.24-5-5 0-2.47 3.1-5.8 5-7.53 1.9 1.73 5 5.05 5 7.53 0 2.76-2.24 5-5 5zm-2.97-4.57c.24 1.66 1.79 2.77 3.4 2.54a.5.5 0 0 1 .57.49c0 .28-.2.47-.42.5a4.013 4.013 0 0 1-4.54-3.39c-.04-.3.19-.57.5-.57.25 0 .46.18.49.43z" />
    </svg>
  </span>
);

export default BondingSharesExplorerContainer;
