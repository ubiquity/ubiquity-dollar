import React, { useEffect, useState } from "react";
import { useRouter } from "next/router";
import { useConnectedContext } from "./context/connected";
import CurveBalance from "./curve.balance";
import CurveLPBalance from "./curveLP.balance";
import DebtCouponBalance from "./debtCoupon.balance";
import UadBalance from "./uad.balance";
import UarBalance from "./uar.balance";
import UbqBalance from "./ubq.balance";
import Intro from "../pages/intro";
import YieldFarmingPage from "../pages/yield-farming";
import LiquidityMining from "../pages/liquidity-mining";
import PriceStabilization from "../pages/price-stabilization";
import Markets from "../pages/markets";
import LaunchParty from "../pages/launch-party";

const PROD = process.env.NODE_ENV == "production";

export function _renderControls() {
  const router = useRouter();
  const context = useConnectedContext();
  const { balances } = context;
  const [currentPage, setCurrentPage] = useState("");

  const poster =
    "https://ssfy.io/https%3A%2F%2Fwww.notion.so%2Fimage%2Fhttps%253A%252F%252Fs3-us-west-2.amazonaws.com%252Fsecure.notion-static.com%252Fbb144e8e-3a57-4e68-b2b9-6a80dbff07d0%252FGroup_3.png%3Ftable%3Dblock%26id%3Dff1a3cae-9009-41e4-9cc4-d4458cc2867d%26cache%3Dv2";

  const video = (
    <video autoPlay muted loop playsInline poster={poster}>
      {PROD && <source src="ubiquity-one-fifth-speed-trimmed-compressed.mp4" type="video/mp4" />}
    </video>
  );

  useEffect(() => {
    const page = router.asPath.match(/#([a-z0-9-]+)/gi);
    if (page) {
      setCurrentPage(page[0]);
    }
  }, [router]);

  return (
    <>
      <div id="background">
        {video}
        <div id="grid"></div>
      </div>
      <div id="common">
        {currentPage === "#intro" && <Intro />}
        {currentPage === "#price-stabilization" && <PriceStabilization />}
        {currentPage === "#liquidity-mining" && <LiquidityMining />}
        {currentPage === "#yield-farming" && <YieldFarmingPage />}
        {currentPage === "#launch-party" && <LaunchParty />}
        {currentPage === "#markets" && <Markets />}
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
