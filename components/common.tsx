import React, { useEffect, useState } from "react";
import { useRouter } from "next/router";
import Intro from "../pages/intro";
import YieldFarmingPage from "../pages/yield-farming";
import LiquidityMining from "../pages/liquidity-mining";
import PriceStabilization from "../pages/price-stabilization";
import Markets from "../pages/markets";
import LaunchParty from "../pages/launch-party";

const PROD = process.env.NODE_ENV == "production";

export function _renderControls() {
  const router = useRouter();
  const [currentPage, setCurrentPage] = useState("");

  const poster =
    "https://ssfy.io/https%3A%2F%2Fwww.notion.so%2Fimage%2Fhttps%253A%252F%252Fs3-us-west-2.amazonaws.com%252Fsecure.notion-static.com%252Fbb144e8e-3a57-4e68-b2b9-6a80dbff07d0%252FGroup_3.png%3Ftable%3Dblock%26id%3Dff1a3cae-9009-41e4-9cc4-d4458cc2867d%26cache%3Dv2";

  const video = (
    <video autoPlay muted loop playsInline poster={poster} className="bg-video">
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
      </div>
    </>
  );
}
