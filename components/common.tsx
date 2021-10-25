/* eslint-disable @typescript-eslint/explicit-module-boundary-types */
import { BigNumber, ethers } from "ethers";
import React, { useState, useEffect } from "react";

import { EthAccount } from "./common/types";
import Account from "./account";
import Network from "./network";
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
import { UADIcon } from "./ui/icons";

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
  const { setAccount, account, balances, twapPrice } = useConnectedContext();
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

  return (
    <>
      <div id="background">
        {PROD && <video src="ubiquity-one-fifth-speed-trimmed-compressed.mp4" autoPlay muted loop playsInline></video>}
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
                {UADIcon}
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
                <span>
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 132 151">
                    <path d="M132 41.1c0-2.3-1.3-4.5-3.3-5.7L69.4 1.2c-1-.6-2.1-.9-3.3-.9-1.1 0-2.3.3-3.3.9L3.6 35.4c-2 1.2-3.3 3.3-3.3 5.7v68.5c0 2.3 1.3 4.5 3.3 5.7l59.3 34.2c2 1.2 4.5 1.2 6.5 0l59.3-34.2c2-1.2 3.3-3.3 3.3-5.7V41.1zm-11.9 62.5c0 2.7-1.4 5.2-3.7 6.5l-46.6 27.5c-1.1.7-2.4 1-3.7 1s-2.5-.3-3.7-1l-46.6-27.5c-2.3-1.3-3.7-3.8-3.7-6.5V54.1c0-1.2.6-2.4 1.7-3 1.1-.6 2.3-.6 3.4 0l8 4.7c1.9 1.1 3 3.3 4.4 5.8.3.5.5 1 .8 1.4 3.5 6.3 5.2 13 6.8 19.5 3 11.9 6 24.2 21.3 28.2 5 1.3 10.4 1.3 15.4 0 15.2-4 18.3-16.3 21.3-28.2C96.8 76 98.5 69.3 102 63c.3-.5.5-1 .8-1.4 1.3-2.5 2.5-4.6 4.4-5.8l8-4.7c1-.6 2.3-.6 3.4 0s1.7 1.7 1.7 3v49.5zM62.6 13.7c2.2-1.3 4.9-1.3 7.1 0L110 37.6c1 .6 1.6 1 1.6 2.2 0 1.2-.6 1.9-1.6 2.5l-7.7 4.6c-3.4 2-5.1 5.2-6.6 8.1l-.1.2c-.2.4-.4.7-.6 1.1-3.8 6.8-6.6 14-8.2 20.4C83.6 89.1 82.4 97.3 72 100c-1.9.5-3.9.7-5.8.7-2 0-3.9-.3-5.8-.7C50 97.3 48.7 89.1 45.6 76.6 44 70.2 41.2 63 37.4 56.2c-.2-.3-.4-.7-.6-1l-.1-.3c-1.5-2.8-3.3-6.1-6.6-8.1l-7.7-4.6c-1-.6-1.6-1.3-1.6-2.5s.6-1.6 1.6-2.2l40.2-23.8z" />
                  </svg>
                </span>
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
