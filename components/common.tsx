/* eslint-disable @typescript-eslint/explicit-module-boundary-types */
import { BigNumber, ethers } from "ethers";
import React, { useState, useEffect } from "react";

import { EthAccount } from "./common/types";
import Account from "./account";
import Network from "./network";
import BondingMigrate from "./bonding.migrate";
import { useConnectedContext } from "./context/connected";
import DebtCouponDeposit from "./debtCoupon.deposit";
import DebtCouponRedeem from "./debtCoupon.redeem";
import TwapPrice from "./twap.price";
import UarRedeem from "./uar.redeem";
import Inventory from "./inventory";
import BondingSharesExplorer from "./BondingSharesExplorer";
import YieldFarming from "./YieldFarming";
import icons from "./ui/icons";

const PROD = process.env.NODE_ENV == "production";

async function fetchAccount(): Promise<EthAccount | null> {
  if (window.ethereum?.request) {
    return {
      address: ((await window.ethereum.request({
        method: "eth_requestAccounts",
      })) as string[])[0],
      balance: 0,
    };
  } else {
    alert("MetaMask is not installed!");
    console.error("MetaMask is not installed, cannot connect wallet");
    return null;
  }
}

export function _renderControls() {
  const context = useConnectedContext();
  const { setAccount, account, balances, twapPrice } = context;

  const [connecting, setConnecting] = useState(false);

  const connect = async (): Promise<void> => {
    setConnecting(true);
    setAccount(await fetchAccount());
  };

  if (!PROD) {
    useEffect(() => {
      connect();
    }, []);
  }
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
          <div id="logo">
            <span>Ubiquity Dollar</span>
            <span>|</span>
            <span>Dashboard</span>
            <span></span>
          </div>
          <div>
            <span>
              <input type="button" value="Connect Wallet" disabled={connecting} onClick={() => connect()} />
            </span>
          </div>
          <Network />
          <Account />
        </header>

        {account && <TwapPrice />}
        <BondingMigrate />
        {account && <YieldFarming />}
        {account && <BondingSharesExplorer />}
        {balances?.uar.gt(BigNumber.from(0)) && twapPrice?.gte(ethers.utils.parseEther("1")) ? <UarRedeem /> : ""}
        {twapPrice?.lte(ethers.utils.parseEther("1")) ? <DebtCouponDeposit /> : ""}
        {balances?.debtCoupon.gt(BigNumber.from(0)) ? <DebtCouponRedeem /> : ""}

        <div id="markets">
          <div>
            <aside> Primary Markets</aside>
          </div>
          <div>
            <div id="uad-market">
              <div>
                {icons.svgs.uad}
                <span>uAD</span>
              </div>
              <div>
                <a target="_blank" href="https://crv.to">
                  <input type="button" value="Swap" />
                </a>
              </div>
              <div>
                <a target="_blank" href="https://crv.to/pool">
                  <input type="button" value="Deposit" />
                </a>
              </div>
            </div>
            <div id="ubq-market">
              <div>
                <span>{icons.svgs.ubq}</span>
                <span>UBQ</span>
              </div>
              <div>
                <a
                  target="_blank"
                  href="https://app.sushi.com/swap?inputCurrency=0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0&outputCurrency=0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6"
                >
                  <input type="button" value="Swap" />
                </a>
              </div>
              <div>
                <a target="_blank" href="https://app.sushi.com/add/0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0/0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6">
                  <input type="button" value="Deposit" />
                </a>
              </div>
            </div>
          </div>
        </div>

        {balances && <Inventory />}
      </div>
    </>
  );
}
