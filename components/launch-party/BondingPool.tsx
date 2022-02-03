import cx from "classnames";
import { useState } from "react";
import { PoolInfo, PoolData } from "./lib/pools";
import { format, round } from "./lib/utils";

type BondingPoolParams = PoolInfo & {
  enabled: boolean;
  poolData: PoolData | null;
  onDeposit: ({ amount }: { amount: number }) => any;
};

const BondingPool = ({ enabled, poolData, onDeposit, ...info }: BondingPoolParams) => {
  const LPTokenName = poolData ? poolData.symbol1 + "-" + poolData.symbol2 : "...";
  const [amount, setAmount] = useState("");

  const onSubmit = () => {
    onDeposit({ amount: parseFloat(amount) });
  };

  const parsedAmount = parseFloat(amount);
  const disableSubmit = !!(!enabled || !(parsedAmount > 0) || (poolData && parsedAmount > poolData.poolTokenBalance));

  return (
    <div className="p-6 bg-white bg-opacity-5 rounded">
      <div className="flex mb-6">
        {info.logo ? <img src={info.logo} className="h-20 rounded-full" /> : null}
        <div
          className={cx("flex-grow flex font-light items-center justify-center text-accent drop-shadow-light", {
            ["text-3xl"]: info.logo,
            ["text-6xl"]: !info.logo,
          })}
        >
          <div>
            {poolData ? format(Math.round(poolData.apy)) : "????"}%{info.logo ? <br /> : " "}
            <span className="font-normal">APY</span>
          </div>
        </div>
      </div>
      <div className="grid grid-cols-2 gap-6 text-left mb-6">
        <TokenInfo name={poolData?.name1 || ""} symbol={poolData?.symbol1 || ""} liquidity={poolData?.liquidity1} />
        <TokenInfo name={poolData?.name2 || ""} symbol={poolData?.symbol2 || ""} liquidity={poolData?.liquidity2} />
      </div>
      <div>
        <input
          type="number"
          value={amount}
          onChange={(ev) => setAmount(ev.target.value)}
          className="w-full box-border m-0 h-12 px-4 py-4 mb-2"
          placeholder={`${LPTokenName} token amount`}
        />
      </div>
      <div className="text-sm flex mb-6">
        <div className="flex-grow text-left">
          You have {poolData ? format(round(poolData.poolTokenBalance)) : "????"} {LPTokenName}
        </div>
        <a href={`https://www.sorbet.finance/#/pools/${info.tokenAddress}`} target="_blank">
          Get more
        </a>
      </div>
      <button className="btn-primary m-0" disabled={disableSubmit} onClick={onSubmit}>
        Deposit &amp; Bond
      </button>
    </div>
  );
};

const TokenInfo = ({ name, symbol, liquidity }: { name: string; symbol: string; liquidity: number | null | undefined }) => (
  <div className="flex items-center">
    <div className="flex-grow" title={name}>
      {symbol}
    </div>
    <div className="px-2 py-0 flex items-center border border-solid border-white bg-opacity-50 rounded-full">
      <img src="liquidity.png" className="h-4 mr-2" />
      <span className="leading-6 text-sm">{liquidity != null ? format(round(liquidity)) : "???"}</span>
    </div>
  </div>
);

export default BondingPool;
