import { Button, PositiveNumberInput, TextInput } from "@/ui";
import { ethers } from "ethers";
import { useState } from "react";
import * as widget from "../ui/widget";
import { poolByAddress } from "./lib/pools";
import { apyFromRatio, multiplierFromRatio, round } from "./lib/utils";

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
      <div>
        <TextInput placeholder="Token address" value={token} onChange={setToken} />
        <PositiveNumberInput placeholder="5 days multiplier" value={multiplier} onChange={setMultiplier} />

        <div>
          <div>APY</div>
          <div>{apy ? `${round(apy)}%` : "..."}</div>
        </div>
      </div>

      <div>
        <Button disabled={!token || isNaN(floatMultiplier) || floatMultiplier < 0} onClick={onClickButton}>
          Apply
        </Button>
      </div>

      {ratiosArr.length ? (
        <table>
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
  const multiplier = multiplierFromRatio(ratio);
  const apy = apyFromRatio(ratio);
  return (
    <tr onClick={onClick}>
      <td>{poolInfo.name}</td>
      <td>
        <div title={token}>{token}</div>
      </td>
      <td>{multiplier}</td>
      <td>{apy !== null ? round(apy) : "..."}</td>
    </tr>
  );
};

export default RewardsManager;
