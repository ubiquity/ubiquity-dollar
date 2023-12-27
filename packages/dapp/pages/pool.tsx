import dynamic from "next/dynamic";
import { FC } from "react";

import Button from "@/components/ui/button";
import PositiveNumberInput from "@/components/ui/positive-number-input";

const WalletConnectionWall = dynamic(() => import("@/components/ui/wallet-connection-wall"), { ssr: false }); //@note Fix: (Hydration Error)

/**
 * UbiquityPool page
 *
 * Allows users to:
 * 1. Send collateral tokens to the pool in exchange for Dollar tokens (mint)
 * 2. Send Dollar tokens to the pool in exchange for collateral (redeem)
 */
const Pool: FC = (): JSX.Element => {
  // fetch pool info
  const dollarPrice = "1.00";
  const poolBalance = "2000";
  const poolCeiling = "50000";
  const userBalanceCollateral = "100";
  const userBalanceDollar = "200";
  const mintFee = "100000"; // 10%, 1_000_000 = 100%
  const redemptionFee = "200000"; // 20%, 1_000_000 = 100%
  const receiveAmountDollar = 0;
  const receiveAmountCollateral = 0;

  return (
    <WalletConnectionWall>
      <div id="Pool" className="pool-container">
        {/* pool info block */}
        <div className="panel">
          <h2>Pool info</h2>
          <div className="pool-container__row">
            <span>Dollar price</span>
            <span>${dollarPrice}</span>
          </div>
          <div className="pool-container__row">
            <span>Pool balance (LUSD)</span>
            <span>{poolBalance}</span>
          </div>
          <div className="pool-container__row">
            <span>Pool ceiling (LUSD)</span>
            <span>{poolCeiling}</span>
          </div>
          <div className="pool-container__row">
            <span>User balance (LUSD)</span>
            <span>{userBalanceCollateral}</span>
          </div>
          <div className="pool-container__row">
            <span>User balance (Dollar)</span>
            <span>{userBalanceDollar}</span>
          </div>
          <div className="pool-container__row">
            <span>Mint fee</span>
            <span>{(+mintFee / 1e6) * 100}%</span>
          </div>
          <div className="pool-container__row">
            <span>Redemption fee</span>
            <span>{(+redemptionFee / 1e6) * 100}%</span>
          </div>
        </div>
        {/* mint block */}
        <div className="panel">
          <h2>Mint</h2>
          <div>
            <PositiveNumberInput placeholder={`LUSD amount`} value="" onChange={() => {}} />
          </div>
          <div className="pool-container__row">
            <span>You receive</span>
            <span>{receiveAmountDollar} Dollars</span>
          </div>
          <div>
            <Button disabled={true}>Mint</Button>
          </div>
        </div>
        {/* redeem block */}
        <div className="panel">
          <h2>Redeem</h2>
          <div>
            <PositiveNumberInput placeholder={`Dollar amount`} value="" onChange={() => {}} />
          </div>
          <div className="pool-container__row">
            <span>You receive</span>
            <span>{receiveAmountCollateral} LUSD</span>
          </div>
          <div>
            <Button>Redeem</Button>
          </div>
        </div>
      </div>
    </WalletConnectionWall>
  );
};

export default Pool;
