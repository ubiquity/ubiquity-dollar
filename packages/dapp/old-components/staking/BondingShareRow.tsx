import { useState } from "react";
import { formatEther } from "old-components/lib/format";
import Button from "../ui/Button";
import Icon from "../ui/Icon";
import { BondingShareRowProps, LP_TO_USD, USD_TO_LP } from "./BondingSharesExplorer";

export function BondingShareRow({ id, rewards: ugov, stake: bond, weeksLeft, disabled, onWithdrawLp, onClaimUbq }: BondingShareRowProps) {
  const [withdrawAmount] = useState("");

  const numLpAmount = +formatEther(bond.lpAmount);
  const usdAmount = numLpAmount * LP_TO_USD;

  function onClickWithdraw() {
    const parsedUsdAmount = parseFloat(withdrawAmount);
    if (parsedUsdAmount) {
      onWithdrawLp({ id, amount: parsedUsdAmount * USD_TO_LP });
    } else {
      onWithdrawLp({ id, amount: null });
    }
  }

  return (
    <tr key={id.toString()} title={`Bonding Share ID: ${id.toString()}`}>
      <td>
        {weeksLeft <= 0 && bond.lpAmount.gt(0) ? (
          <button disabled={disabled} onClick={onClickWithdraw}>
            Claim &amp; Withdraw
          </button>
        ) : ugov.gt(0) ? (
          <Button
            disabled={disabled}
            onClick={() => {
              // const _id = Number(id);
              return onClaimUbq(id);
            }}
          >
            Claim reward
          </Button>
        ) : null}
      </td>
      <td>
        <div>
          <Icon icon="ubq" /> <span>{formatEther(ugov)}</span>
        </div>
      </td>
      <td>{weeksLeft <= 0 ? "Ready" : <span>{weeksLeft}w</span>}</td>

      <td>${Math.round(usdAmount * 100) / 100}</td>
    </tr>
  );
}
