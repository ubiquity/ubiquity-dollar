import { BigNumber, ethers } from "ethers";
import { useState } from "react";
import { poolByAddress } from "./lib/pools";
import SectionTitle from "./lib/SectionTitle";

type RewardsManagerParams = {
  onSubmit: ({ token, ratio }: { token: string; ratio: ethers.BigNumber }) => any;
  ratios: { [token: string]: ethers.BigNumber };
};

const RewardsManager = ({ onSubmit, ratios }: RewardsManagerParams) => {
  const [token, setToken] = useState<string>("");
  const [ratio, setRatio] = useState<string>("");

  const onClickButton = () => {
    onSubmit({ token, ratio: ethers.utils.parseUnits(ratio, "wei") });
  };

  const ratiosArr = Object.entries(ratios);

  return (
    <div className="party-container">
      <SectionTitle title="Rewards management" subtitle="" />
      <input placeholder="Token address" value={token} onChange={(ev) => setToken(ev.target.value)} />
      <input placeholder="Ratio per billion" type="number" value={ratio} onChange={(ev) => setRatio(ev.target.value)} />
      <button disabled={!token || !ratio} onClick={onClickButton}>
        Apply
      </button>

      {ratiosArr.length ? (
        <div className="mt-4">
          {ratiosArr.map(([tk, rt]) => (
            <TokenInfo key={tk} token={tk} ratio={rt} />
          ))}
        </div>
      ) : null}
    </div>
  );
};

const TokenInfo = ({ token, ratio }: { token: string; ratio: ethers.BigNumber }) => {
  const poolInfo = poolByAddress(token);
  if (!poolInfo) return null;
  return (
    <div>
      {poolInfo.token1}-{poolInfo.token2} | {token} | {parseInt(ratio.toString()) / 1_000_000_000}
    </div>
  );
};

export default RewardsManager;
