import { BigNumber } from "ethers";
import { memo } from "react";

import withLoadedContext from "old-components/lib/withLoadedContext";

// Contracts: bonding, metaPool, bondingToken, masterChef

import Loading from "../ui/Loading";
import { BondingSharesExplorerContainer } from "./BondingSharesExplorerContainer";
import { BondingSharesInformation } from "./BondingSharesInformation";

export type ShareData = {
  id: BigNumber;
  rewards: BigNumber;
  stake: {
    minter: string;
    lpFirstDeposited: BigNumber;
    creationBlock: BigNumber;
    lpRewardDebt: BigNumber;
    endBlock: BigNumber;
    lpAmount: BigNumber;
  };
  stakingTokenBalance: BigNumber;
  weeksLeft: number;
};

export type Model = {
  shares: ShareData[];
  totalShares: BigNumber;
  walletLpBalance: BigNumber;
  processing: ShareData["id"][];
};

export type Actions = {
  onWithdrawLp: (payload: { id: BigNumber; amount: null | number }) => void;
  onClaimUbq: (id: BigNumber) => void;
  onStake: (payload: { amount: BigNumber; weeks: BigNumber }) => void;
};

export const USD_TO_LP = 0.7460387929;
export const LP_TO_USD = 1 / USD_TO_LP;

export const BondingSharesExplorer = memo(({ model, actions }: { model: Model | null; actions: Actions }) => {
  return <>{model ? <BondingSharesInformation {...model} {...actions} /> : <Loading text="Loading existing shares information" />}</>;
});

export type BondingShareRowProps = ShareData & { disabled: boolean; onWithdrawLp: Actions["onWithdrawLp"]; onClaimUbq: Actions["onClaimUbq"] };

export default withLoadedContext(BondingSharesExplorerContainer);
