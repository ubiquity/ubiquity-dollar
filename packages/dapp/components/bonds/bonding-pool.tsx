import { useState } from "react";
import useTransactionLogger from "../lib/hooks/use-transaction-logger";
import Button from "../ui/button";
import PositiveNumberInput from "../ui/positive-number-input";
import Tooltip from "../ui/tooltip";

import { getPoolUrl, PoolData, PoolInfo } from "./lib/pools";
import { format, round } from "./lib/utils";

type BondingPoolParams = PoolInfo & {
  enabled: boolean;
  poolData: PoolData | null;
  onDeposit: ({ amount }: { amount: number }) => unknown;
};

const BondingPool = ({ enabled, poolData, onDeposit, ...info }: BondingPoolParams) => {
  const [, , transacting] = useTransactionLogger();
  const LPTokenName = poolData ? poolData.symbol1 + "-" + poolData.symbol2 : "...";
  const [amount, setAmount] = useState("");

  const onSubmit = () => {
    onDeposit({ amount: parseFloat(amount) });
  };

  const parsedAmount = parseFloat(amount);
  const disableSubmit = transacting || !!(!enabled || !(parsedAmount > 0) || (poolData && parsedAmount > poolData.poolTokenBalance));

  const poolUrl = poolData ? getPoolUrl(info, poolData) : "";

  return (
    <div>
      <div>
        {info.logo ? <img src={info.logo} /> : null}
        <Tooltip content={`Compounding 5-days ${poolData?.multiplier} multiplier for 365 days`}>
          <div>
            <div>
              {poolData?.apr ? format(Math.round(poolData.apr)) : "????"}%{info.logo ? <br /> : " "}
              <span>APR</span>
            </div>
          </div>
        </Tooltip>
      </div>

      <div>
        <Tooltip content="Liquidity">
          <img src="liquidity.png" />
        </Tooltip>
        <div>
          {poolData ? (
            <>
              <div title={poolData.name1}>{poolData.symbol1}</div>
              <div>{poolData.liquidity1 !== null ? format(round(poolData.liquidity1)) : ""}</div>
              <div></div>
              <div>{poolData.liquidity2 !== null ? format(round(poolData.liquidity2)) : ""}</div>
              <div title={poolData.name2}>{poolData.symbol2}</div>
            </>
          ) : (
            <span>· · ·</span>
          )}
        </div>
      </div>

      <div>
        <div>
          <div>
            <PositiveNumberInput value={amount} onChange={setAmount} disabled={!enabled} placeholder={`${LPTokenName} token amount`} />
          </div>
          <div>
            <div>
              Balance: {poolData ? format(round(poolData.poolTokenBalance)) : "????"} {LPTokenName}
            </div>
            <a href={poolUrl} target="_blank" rel="noopener noreferrer">
              Get more
            </a>
          </div>
          <div>
            <Button disabled={disableSubmit} onClick={onSubmit}>
              Deposit &amp; Bond
            </Button>
          </div>
        </div>
        {!enabled ? <div>You need a UbiquiStick to use this pool</div> : null}
      </div>
    </div>
  );
};

export default BondingPool;
