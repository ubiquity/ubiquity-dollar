import React, { useEffect, useState } from "react";
import { useRouter } from "next/router";
import Intro from "../pages/intro";
import YieldFarmingPage from "../pages/yield-farming";
import DebtCouponPage from "../pages/debt-coupon";
import LiquidityMining from "../pages/liquidity-mining";
import PriceStabilization from "../pages/price-stabilization";
import TokensSwap from "../pages/tokens-swap";
import LaunchParty from "../pages/launch-party";

export function _renderControls() {
  const router = useRouter();
  const [currentPage, setCurrentPage] = useState("");

  useEffect(() => {
    const page = router.asPath.match(/#([a-z0-9-]+)/gi);
    if (page) {
      setCurrentPage(page[0]);
    }
  }, [router]);

  return (
    <>
      <div id="common">
        {currentPage === "#intro" && <Intro />}
        {currentPage === "#price-stabilization" && <PriceStabilization />}
        {currentPage === "#liquidity-mining" && <LiquidityMining />}
        {currentPage === "#yield-farming" && <YieldFarmingPage />}
        {currentPage === "#debt-coupon" && <DebtCouponPage />}
        {currentPage === "#launch-party" && <LaunchParty />}
        {currentPage === "#markets" && <TokensSwap />}
      </div>
    </>
  );
}
