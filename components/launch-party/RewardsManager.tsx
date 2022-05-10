import { BigNumber, ethers } from "ethers";
import { useState } from "react";
import { poolByAddress } from "./lib/pools";
import { round } from "./lib/utils";
import { Button } from "@/ui";
import * as widget from "../ui/widget";

type RewardsManagerParams = {
  onSubmit: ({ token, ratio }: { token: string; ratio: ethers.BigNumber }) => unknown;
  ratios: { [token: string]: ethers.BigNumber };
};

const RewardsManager = ({ onSubmit, ratios }: RewardsManagerParams) => {
  const [token, setToken] = useState<string>("");
  const [multiplier, setMultiplier] = useState<string>("");

  const onClickButton = () => {
    onSubmit({ token, ratio: ethers.utils.parseUnits((parseFloat(multiplier) * 1_000_000_000).toString(), "wei") });
  };

  const ratiosArr = Object.entries(ratios);

  const floatMultiplier = parseFloat(multiplier);
  const apy = floatMultiplier > 1 ? floatMultiplier ** (365 / 5) : null;

  return (
    <widget.Container>
      <widget.Title text="Rewards management" />
      <div className="flex items-center">
        <input className="flex-grow" placeholder="Token address" value={token} onChange={(ev) => setToken(ev.target.value)} />
        <input placeholder="5 days multiplier" type="number" value={multiplier} onChange={(ev) => setMultiplier(ev.target.value)} />

        <div className="w-36 text-xs leading-none text-accent">
          <div>APY</div>
          <div>{apy ? `${round(apy)}%` : "..."}</div>
        </div>
      </div>

      <div className="text-right">
        <Button disabled={!token || isNaN(floatMultiplier) || floatMultiplier < 0} onClick={onClickButton}>
          Apply
        </Button>
      </div>

      {ratiosArr.length ? (
        <table className="mt-4">
          <thead>
            <tr>
              <th>Token</th>
              <th>Address</th>
              <th>Multiplier</th>
              <th>APY</th>
            </tr>
          </thead>
          <tbody>
            {ratiosArr.map(([tk, rt]) => (
              <TokenInfo key={tk} token={tk} ratio={rt} onClick={() => setToken(tk)} />
            ))}
          </tbody>
        </table>
      ) : null}
    </widget.Container>
  );
};

const TokenInfo = ({ token, ratio, onClick }: { token: string; ratio: ethers.BigNumber; onClick: () => void }) => {
  const poolInfo = poolByAddress(token);
  if (!poolInfo) return null;
  const multiplier = parseInt(ratio.toString()) / 1_000_000_000;
  const apy = multiplier > 1 ? multiplier ** (365 / 5) : null;
  return (
    <tr className="cursor-pointer hover:bg-white/10" onClick={onClick}>
      <td>{poolInfo.name}</td>
      <td>
        <div className="w-60 overflow-hidden text-ellipsis" title={token}>
          {token}
        </div>
      </td>
      <td>{multiplier}</td>
      <td>{apy !== null ? round(apy) : "..."}</td>
    </tr>
  );
};

export default RewardsManager;
