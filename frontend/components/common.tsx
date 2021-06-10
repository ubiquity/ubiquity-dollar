/* eslint-disable @typescript-eslint/explicit-module-boundary-types */
import { ethers, BigNumber } from "ethers";

import { UbiquityAlgorithmicDollar__factory } from "../src/types/factories/UbiquityAlgorithmicDollar__factory";
import { IMetaPool__factory } from "../src/types/factories/IMetaPool__factory";
import { Bonding__factory } from "../src/types/factories/Bonding__factory";
import { BondingShare__factory } from "../src/types/factories/BondingShare__factory";
import { UbiquityAlgorithmicDollarManager__factory } from "../src/types/factories/UbiquityAlgorithmicDollarManager__factory";
import { UbiquityAlgorithmicDollarManager } from "../src/types/UbiquityAlgorithmicDollarManager";
import { ERC20__factory } from "../src/types/factories/ERC20__factory";
import UadBalance from "./uad.balance";
import { ADDRESS } from "../pages/index";
import { Balances, useConnectedContext } from "./context/connected";
import { Dispatch, SetStateAction, useState } from "react";
import { EthAccount } from "../utils/types";
import Account from "./account";
import CurveBalance from "./curve.balance";
import CurveLPBalance from "./curveLP.balance";
import DepositShare from "./deposit.share";
import UarBalance from "./uar.balance";
import ChefUgov from "./chefugov";
import {
  Bonding,
  BondingShare,
  DebtCouponManager,
  DebtCouponManager__factory,
  IMetaPool,
  MasterChef,
  MasterChef__factory,
  UbiquityAlgorithmicDollar,
  UbiquityAutoRedeem,
  UbiquityGovernance,
} from "../src/types";
import { UbiquityAutoRedeem__factory } from "../src/types/factories/UbiquityAutoRedeem__factory";
import { UbiquityGovernance__factory } from "../src/types/factories/UbiquityGovernance__factory";
import TwapPrice from "./twap.price";
import UarRedeem from "./uar.redeem";

export function _renderTasklist() {
  return (
    <>
      <h1>tasklist</h1>
      <ol>
        <li>pending ugov reward</li>
        <li>bonding shares inputs for weeks and LP token amount</li>
        <li>link to crv.finance</li>
        <li>convert all wei into ether values</li>
      </ol>
    </>
  );
}

export async function _connect(
  setProvider: Dispatch<
    SetStateAction<ethers.providers.Web3Provider | undefined>
  >,
  setAccount: Dispatch<SetStateAction<EthAccount | undefined>>,
  setManager: Dispatch<
    SetStateAction<UbiquityAlgorithmicDollarManager | undefined>
  >,
  setMetapool: Dispatch<SetStateAction<IMetaPool | undefined>>,
  setBonding: Dispatch<SetStateAction<Bonding | undefined>>,
  setBondingShare: Dispatch<SetStateAction<BondingShare | undefined>>,
  setMasterChef: Dispatch<SetStateAction<MasterChef | undefined>>,
  setUAR: Dispatch<SetStateAction<UbiquityAutoRedeem | undefined>>,
  setUGOV: Dispatch<SetStateAction<UbiquityGovernance | undefined>>,
  setUAD: Dispatch<SetStateAction<UbiquityAlgorithmicDollar | undefined>>,
  setBalances: Dispatch<SetStateAction<Balances | undefined>>,
  setDebtCouponMgr: Dispatch<SetStateAction<DebtCouponManager | undefined>>
): Promise<void> {
  if (!window.ethereum?.request) {
    alert("MetaMask is not installed!");
    return;
  }

  const provider = new ethers.providers.Web3Provider(window.ethereum);
  const accounts = await window.ethereum.request({
    method: "eth_requestAccounts",
  });
  setProvider(provider);
  setAccount({ address: accounts[0], balance: 0 });
  const manager = UbiquityAlgorithmicDollarManager__factory.connect(
    ADDRESS.MANAGER,
    provider
  );
  setManager(manager);
  const SIGNER = provider.getSigner();
  const TOKEN_ADDR = await manager.stableSwapMetaPoolAddress();
  const metapool = IMetaPool__factory.connect(TOKEN_ADDR, SIGNER);
  const BONDING_ADDR = await manager.bondingContractAddress();
  const bonding = Bonding__factory.connect(BONDING_ADDR, SIGNER);
  const BONDING_SHARE_ADDR = await manager.bondingShareAddress();
  const bondingShare = BondingShare__factory.connect(
    BONDING_SHARE_ADDR,
    SIGNER
  );
  setMetapool(metapool);
  setBonding(bonding);
  setBondingShare(bondingShare);
  const masterchefAdr = await manager.masterChefAddress();
  const masterchef = MasterChef__factory.connect(masterchefAdr, SIGNER);
  setMasterChef(masterchef);
  const uarAdr = await manager.autoRedeemTokenAddress();
  const uar = UbiquityAutoRedeem__factory.connect(uarAdr, SIGNER);
  setUAR(uar);
  const uGovAdr = await manager.governanceTokenAddress();
  const ugov = UbiquityGovernance__factory.connect(uGovAdr, SIGNER);
  setUGOV(ugov);
  const uadAdr = await manager.dollarTokenAddress();
  const uad = UbiquityAlgorithmicDollar__factory.connect(uadAdr, SIGNER);
  setUAD(uad);
  setBalances({
    uad: BigNumber.from(0),
    crv: BigNumber.from(0),
    uad3crv: BigNumber.from(0),
    uar: BigNumber.from(0),
    ubq: BigNumber.from(0),
    bondingShares: BigNumber.from(0),
  });
  const debtCouponMgr = DebtCouponManager__factory.connect(
    ADDRESS.DEBT_COUPON_MANAGER,
    SIGNER
  );
  setDebtCouponMgr(debtCouponMgr);
}

export function _renderControls() {
  const {
    account,
    provider,
    manager,
    setProvider,
    setAccount,
    setManager,
    setMetapool,
    setBonding,
    setBondingShare,
    setMasterChef,
    setUAR,
    setUGOV,
    setUAD,
    setBalances,
    balances,
    setDebtCouponMgr,
  } = useConnectedContext();

  const connect = async (): Promise<void> =>
    _connect(
      setProvider,
      setAccount,
      setManager,
      setMetapool,
      setBonding,
      setBondingShare,
      setMasterChef,
      setUAR,
      setUGOV,
      setUAD,
      setBalances,
      setDebtCouponMgr
    );

  return (
    <>
      <div className="column-wrap">
        <button onClick={connect}>Connect Wallet</button>
        <Account />
      </div>
      <div className="balance">
        <UadBalance />
        <CurveBalance />
        <CurveLPBalance />
        <UarBalance />
      </div>
      <br />
      <div className="column-wrap">
        <DepositShare />
        <ChefUgov />
        <TwapPrice />
        {balances?.uar.gt(BigNumber.from(0)) ? <UarRedeem /> : ""}
      </div>
    </>
  );
}
