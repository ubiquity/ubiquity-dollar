import cx from "classnames";
import Tippy from "@tippyjs/react";
import { useState } from "react";
import { PoolInfo, PoolData } from "./lib/pools";
import { format, round } from "./lib/utils";
import { Tooltip } from "../ui/widget";

type BondingPoolParams = PoolInfo & {
  enabled: boolean;
  poolData: PoolData | null;
  onDeposit: ({ amount }: { amount: number }) => unknown;
};

const BondingPool = ({ enabled, poolData, onDeposit, ...info }: BondingPoolParams) => {
  const LPTokenName = poolData ? poolData.symbol1 + "-" + poolData.symbol2 : "...";
  const [amount, setAmount] = useState("");

  const onSubmit = () => {
    onDeposit({ amount: parseFloat(amount) });
  };

  const parsedAmount = parseFloat(amount);
  const disableSubmit = !!(!enabled || !(parsedAmount > 0) || (poolData && parsedAmount > poolData.poolTokenBalance));

  const poolUrl = info.tokenAddress === info.poolAddress ? "https://v2.info.uniswap.org/pair/" : "https://www.sorbet.finance/#/pools/";

  return (
    <div className="rounded bg-white bg-opacity-5 p-6">
      <div className="mb-6 flex">
        {info.logo ? <img src={info.logo} className="h-20 rounded-full" /> : null}
        <Tooltip title={`Compounding 5-days ${poolData?.multiplier} multiplier for 365 days`}>
          <div
            className={cx("flex flex-grow items-center justify-center font-light text-accent drop-shadow-light", {
              ["text-3xl"]: info.logo,
              ["text-6xl"]: !info.logo,
            })}
          >
            <div>
              {poolData ? format(Math.round(poolData.apy)) : "????"}%{info.logo ? <br /> : " "}
              <span className="font-normal">APY</span>
            </div>
          </div>
        </Tooltip>
      </div>

      <div className="mb-6 flex items-center">
        <Tooltip title="Liquidity">
          <img src="liquidity.png" className="mr-2 h-4 opacity-50" />
        </Tooltip>
        <div className="flex h-6 flex-grow items-center rounded-full border border-solid border-accent/30 bg-accent/5 px-2 font-mono text-xs">
          {poolData ? (
            <>
              <div className="text-white/50" title={poolData.name1}>
                {poolData.symbol1}
              </div>
              <div className="w-1/2 p-1 text-right text-accent">{poolData.liquidity1 !== null ? format(round(poolData.liquidity1)) : ""}</div>
              <div className="h-full w-[1px] flex-shrink-0 bg-accent/30"></div>
              <div className="w-1/2 p-1 text-left text-accent">{poolData.liquidity2 !== null ? format(round(poolData.liquidity2)) : ""}</div>
              <div className="text-white/50" title={poolData.name2}>
                {poolData.symbol2}
              </div>
            </>
          ) : (
            <span className="flex-grow text-center text-accent">Loading liquidity info...</span>
          )}
        </div>
      </div>

      <div className="relative">
        <div className={cx({ "blur-sm": !enabled })}>
          <div>
            <input
              type="number"
              value={amount}
              onChange={(ev) => setAmount(ev.target.value)}
              className="m-0 mb-2 box-border h-10 w-full px-4 outline outline-accent/0 focus:outline-accent/75"
              disabled={!enabled}
              placeholder={`${LPTokenName} token amount`}
            />
          </div>
          <div className="mb-6 flex text-sm">
            <div className="flex-grow text-left">
              You have {poolData ? format(round(poolData.poolTokenBalance)) : "????"} {LPTokenName}
            </div>
            <a href={`${poolUrl}${info.tokenAddress}`} target="_blank">
              Get more
            </a>
          </div>
          <button className="btn-primary m-0" disabled={disableSubmit} onClick={onSubmit}>
            Deposit &amp; Bond
          </button>
        </div>
        {!enabled ? (
          <div className="absolute top-0 right-0 bottom-0 left-0 flex  items-center justify-center rounded-lg border-4 border-dashed border-white/25 bg-white/10 text-sm uppercase tracking-widest">
            You need a UbiquiStick to use this pool
          </div>
        ) : null}
      </div>
    </div>
  );
};

export default BondingPool;
