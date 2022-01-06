import { useEffect, useState } from "react";
import cx from "classnames";
import { useRecoilValue } from "recoil";
import { PoolInfo, PoolData, fetchPoolData } from "./lib/pools";
import { format, round } from "./lib/utils";
import { isWhitelistedState } from "./lib/states";

const BondingPool = (info: PoolInfo) => {
  const isWhitelisted = useRecoilValue(isWhitelistedState);
  const [poolData, setPoolData] = useState<PoolData | null>(null);
  useEffect(() => {
    (async () => {
      setTimeout(async () => {
        setPoolData(await fetchPoolData(info));
      }, 2000);
    })();
  }, []);

  const LPTokenName = info.token1 + "-" + info.token2;

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
            {poolData ? format(poolData.apy) : "????"}%{info.logo ? <br /> : " "}
            <span className="font-normal">APY</span>
          </div>
        </div>
      </div>
      <div className="grid grid-cols-2 gap-6 text-left mb-6">
        <TokenInfo name={info.token1} liquidity={poolData?.liquidity1} />
        <TokenInfo name={info.token2} liquidity={poolData?.liquidity2} />
      </div>
      <div>
        <input type="number" className="w-full box-border m-0 h-12 px-4 py-4 mb-2" placeholder={`${LPTokenName} token amount`} />
      </div>
      <div className="text-sm flex mb-6">
        <div className="flex-grow text-left">
          You have {poolData ? format(round(poolData.poolTokenBalance)) : "????"} {LPTokenName}
        </div>
        <a href={info.poolMarketLink} target="_blank">
          Get more
        </a>
      </div>
      <button className="btn-primary m-0" disabled={!isWhitelisted}>
        Deposit &amp; Bond
      </button>
    </div>
  );
};

const TokenInfo = ({ name, liquidity }: { name: string; liquidity: number | undefined }) => (
  <div className="flex items-center">
    <div className="flex-grow">{name}</div>
    <div className="px-2 py-0 flex items-center border border-solid border-white bg-opacity-50 rounded-full">
      <img src="liquidity.png" className="h-4 mr-2" />
      <span className="leading-6 text-sm">{liquidity != null ? format(round(liquidity)) : "???"}</span>
    </div>
  </div>
);

export default BondingPool;
