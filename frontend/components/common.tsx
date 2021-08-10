/* eslint-disable @typescript-eslint/explicit-module-boundary-types */
import { BigNumber, ethers } from "ethers";
import React, { useState, useEffect } from "react";
import { ERC1155Ubiquity } from "../src/types";

import { EthAccount } from "../utils/types";
import Account from "./account";
import BondingMigrate from "./bonding.migrate";
import ChefUgov from "./chefugov";
import {
  Balances,
  useConnectedContext,
  useConnectedContracts,
} from "./context/connected";
import CurveBalance from "./curve.balance";
import CurveLPBalance from "./curveLP.balance";
import DebtCouponBalance from "./debtCoupon.balance";
import DebtCouponDeposit from "./debtCoupon.deposit";
import DebtCouponRedeem from "./debtCoupon.redeem";
import DepositShare from "./deposit.share";
import DepositShareRedeem from "./deposit.share.redeem";
import TwapPrice from "./twap.price";
import UadBalance from "./uad.balance";
import UarBalance from "./uar.balance";
import UarRedeem from "./uar.redeem";
import UbqBalance from "./ubq.balance";
import { Contracts } from "../src/contracts";

const PROD = process.env.NODE_ENV == "production";

async function erc1155BalanceOf(
  addr: string,
  erc1155UbiquityCtr: ERC1155Ubiquity
): Promise<BigNumber> {
  const treasuryIds = await erc1155UbiquityCtr.holderTokens(addr);

  const balanceOfs = treasuryIds.map((id) => {
    return erc1155UbiquityCtr.balanceOf(addr, id);
  });
  const balances = await Promise.all(balanceOfs);
  let fullBalance = BigNumber.from(0);
  if (balances.length > 0) {
    fullBalance = balances.reduce((prev, cur) => {
      return prev.add(cur);
    });
  }
  return fullBalance;
}

// Load the account balances in a single parallel operation
async function accountBalances(
  account: EthAccount,
  contracts: Contracts
): Promise<Balances> {
  const [
    uad,
    crv,
    uad3crv,
    uar,
    ubq,
    debtCoupon,
    bondingShares,
  ] = await Promise.all([
    contracts.uad.balanceOf(account.address),
    contracts.crvToken.balanceOf(account.address),
    contracts.metaPool.balanceOf(account.address),
    contracts.uar.balanceOf(account.address),
    contracts.ugov.balanceOf(account.address),
    erc1155BalanceOf(account.address, contracts.debtCouponToken),
    erc1155BalanceOf(account.address, contracts.bondingToken),
  ]);
  return {
    uad,
    crv,
    uad3crv,
    uar,
    ubq,
    debtCoupon,
    bondingShares,
    bondingSharesLP: BigNumber.from(0),
  };
}

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
  const {
    setAccount,
    setBalances,
    setTwapPrice,
    account,
    contracts,
    balances,
    twapPrice,
  } = useConnectedContext();
  const [connecting, setConnecting] = useState(false);
  useConnectedContracts();

  useEffect(() => {
    (async function () {
      if (contracts) {
        setTwapPrice(await contracts.twapOracle.consult(contracts.uad.address));
      }
    })();
  }, [contracts]);

  useEffect(() => {
    (async function () {
      if (contracts && account) {
        setBalances(await accountBalances(account, contracts));
      }
    })();
  }, [account, contracts]);

  const connect = async (): Promise<void> => {
    setConnecting(true);
    setAccount(await fetchAccount());
  };

  return (
    <>
      <div id="background">
        {PROD && (
          <video
            src="ubiquity-one-fifth-speed-trimmed-compressed.mp4"
            autoPlay
            muted
            loop
            playsInline
          ></video>
        )}
        <div id="grid"></div>
      </div>
      <div id="common">
        <header>
          <div id="logo">
            <span>Ubiquity Dollar</span>
            <span>|</span>
            <span>Staking Dashboard</span>
            <span></span>
          </div>
          <div>
            <span>
              <input
                type="button"
                value="Connect Wallet"
                disabled={connecting}
                onClick={() => connect()}
              />
            </span>
          </div>

          <Account />
        </header>

        {account && <TwapPrice />}
        <ChefUgov />
        <BondingMigrate />
        <DepositShare />
        {balances?.uar.gt(BigNumber.from(0)) &&
        twapPrice?.gte(ethers.utils.parseEther("1")) ? (
          <UarRedeem />
        ) : (
          ""
        )}
        {twapPrice?.lte(ethers.utils.parseEther("1")) ? (
          <DebtCouponDeposit />
        ) : (
          ""
        )}
        {balances?.debtCoupon.gt(BigNumber.from(0)) ? <DebtCouponRedeem /> : ""}
        {balances?.bondingShares.gt(BigNumber.from(0)) ? (
          <DepositShareRedeem />
        ) : (
          ""
        )}

        <div id="markets">
          <div>
            <aside> Primary Markets</aside>
          </div>
          <div>
            <div id="uad-market">
              <div>
                <span>
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 75 85.45"
                  >
                    <path d="m30.13 57.62.35.2L58.31 74 39.36 85a3.75 3.75 0 0 1-3.52.11l-.2-.11L1.86 65.45a3.73 3.73 0 0 1-1.85-3v-6a33 33 0 0 1 30.12 1.17zM9.18 15.77l29.4 17.1.38.22A40.49 40.49 0 0 0 75 35v27.22a3.72 3.72 0 0 1-1.68 3.11l-.18.12-7.34 4.24-31.55-18.35A40.47 40.47 0 0 0 0 48.32v-25.1a3.75 3.75 0 0 1 1.68-3.11l.18-.11zM37.5 0a3.75 3.75 0 0 1 1.64.38l.22.12L73.14 20A3.72 3.72 0 0 1 75 23v3.68a33 33 0 0 1-32.2 0l-.45-.26-25.69-14.97L35.64.5a3.64 3.64 0 0 1 1.62-.5z" />
                  </svg>
                </span>
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
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 91.57 104.19"
                  >
                    <path d="M43.28.67 2.5 24.22A5 5 0 0 0 0 28.55v47.09A5 5 0 0 0 2.5 80l40.78 23.55a5 5 0 0 0 5 0L89.07 80a5 5 0 0 0 2.5-4.33V28.55a5 5 0 0 0-2.5-4.33L48.28.67a5 5 0 0 0-5 0zm36.31 25a2 2 0 0 1 0 3.46l-6 3.48c-2.72 1.57-4.11 4.09-5.34 6.3-.18.33-.36.66-.55 1-3 5.24-4.4 10.74-5.64 15.6C59.71 64.76 58 70.1 50.19 72.09a17.76 17.76 0 0 1-8.81 0c-7.81-2-9.53-7.33-11.89-16.59-1.24-4.86-2.64-10.36-5.65-15.6l-.54-1c-1.23-2.21-2.62-4.73-5.34-6.3l-6-3.47a2 2 0 0 1 0-3.47L43.28 7.6a5 5 0 0 1 5 0zM43.28 96.59 8.5 76.51A5 5 0 0 1 6 72.18v-36.1a2 2 0 0 1 3-1.73l6 3.46c1.29.74 2.13 2.25 3.09 4l.6 1c2.59 4.54 3.84 9.41 5 14.11 2.25 8.84 4.58 18 16.25 20.93a23.85 23.85 0 0 0 11.71 0C63.3 75 65.63 65.82 67.89 57c1.2-4.7 2.44-9.57 5-14.1l.59-1.06c1-1.76 1.81-3.27 3.1-4l5.94-3.45a2 2 0 0 1 3 1.73v36.1a5 5 0 0 1-2.5 4.33L48.28 96.59a5 5 0 0 1-5 0z" />
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
                <a
                  target="_blank"
                  href="https://app.sushi.com/add/0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0/0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6"
                >
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
                <UadBalance />
                <UarBalance />
                <DebtCouponBalance />
                <UbqBalance />
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
