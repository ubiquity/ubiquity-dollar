/* eslint-disable @typescript-eslint/explicit-module-boundary-types */
import { BigNumber, ethers } from "ethers";
import React from "react";

import Account from "./account";
import BondingMigrate from "./bonding.migrate";
import { useConnectedContext } from "./context/connected";
import CurveBalance from "./curve.balance";
import CurveLPBalance from "./curveLP.balance";
import DebtCouponBalance from "./debtCoupon.balance";
import DebtCouponDeposit from "./debtCoupon.deposit";
import DebtCouponRedeem from "./debtCoupon.redeem";
import TwapPrice from "./twap.price";
import UadBalance from "./uad.balance";
import UarBalance from "./uar.balance";
import UarRedeem from "./uar.redeem";
import UbqBalance from "./ubq.balance";
import BondingSharesExplorer from "./BondingSharesExplorer";
import YieldFarming from "./YieldFarming";
import icons from "./ui/icons";

const PROD = process.env.NODE_ENV == "production";

export function _renderControls() {
  const context = useConnectedContext();
  const { account, balances, twapPrice } = context;

  const poster =
    "https://ssfy.io/https%3A%2F%2Fwww.notion.so%2Fimage%2Fhttps%253A%252F%252Fs3-us-west-2.amazonaws.com%252Fsecure.notion-static.com%252Fbb144e8e-3a57-4e68-b2b9-6a80dbff07d0%252FGroup_3.png%3Ftable%3Dblock%26id%3Dff1a3cae-9009-41e4-9cc4-d4458cc2867d%26cache%3Dv2";

  const video = (
    <video autoPlay muted loop playsInline poster={poster}>
      {PROD && <source src="ubiquity-one-fifth-speed-trimmed-compressed.mp4" type="video/mp4" />}
    </video>
  );

  return (
    <>
      <div id="background">
        {video}
        <div id="grid"></div>
      </div>
      <div id="common">
        <header>
          <Account />
        </header>

        {balances && (
          <>
            <div id="inventory-top">
              <div>
                <div>
                  <aside>My Ubiquity Inventory</aside>
                  <figure></figure>
                </div>
                <UbqBalance />
                <UadBalance />
                <UarBalance />
                <DebtCouponBalance />
                <CurveBalance />
                <CurveLPBalance />
              </div>
            </div>
          </>
        )}
      </div>
    </>
  );
}
