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
import { useConnectedContext } from "./context/connected";
import { Dispatch, SetStateAction, useState } from "react";
import { EthAccount } from "../utils/types";
import Account from "./account";
import CurveBalance from "./curve.balance";
import CurveLPBalance from "./curveLP.balance";
import DepositShare from "./deposit.share";
import ChefUgov from "./chefugov";
import {
  Bonding,
  BondingShare,
  IMetaPool,
  MasterChef,
  MasterChef__factory,
  UbiquityAlgorithmicDollar,
  UbiquityAutoRedeem,
  UbiquityGovernance,
} from "../src/types";
import { UbiquityAutoRedeem__factory } from "../src/types/factories/UbiquityAutoRedeem__factory";
import { UbiquityGovernance__factory } from "../src/types/factories/UbiquityGovernance__factory";

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
  setUAD: Dispatch<SetStateAction<UbiquityAlgorithmicDollar | undefined>>
): Promise<void> {
  if (!window.ethereum?.request) {
    alert("MetaMask is not installed!");
    return;
  }

  const provider = new ethers.providers.Web3Provider(window.ethereum);
  const accounts = await window.ethereum.request({
    method: "eth_requestAccounts",
  });
  console.log("accounts", JSON.stringify(accounts));
  setProvider(provider);
  setAccount({ address: accounts[0], balance: 0 });
  const manager = UbiquityAlgorithmicDollarManager__factory.connect(
    ADDRESS.MANAGER,
    provider
  );
  setManager(manager);
  const SIGNER = provider?.getSigner();

  const TOKEN_ADDR = await manager.stableSwapMetaPoolAddress();
  const metapool = IMetaPool__factory.connect(TOKEN_ADDR, SIGNER);
  const bonding = Bonding__factory.connect(ADDRESS.BONDING, SIGNER);
  const bondingShare = BondingShare__factory.connect(
    ADDRESS.BONDING_SHARE,
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
}

export async function _getTokenBalance(
  provider: ethers.providers.Web3Provider | undefined,
  account: string,
  setTokenBalance: Dispatch<SetStateAction<string | undefined>>
): Promise<void> {
  console.log("_getTokenBalance");
  // console.log("provider", provider);
  console.log("account", account);
  if (provider && account) {
    const uAD = UbiquityAlgorithmicDollar__factory.connect(
      ADDRESS.UAD,
      provider.getSigner()
    );
    console.log("ADDRESS.UAD", ADDRESS.UAD);
    //console.log("uAD", uAD);
    const rawBalance = await uAD.balanceOf(account);
    console.log("rawBalance", rawBalance);

    const decimals = await uAD.decimals();
    console.log("decimals", decimals);
    const balance = ethers.utils.formatUnits(rawBalance, decimals);
    console.log("balance", balance);
    setTokenBalance(balance);
  }
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
  } = useConnectedContext();
  const [tokenBalance, setTokenBalance] = useState<string>();
  const [tokenLPBalance, setLPTokenBalance] = useState<string>();
  const [curveTokenBalance, setCurveTokenBalance] = useState<string>();
  const [
    tokenBondingSharesBalance,
    setBondingSharesBalance,
  ] = useState<string>();
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
      setUAD
    );

  const getTokenBalance = async () =>
    _getTokenBalance(provider, account ? account.address : "", setTokenBalance);
  /*   const depositBondingTokens = () =>
    _depositBondingTokens(provider, account, setBondingSharesBalance); */

  /*   const getCurveTokenBalance = async () =>
    _getCurveTokenBalance(
      provider,
      account ? account.address : "",
      setCurveTokenBalance
    ); */
  return (
    <>
      <button onClick={connect}>Connect Wallet</button>
      <Account />
      <UadBalance />
      <CurveBalance />
      <CurveLPBalance />
      <DepositShare />
      <ChefUgov />
    </>
  );
}
/* <button onClick={getTokenBalance}>Get uAD Token Balance</button>
      <p>uAD Balance: {tokenBalance}</p> */
